from typing import Any, List

from chaosaws.cloudwatch.probes import get_alarm_state_value
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = ["check_alarm_state_value"]


def check_alarm_state_value(
    alarm_names: List[str],
    expected: Any,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> int:
    valid_states = []
    if isinstance(expected, list):
        valid_states = expected
    else:
        valid_states = [expected]

    for alarm_name in alarm_names:
        alarm_state = get_alarm_state_value(
            alarm_name=alarm_name,
            configuration=configuration,
            secrets=secrets,
        )
        if alarm_state not in valid_states:
            logger.info(
                "Alarm with name %s is not in the expected state %s. Found %s.",
                alarm_name,
                valid_states,
                alarm_state,
            )
            return False

    return True
