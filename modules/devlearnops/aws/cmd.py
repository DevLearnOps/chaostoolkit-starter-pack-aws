"""Utility package to interact with command line programs"""
import os
import shutil
from subprocess import PIPE, STDOUT, Popen
from typing import List, Optional

from chaoslib.exceptions import FailedActivity


def check_program_exists(program: str):
    """Check if aws-fail-az program is installed in the system"""
    if shutil.which(program) is None:
        raise FailedActivity(
            f"Unable to simulate az failure. `{program}` program is not installed in the system"
            " or could not be found in system's $PATH."
        )


def run_fail_az(
    subcommand: str,
    namespace: Optional[str] = None,
    args: Optional[List[str]] = None,
    payload: Optional[str] = None,
    state_table: Optional[str] = None,
    capture_output: bool = False,
):
    """
    Execute aws-fail-az command line program

    Parameters
    ----------
    subcommand: str
        The subcommand for aws-fail-az (fail|recover|state-save|state-read|state-delete)
    namespace: str
        The namespace argument for aws-fail-az. Default is 'chaostoolkit'
    args: List[str]
        Additional command-line arguments for aws-fail-az
    payload: str
        Data as string that will be sent to the command via stdin
    capture_output: bool
        If true the output of the command will be captured and returned

    Returns
    -------
    out: str
        the captured output
    return_code: int
        the command return code
    """
    env = os.environ.copy()
    if state_table:
        env["AWS_FAILAZ_STATE_TABLE"] = state_table

    cmd = [
        "aws-fail-az",
        subcommand,
        "--ns",
        namespace or "chaostoolkit",
    ]

    if payload is not None and len(payload) > 0:
        cmd.append("--stdin")
    if args:
        cmd.extend(args)

    with Popen(
        cmd,
        stdout=PIPE if capture_output else None,
        stdin=PIPE,
        stderr=STDOUT,
        env=env,
    ) as p:
        if payload is not None and len(payload) > 0:
            out, _ = p.communicate(payload.encode("utf-8"))
        else:
            out, _ = p.communicate()

        return_code = p.returncode or 0

    return out, return_code
