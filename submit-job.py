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


def _parse_env(env: list):
    environment = []
    for env_var in env:
        if "=" not in env_var:
            raise ValueError(
                "Environment variable is not properly formed. Use --env 'KEY=value'"
            )

        key, value = env_var.split("=", maxsplit=1)
        environment.append({"name": key, "value": value})

    return environment


def _submit_job(job_queue: str, job_definition: str, job_details: dict, environ: list):
    experiment_conf = job_details["path"]
    cur_time = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    experiment_last_path = experiment_conf.split("/")[-2]
    name = f"{cur_time}-{experiment_last_path}"

    environment = [
        {
            "name": "CHAOS_CONFIG_FILE",
            "value": experiment_conf,
        },
    ]
    environment.extend(environ)

    client.submit_job(
        jobName=name,
        jobQueue=job_queue,
        jobDefinition=job_definition,
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
@click.option(
    "--env",
    "-e",
    multiple=True,
    help="Override environment variable for job execution. Format: --env 'KEY=value'",
)
@click.option(
    "--queue",
    required=True,
    help="The name of the AWS batch job queue",
)
@click.option(
    "--job-definition",
    required=True,
    help="The name of the AWS batch job definition",
)
@click.argument("experiment-configurations", nargs=-1)
def cli(vcpu, memory, env, queue, job_definition, experiment_configurations):
    # pylint: disable=too-many-arguments

    for experiment_config_file in list(experiment_configurations):
        print(f"Submitting experiment with config file: {experiment_config_file}")
        job_details = {
            "path": experiment_config_file,
            "vcpu": vcpu,
            "memory": memory,
        }
        _submit_job(
            job_queue=queue,
            job_definition=job_definition,
            job_details=job_details,
            environ=_parse_env(env),
        )


if __name__ == "__main__":
    cli()  # pylint: disable=no-value-for-parameter
