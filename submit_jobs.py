import boto3
import os
from datetime import datetime


JOBS = [
    {
        "experiment": "reliability/ecs-service-fail-az",
    },
    {
        "experiment": "reliability/ecs-service-slow-datasource",
    },
    {
        "experiment": "reliability/ecs-service-slow-dependency",
    },
]

params = {}
region = os.getenv("AWS_REGION", os.getenv("AWS_DEFAULT_REGION"))
profile = os.getenv("AWS_PROFILE")
if region:
    params["region_name"] = region
if profile:
    boto3.setup_default_session(profile_name=profile, **params)

client = boto3.client("batch", **params)


def submit_job(job_details):
    experiment = job_details["experiment"]
    cur_time = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    experiment_last_path = experiment.split("/")[-1]
    name = f"{cur_time}-{experiment_last_path}"

    client.submit_job(
        jobName=name,
        jobQueue="live-chaos-batch-job-queue",
        jobDefinition="live-chaos-batch-job-definition",
        containerOverrides={
            "environment": [
                {
                    "name": "EXPERIMENT_PATH",
                    "value": experiment,
                }
            ],
            "resourceRequirements": [
                {"value": str(job_details.get("vcpu", 1)), "type": "VCPU"},
                {"value": str(job_details.get("memory", 2048)), "type": "MEMORY"},
            ],
        },
        timeout={"attemptDurationSeconds": 3600},
    )


if __name__ == "__main__":
    for job in JOBS:
        submit_job(job)
