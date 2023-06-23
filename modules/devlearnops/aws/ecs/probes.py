import time
from typing import List

from chaosaws import aws_client
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = ["wait_for_service_attribute"]


def wait_for_service_attribute(
    cluster: str,
    service: str,
    attribute: str,
    expected: int,
    timeout: int = 60,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    client = aws_client("ecs", configuration, secrets)

    time_limit = time.time() + timeout

    while time.time() < time_limit:
        results = client.describe_services(cluster=cluster, services=[service])
        if len(results.get("services", [])) != 1:
            raise FailedActivity(
                "Could not uniquely identify ECS service for"
                " cluster [{cluster}] and service [{service}]"
            )

        descriptor = results.get("services")[0]
        if descriptor.get(attribute) == expected:
            return True

        time.sleep(20)

    raise FailedActivity("Operation timed out.")
