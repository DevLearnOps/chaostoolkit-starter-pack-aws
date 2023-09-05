"""Defines chaos attacks for Amazon ECS services"""

from typing import Dict, List

from chaosaws import aws_client
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

from .. import get_account_id, get_current_region
from .probes import wait_for_service_stable
from .utils import (
    delete_service_state,
    describe_service,
    get_updatable_task_definition,
    read_service_states,
    save_service_state,
)

__all__ = [
    "install_container_hog",
    "update_service_configuration",
    "restore_services",
]

HOG_CONTAINER_NAME = "ecs-hog"


def _render_stress_command(stressor, task_total_cpu: int, task_total_memory: int):
    """Renders the stressor command for the 'hog' container"""
    stressor_type = stressor["type"]
    cmd = []
    if stressor_type.lower() == "cpu":
        target_cpu_load = int(stressor.get("cpu_load", 100))
        cpu = max(1, int(task_total_cpu / 1024))

        cpu_load = min(100, target_cpu_load)
        cmd.append(f"--cpu {cpu} --cpu-load {cpu_load}")

    if stressor.get("duration"):
        cmd.append(f" --timeout {stressor.get('duration')}")

    return " ".join(cmd)


def install_container_hog(
    cluster: str,
    service: str,
    hog_configuration: Dict,
    hog_delay_seconds: int = 60,
    hog_image: str = "public.ecr.aws/devlearnops/ecs-container-hog:latest",
    wait_service_stable: bool = True,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    """
    Installs a CPU or Memory stressor to the service task definition

    Parameters
    ----------
    cluster: str
        The ECS cluster name
    service: str
        The ECS service name
    hog_configuration: Dict
        The configuration for the container hog. Valid parameters are:
        - type: str = cpu|memory
        - cpu_load: int = 0-100 (target cpu-load in %)
        - duration: int = 60 (duration in seconds)
    hog_delay_seconds: int
        The amount of time in seconds the container will wait before starting
        the hog. Useful to allow some time for main services to boot up
    wait_service_stable: bool
        Wait for service deployment to complete before returning

    Returns
    -------
    str:
        The updated service Arn
    """
    ecs_client = aws_client("ecs", configuration, secrets)
    service_descriptor = describe_service(ecs_client, cluster, service)
    if not service_descriptor:
        raise FailedActivity(
            f"Could not describe service for cluster {cluster} and service {service}"
        )

    task_definition_arn = service_descriptor["taskDefinition"]
    logger.info(
        "Current task definition arn for [%s] is [%s]", service, task_definition_arn
    )

    save_service_state(service_descriptor)

    task_definition = get_updatable_task_definition(ecs_client, task_definition_arn)

    container_definitions = task_definition["containerDefinitions"]
    new_container_definitions = []
    for definition in container_definitions:
        if definition["name"] != HOG_CONTAINER_NAME:
            new_container_definitions.append(definition)

    command = _render_stress_command(
        hog_configuration, int(task_definition["cpu"]), int(task_definition["memory"])
    )

    if not hog_image.startswith("public.ecr.aws") or ".dkr.ecr." not in hog_image:
        hog_image = f"{get_account_id()}.dkr.ecr.{get_current_region()}.amazonaws.com/{hog_image}"

    hog_container_definition = {
        "name": HOG_CONTAINER_NAME,
        "image": hog_image,
        "portMappings": [],
        "essential": False,
        "environment": [
            {"name": "HOG_CONFIG", "value": command},
            {"name": "HOG_DELAY", "value": str(hog_delay_seconds)},
        ],
    }
    new_container_definitions.append(hog_container_definition)

    task_definition["containerDefinitions"] = new_container_definitions

    response = ecs_client.register_task_definition(**task_definition)
    new_task_definition_arn = response["taskDefinition"]["taskDefinitionArn"]

    response = ecs_client.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task_definition_arn,
    )

    if wait_service_stable:
        wait_for_service_stable(
            cluster=cluster,
            service=service,
            configuration=configuration,
            secrets=secrets,
        )

    return response["service"]["serviceArn"]


def update_service_configuration(
    cluster: str,
    service: str,
    container_name: str,
    environ: Dict,
    wait_service_stable: bool = True,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    """
    Updates the ECS service configuration

    Parameters
    ----------
    cluster: str
        The ECS cluster name
    service: str
        The ECS service name
    container_name: str
        The name of the container in the ECS task definition to update
    environ: Dict
        A dictionary of keys to update the service configuration to
    wait_service_stable: bool
        Wait for service deployment to complete before returning

    Returns
    -------
    str:
        The updated service Arn
    """
    client = aws_client("ecs", configuration, secrets)

    service_descriptor = describe_service(client, cluster, service)
    if not service_descriptor:
        raise FailedActivity(
            f"Could not describe service for cluster {cluster} and service {service}"
        )

    task_definition_arn = service_descriptor["taskDefinition"]
    logger.info(
        "Current task definition arn for [%s] is [%s]", service, task_definition_arn
    )

    save_service_state(service_descriptor)

    task_definition = get_updatable_task_definition(client, task_definition_arn)

    container_definitions = task_definition["containerDefinitions"]
    for container_def in container_definitions:
        if container_def["name"] == container_name:
            for variable in container_def.get("environment", []):
                for key, value in environ.items():
                    if variable["name"] == key:
                        variable["value"] = value

    response = client.register_task_definition(**task_definition)
    new_task_definition_arn = response["taskDefinition"]["taskDefinitionArn"]

    response = client.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task_definition_arn,
    )

    if wait_service_stable:
        wait_for_service_stable(
            cluster=cluster,
            service=service,
            configuration=configuration,
            secrets=secrets,
        )

    return response["service"]["serviceArn"]


def restore_services(
    wait_service_stable: bool = True,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> List[str]:
    """
    Reverts all ECS services to original state

    Parameters
    ----------
    wait_service_stable: bool
        Wait for service deployment to complete before returning

    Raises
    ------
    FailedActivity:
        If there is no service configuration to revert to

    Returns
    -------
    list:
        a list of all restored services arns
    """
    ecs_client = aws_client("ecs", configuration, secrets)

    states = read_service_states()
    if not states:
        raise FailedActivity("No service configuration found to revert to. Failing.")

    restored_arns = []
    for state in states:
        stored_service_status = state.get("state")
        cluster = stored_service_status.get("cluster_name")
        service = stored_service_status.get("service_name")

        service_descriptor = describe_service(ecs_client, cluster, service)

        original_task_definition_arn = service_descriptor["taskDefinition"]
        if "task_definition_arn" in stored_service_status:
            original_task_definition_arn = stored_service_status["task_definition_arn"]

        response = ecs_client.update_service(
            cluster=cluster,
            service=service,
            taskDefinition=original_task_definition_arn,
        )

        if wait_service_stable:
            wait_for_service_stable(
                cluster=cluster,
                service=service,
                configuration=configuration,
                secrets=secrets,
            )

        if original_task_definition_arn != service_descriptor["taskDefinition"]:
            deregister_response = ecs_client.deregister_task_definition(
                taskDefinition=service_descriptor["taskDefinition"]
            )
            ecs_client.delete_task_definitions(
                taskDefinitions=[
                    deregister_response["taskDefinition"]["taskDefinitionArn"],
                ]
            )

        restored_arns.append(response["service"]["serviceArn"])
        delete_service_state(state_obj=state)

    return restored_arns
