import json
import os
from datetime import datetime
from pathlib import Path
from string import Template

import boto3
import click
from devlearnops import sanitize_name_for_path
from devlearnops.reporting import journal

boto_session = boto3.session.Session()
account_id = boto_session.client("sts").get_caller_identity().get("Account")
region = boto_session.client("s3").meta.region_name


def send_notification(template_path, subject, **props):
    topic_arn = os.getenv("FAILED_EXPERIMENT_TOPIC_ARN")
    if not topic_arn:
        print("SNS notification topic not configured. Unable to send notification")
        return

    with open(template_path, mode="r", encoding="utf-8") as file:
        notification_template = Template(file.read())

    print(f"Sending notification to [{topic_arn}] SNS topic.")
    report = notification_template.substitute(**props)
    sns_client = boto_session.client("sns")
    sns_client.publish(
        TopicArn=topic_arn,
        Subject=subject,
        Message=report,
    )


def upload_journal_and_logs(journals_bucket, journal_path, ctk_logs_path) -> str:
    with open(journal_path, mode="r", encoding="utf-8") as file:
        journal_data = json.load(file)

    start_time = datetime.strptime(journal_data.get("start"), "%Y-%m-%dT%H:%M:%S.%f")
    sanitized_name = sanitize_name_for_path(
        journal_data.get("experiment", {}).get("title", "undefined"),
        max_len=50,
    )
    upload_path = start_time.strftime("%Y%m%d_%H%M%S") + f"_{sanitized_name}"
    print(
        f"Uploading experiment journal and logs to [s3://{journals_bucket}/{upload_path}/]"
    )

    s3_client = boto_session.client("s3")
    with open(journal_path, mode="rb") as binary_file:
        s3_client.upload_fileobj(
            binary_file,
            Bucket=journals_bucket,
            Key=f"{upload_path}/journal.json",
        )
    with open(ctk_logs_path, mode="rb") as binary_file:
        s3_client.upload_fileobj(
            binary_file,
            Bucket=journals_bucket,
            Key=f"{upload_path}/chaostoolkit.log",
        )

    return upload_path


@click.command()
@click.option(
    "--journal-file",
    required=False,
    default="journal.json",
    type=click.Path(exists=True),
    help="The path of the chaostoolkit journal file",
)
@click.option(
    "--logs-file",
    required=False,
    default="chaostoolkit.log",
    type=click.Path(exists=True),
    help="The path of the chaostoolkit log file",
)
@click.option(
    "--journals-bucket",
    required=False,
    default=lambda: os.getenv("JOURNALS_BUCKET"),
    help="The name of the S3 bucket destination for journals",
)
def cli(journal_file, logs_file, journals_bucket):
    upload_path = upload_journal_and_logs(
        journals_bucket=journals_bucket,
        journal_path=journal_file,
        ctk_logs_path=logs_file,
    )

    _, experiment_report = journal.execution_report(journal_path=journal_file)

    experiment_report["aws_account_id"] = account_id
    experiment_report["aws_region"] = region
    experiment_report["journals_bucket"] = journals_bucket
    experiment_report["experiment_files_location"] = upload_path

    if experiment_report.get("has_failures"):
        base_path = Path(__file__).parent
        send_notification(
            template_path=f"{base_path}/experiment-failed.template",
            subject=f"Chaos: Failed experiment '{experiment_report.get('experiment_title')}'",
            **experiment_report,
        )

    print(experiment_report["execution_summary"])


if __name__ == "__main__":
    cli()
