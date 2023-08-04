from typing import Any, Dict, List

from chaosaws import aws_client
from chaosaws.ssm.actions import send_command as send_command_wrapped
from chaosaws.types import AWSResponse
from chaoslib.types import Configuration, Secrets
from devlearnops import select_items
from logzero import logger

__all__ = ["send_command"]


def send_command(
    document_name: str,
    targets: List[Dict[str, Any]] = None,
    targets_percent: int = 100,
    targets_count: int = None,
    document_version: str = "$DEFAULT",
    parameters: Dict[str, Any] = None,
    timeout_seconds: int = 60,
    max_concurrency: str = "1",
    max_errors: str = "0",
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> AWSResponse:
    """
    Wraps the send_command action to allow selecting a subset of instances to attack.

    An SSM document defines the actions that SSM performs on your managed.
    For more information about SSM SendCommand:
    https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_SendCommand.html
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ssm.html#SSM.Client.send_command
    """
    # pylint: disable=too-many-arguments

    client = aws_client("ssm", configuration, secrets)

    results = client.describe_instance_information(
        Filters=targets,
    )
    instances = select_items(
        results["InstanceInformationList"], count=targets_count, percent=targets_percent
    )

    instance_ids = list(map(lambda i: i["InstanceId"], instances))
    logger.info("Selecting SSM managed instances: %s", str(instance_ids))

    return send_command_wrapped(
        document_name=document_name,
        targets=[{"Key": "InstanceIds", "Values": instance_ids}],
        document_version=document_version,
        parameters=parameters,
        timeout_seconds=timeout_seconds,
        max_concurrency=max_concurrency,
        max_errors=max_errors,
        configuration=configuration,
        secrets=secrets,
    )
