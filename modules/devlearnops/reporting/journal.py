import json
from typing import TypedDict

from .models import Journal
from .schemas import JournalSchema


class ExecutionReport(TypedDict):
    """A typing class to represent the execution report"""

    experiment_title: str
    experiment_result: str
    experiment_status: str
    has_failures: bool
    execution_summary: str
    total_duration: str


def execution_report(journal_path: str) -> (Journal, ExecutionReport):
    """
    Creates an execution report in json format from the information in the journal.

    Parameters
    ----------
    journal_path: str
        The path for the journal file

    Returns
    -------
    ExecutionReport:
        The execution report in json format
    """
    with open(journal_path, mode="r") as file:
        data = json.load(file)

    result: Journal = JournalSchema().load(data)

    if result.deviated is True:
        experiment_result = "successful"
    else:
        experiment_result = "deviated"

    fail_summary = result.fail_summary()

    report = {
        "experiment_title": result.experiment.title,
        "experiment_result": experiment_result,
        "experiment_status": result.status,
        "has_failures": bool(len(fail_summary) > 0),
        "execution_summary": fail_summary,
        "total_duration": str(result.duration),
    }
    return result, report
