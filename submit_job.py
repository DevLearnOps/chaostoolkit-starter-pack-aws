import os
from datetime import datetime

import boto3
import click

params = {}
region = os.getenv("AWS_REGION", os.getenv("AWS_DEFAULT_REGION"))
profile = os.getenv("AWS_PROFILE")
if region:
    params["region_name"] = region
if profile:
    boto3.setup_default_session(profile_name=profile, **params)

client = boto3.client("batch", **params)


def _submit_job(job_details):
    experiment_path = job_details["path"]
    cur_time = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    experiment_last_path = experiment_path.split("/")[-1]
    name = f"{cur_time}-{experiment_last_path}"

    environment = [
        {
            "name": "EXPERIMENT_PATH",
            "value": experiment_path,
        },
        {
            "name": "EXPERIMENT_FILE",
            "value": job_details["experiment_file"],
        },
    ]
    client.submit_job(
        jobName=name,
        jobQueue="live-chaos-batch-job-queue",
        jobDefinition="live-chaos-batch-job-definition",
        containerOverrides={
            "environment": environment,
            "resourceRequirements": [
                {"value": str(job_details.get("vcpu", 1)), "type": "VCPU"},
                {"value": str(job_details.get("memory", 2048)), "type": "MEMORY"},
            ],
        },
        timeout={"attemptDurationSeconds": 3600},
    )


@click.command()
@click.option(
    "--vcpu",
    type=click.FLOAT,
    default=1.0,
    help="The number of vcpus for the chaos job",
)
@click.option(
    "--memory",
    type=click.INT,
    default=2048,
    help="The memory (in MB) for the chaos job",
)
@click.argument("experiment-path", type=click.Path(exists=True))
def cli(vcpu, memory, experiment_path):
    experiment_file = "experiment.yaml"
    if os.path.isfile(experiment_path):
        experiment_file = os.path.basename(experiment_path)
        experiment_path = os.path.dirname(experiment_path)

    job_details = {
        "path": experiment_path,
        "experiment_file": experiment_file,
        "vcpu": vcpu,
        "memory": memory,
    }
    _submit_job(job_details)


if __name__ == "__main__":
    cli()
