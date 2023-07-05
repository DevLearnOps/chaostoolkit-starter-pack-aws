import json
import os
from datetime import datetime
from pathlib import Path
from string import Template

import boto3


def _failed_activity(activity):
    if activity.get("activity").get("type") == "probe":
        return (
            activity.get("status") != "succeeded"
            or activity.get("tolerance_met") is not True
        )

    return activity.get("status") != "succeeded"


def _gen_fail_summary(activity):
    activity_type = activity.get("activity", {}).get("type", "action")
    name = activity.get("activity", {}).get("name", "undefined")
    if activity_type == "probe":
        summary = f"Probe [{name}] failed verification:"
        summary += f"\n  tolerance verification met: {activity.get('tolerance_met')}"
    else:
        summary = f"Activity [{name}] failed to complete"

    exception = activity.get("exception", [])
    if exception:
        exception_text = "    ".join(exception)
        summary += f"\n  exception: {exception_text}"

    output = activity.get("output")
    if output:
        summary += f"\n  output: {str(output)}"

    return summary


def _gen_steady_state_summary(steady_state):
    if not steady_state:
        return []

    if steady_state.get("steady_state_met") is not True:
        failed_probes = list(filter(_failed_activity, steady_state.get("probes", [])))
        return [_gen_fail_summary(probe) for probe in failed_probes]

    return []


def send_notification(template_path, subject, **props):
    topic_arn = os.getenv("FAILED_EXPERIMENT_TOPIC_ARN")
    if not topic_arn:
        print("SNS notification topic not configured. Unable to send notification")
        return

    with open(template_path, mode="r", encoding="utf-8") as file:
        notification_template = Template(file.read())

    report = notification_template.substitute(**props)
    session = boto3.session.Session()
    sns_client = session.client("sns")
    sns_client.publish(
        TopicArn=topic_arn,
        Subject=subject,
        Message=report,
    )


def report(journal):
    experiment = journal.get("experiment")

    if journal.get("deviated") is True:
        experiment_result = "successful"
    else:
        experiment_result = "deviated"

    summary = ""
    before_summaries = _gen_steady_state_summary(
        journal.get("steady_states", {}).get("before")
    )
    after_summaries = _gen_steady_state_summary(
        journal.get("steady_states", {}).get("after")
    )

    during_steady_state = journal.get("steady_states", {}).get("during", [])
    during_summaries = []
    for steady_state in during_steady_state:
        during_summaries.extend(_gen_steady_state_summary(steady_state))

    if before_summaries:
        summary += "# Failed Steady-State Verifications Before Experiment:\n\n"
        summary += "\n".join(before_summaries)

    if after_summaries:
        summary += "# Failed Steady-State Verifications After Experiment:\n\n"
        summary += "\n".join(after_summaries)

    if during_summaries:
        summary += "# Failed Continuous Steady-State Verifications for Experiment:\n\n"
        summary += "\n".join(during_summaries)

    failed_activities = list(filter(_failed_activity, journal.get("run", [])))
    if failed_activities:
        summary += "# Failed Experiment Activities:\n\n"
        activity_summaries = [
            _gen_fail_summary(activity) for activity in failed_activities
        ]
        summary += "\n".join(activity_summaries)

    report = {
        "experiment_title": experiment.get("title"),
        "experiment_result": experiment_result,
        "experiment_status": journal.get("status"),
        "has_failures": bool(
            before_summaries or after_summaries or during_summaries or failed_activities
        ),
        "execution_summary": summary,
    }
    return report


if __name__ == "__main__":
    with open("journal.json", mode="r", encoding="utf-8") as file:
        journal = json.load(file)

    journals_bucket = os.getenv("JOURNALS_BUCKET")
    start_time = datetime.strptime(journal.get("start"), "%Y-%m-%dT%H:%M:%S.%f")
    sanitized_name = (
        journal.get("experiment", {})
        .get("title", "undefined")
        .strip()
        .replace(" ", "-")
        .replace(".", "")
        .replace("/", "")
        .replace("'", "")
        .replace('"', "")
        .lower()[:50]
    )
    upload_path = start_time.strftime("%Y%m%d_%H%M%S") + f"_{sanitized_name}"

    session = boto3.session.Session()
    s3_client = session.client("s3")
    with open("journal.json", mode="rb") as binary_file:
        s3_client.upload_fileobj(
            binary_file,
            Bucket=journals_bucket,
            Key=f"{upload_path}/journal.json",
        )
    with open("chaostoolkit.log", mode="rb") as binary_file:
        s3_client.upload_fileobj(
            binary_file,
            Bucket=journals_bucket,
            Key=f"{upload_path}/chaostoolkit.log",
        )

    experiment_report = report(journal)
    account_id = session.client("sts").get_caller_identity().get("Account")
    region = session.client("s3").meta.region_name

    experiment_report["aws_account_id"] = account_id
    experiment_report["aws_region"] = region
    experiment_report["journals_bucket"] = journals_bucket
    experiment_report["experiment_files_location"] = upload_path

    if experiment_report.get("has_failures"):
        base_path = Path(__file__).parent
        send_notification(
            template_path=f"{base_path}/experiment-failed.template",
            subject=f"Chaos: Failed experiment '{experiment_report.get('title')}'",
            **experiment_report,
        )
