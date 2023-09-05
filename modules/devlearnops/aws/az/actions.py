"""AZ failure using aws-fail-az"""

import json
from typing import Dict, List, Optional

from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets

from ..cmd import run_fail_az

__all__ = [
    "fail_azs",
    "recover_azs",
]


def fail_azs(
    azs: List[str],
    targets: List[Dict],
    namespace: Optional[str] = None,
    state_table: Optional[str] = None,
    capture_output: bool = False,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    # pylint: disable=unused-argument
    """
    Simulate AZ failure using aws-fail-az program

    Parameters
    ----------
    azs: List[str]
        The list of availability zones to fail
    targets: List[Dict]
        The list of targets filters to use for az failure
        (see aws-fail-az documentation https://github.com/mcastellin/aws-fail-az)
    namespace: str
        (Optional) The namespace of the test state
    state_table: str
        (Optional) The name of the Dynamodb table aws-fail-az should use to store state.
    capture_output: bool
        Capture the command output and return it in the journal

    Returns
    -------
    str:
        Returns output of the aws-fail-az command
    """

    fault_configuration = {
        "azs": azs,
        "targets": targets,
    }
    payload = json.dumps(fault_configuration)

    out, return_code = run_fail_az(
        subcommand="fail",
        namespace=namespace,
        payload=payload,
        state_table=state_table,
        capture_output=capture_output,
    )
    if return_code != 0:
        raise FailedActivity(
            f"Could not complete AZ failure simulation. Return code: {return_code}"
        )

    return out.decode("utf-8") if out else ""


def recover_azs(
    namespace: Optional[str] = None,
    state_table: Optional[str] = None,
    capture_output: bool = False,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    # pylint: disable=unused-argument
    """
    Simulate AZ failure using aws-fail-az program

    Parameters
    ----------
    namespace: str
        (Optional) The namespace of the test state
    state_table: str
        (Optional) The name of the Dynamodb table aws-fail-az should use to store state.
    capture_output: bool
        Capture the command output and return it in the journal

    Returns
    -------
    str:
        Returns output of the aws-fail-az command
    """

    out, return_code = run_fail_az(
        subcommand="recover",
        namespace=namespace,
        state_table=state_table,
        capture_output=capture_output,
    )
    if return_code != 0:
        raise FailedActivity(
            f"Could not recover AZ failure. Return code: {return_code}"
        )

    return out.decode("utf-8") if out else ""
