"""
Utility functions for ECS attacks
"""
import json
from typing import Optional

from chaoslib.exceptions import FailedActivity

from ..cmd import run_fail_az

TASK_DEF_RESOURCE_TYPE = "z-ecs-task-definition"


def save_service_state(service_descriptor, state_table: Optional[str] = None):
    """
    Saves the state of an ecs service
    """
    cluster = service_descriptor["clusterArn"]
    service = service_descriptor["serviceName"]
    resource_key = f"{cluster}-{service}"

    state = {
        "cluster_name": cluster,
        "service_name": service,
        "task_definition_arn": service_descriptor["taskDefinition"],
    }
    payload = json.dumps(state)

    args = [
        "--type",
        TASK_DEF_RESOURCE_TYPE,
        "--key",
        resource_key,
    ]
    out, return_code = run_fail_az(
        subcommand="state-save",
        args=args,
        payload=payload,
        state_table=state_table,
        capture_output=True,
    )

    if return_code != 0:
        raise FailedActivity(
            f"Could not save the requested state. Return code: {return_code}. Output: >\n{out.decode('utf-8')}"
        )


def read_service_states(state_table: Optional[str] = None):
    """
    Saves the state of an ecs service
    """

    args = [
        "--type",
        TASK_DEF_RESOURCE_TYPE,
    ]
    out, return_code = run_fail_az(
        subcommand="state-read", args=args, state_table=state_table, capture_output=True
    )
    if return_code != 0:
        raise FailedActivity(
            f"Could not search existing states. Return code: {return_code}. Output: >\n{out.decode('utf-8')}"
        )

    states = json.loads(out.decode("utf-8"))
    for state in states:
        state["state"] = json.loads(state["state"])
    return states


def delete_service_state(state_obj, state_table: Optional[str] = None):
    """
    Saves the state of an ecs service
    """

    args = [
        "--type",
        state_obj["type"],
        "--key",
        state_obj["key"],
    ]
    out, return_code = run_fail_az(
        subcommand="state-delete",
        args=args,
        state_table=state_table,
        capture_output=True,
    )

    if return_code != 0:
        raise FailedActivity(
            f"Could not delete the requested state. Return code: {return_code}. Output: >\n{out.decode('utf-8')}"
        )


def get_updatable_task_definition(ecs_client, task_definition_arn: str):
    """
    Returns an ECS task definition object stripped out of all non-updatable attributes

    Parameters
    ----------
    ecs_client:
        The boto3 client for ECS
    task_definition_arn: str
        The Arn of the task_definition
    """
    response = ecs_client.describe_task_definition(taskDefinition=task_definition_arn)
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


def describe_service(ecs_client, cluster: str, service: str):
    """Retrieves an ECS service descriptor from AWS"""
    results = ecs_client.describe_services(cluster=cluster, services=[service])
    if len(results["services"]) > 0:
        return results["services"][0]

    return None
