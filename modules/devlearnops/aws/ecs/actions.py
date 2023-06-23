from typing import List

from chaosaws import aws_client
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger
from .. import get_current_region, get_account_id

__all__ = ["install_container_stressor", "remove_container_stressor"]


def _filter_tasks(tasks, count, percent):
    if len(tasks) <= 1:
        return tasks

    if percent > 0:
        count = max(1, int(len(tasks) * (percent / 100)))

    count = min(count, len(tasks))

    return tasks[: count - 1]


def _get_current_task_definition(ecs_client, cluster: str, service: str):
    results = ecs_client.describe_services(cluster=cluster, services=[service])
    task_definition = results.get("services")[0].get("taskDefinition")

    response = ecs_client.describe_task_definition(taskDefinition=task_definition)
    task_definition = dict(response["taskDefinition"])
    remove_args = [
        "compatibilities",
        "registeredAt",
        "registeredBy",
        "status",
        "revision",
        "taskDefinitionArn",
        "requiresAttributes",
    ]
    for arg in remove_args:
        task_definition.pop(arg)

    return task_definition


def _render_stress_command(stressor, task_total_cpu, task_total_memory):
    stressor_type = stressor["type"]
    cmd = []
    if stressor_type.lower() == "cpu":
        target_cpu_load = int(stressor.get("cpu_load", 100))
        cpu = max(1, int(task_total_cpu / 1024))
        if task_total_cpu < 1024:
            cpu_load = int(cpu * (target_cpu_load * (task_total_cpu / 1024)))
        else:
            cpu_load = target_cpu_load
        cmd.append(f"--cpu {cpu} --cpu-load {cpu_load}")

    if stressor.get("duration"):
        cmd.append(f" --timeout {stressor.get('duration')}")

    return " ".join(cmd)


def install_container_stressor(
    cluster: str,
    service: str,
    stressor: dict,
    stressor_delay_seconds: int = 60,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    client = aws_client("ecs", configuration, secrets)

    task_definition = _get_current_task_definition(client, cluster, service)

    container_definitions = task_definition["containerDefinitions"]
    new_container_definitions = []
    for definition in container_definitions:
        if definition["name"] != "ecs-hog":
            new_container_definitions.append(definition)

    command = _render_stress_command(
        stressor, int(task_definition["cpu"]), int(task_definition["memory"])
    )

    hog_container_definition = {
        "name": "ecs-hog",
        "image": f"{get_account_id()}.dkr.ecr.{get_current_region()}.amazonaws.com/ecs-hog:latest",
        "portMappings": [],
        "essential": False,
        "environment": [
            {"name": "HOG_CONFIG", "value": command},
            {"name": "HOG_DELAY", "value": str(stressor_delay_seconds)},
        ],
    }
    new_container_definitions.append(hog_container_definition)

    task_definition["containerDefinitions"] = new_container_definitions

    response = client.register_task_definition(**task_definition)
    new_task_definition_arn = response["taskDefinition"]["taskDefinitionArn"]

    response = client.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task_definition_arn,
    )

    return response["service"]["serviceArn"]


def remove_container_stressor(
    cluster: str,
    service: str,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    client = aws_client("ecs", configuration, secrets)

    task_definition = _get_current_task_definition(client, cluster, service)

    container_definitions = task_definition["containerDefinitions"]
    new_container_definitions = []
    for definition in container_definitions:
        if definition["name"] != "ecs-hog":
            new_container_definitions.append(definition)

    task_definition["containerDefinitions"] = new_container_definitions

    response = client.register_task_definition(**task_definition)
    new_task_definition_arn = response["taskDefinition"]["taskDefinitionArn"]

    response = client.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task_definition_arn,
    )

    return response["service"]["serviceArn"]
