import time

from chaosaws import aws_client
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = [
    "wait_for_service_attribute",
    "wait_for_service_stable",
]


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


def wait_for_service_stable(
    cluster: str,
    service: str,
    delay: int = 60,
    max_attempts: int = 30,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    """
    Waits for an ECS service to finish deployment and enter steady state

    Parameters
    ----------
    cluster: str
        The ECS cluster name
    service: str
        The ECS service name
    delay: int
        The amount of time in seconds to wait between attempts. Default: 60
    max_attempts: int
        The maximum number of attempts to be made. Default: 30

    Returns
    -------
    bool:
        True if the service reached its stable state.
    """
    client = aws_client("ecs", configuration, secrets)
    waiter = client.get_waiter("services_stable")

    logger.info("Waiting for service [%s] to reach a stable state...", service)
    waiter.wait(
        cluster=cluster,
        services=[service],
        WaiterConfig={
            "Delay": delay,
            "MaxAttempts": max_attempts,
        },
    )

    logger.info("Service [%s] successfully reached a stable state.", service)
    return True
