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
    """
    Reads the content of a parameter from AWS Systems Manager

    Parameters
    ----------
    name: str
        the SSM parameter name

    Returns
    -------
    str: the current value of the SSM parameter
    """
    client = aws_client("ssm", configuration, secrets)

    results = client.get_parameter(Name=name)
    if not results:
        raise FailedActivity(f"no parameter value found for name '{name}'")

    value = results["Parameter"].get("Value")
    logger.debug("resolved parameter value: [%s]", value)
    return value
