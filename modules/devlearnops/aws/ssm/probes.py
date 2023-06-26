from typing import List

from chaosaws import aws_client
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = ["get_parameter"]


def get_parameter(
    name: str,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    client = aws_client("ssm", configuration, secrets)

    results = client.get_parameter(Name=name)
    if not results:
        raise FailedActivity(f"no parameter value found for name '{name}'")

    value = results["Parameter"].get("Value")
    logger.debug("resolved parameter value: [%s]", value)
    return value
