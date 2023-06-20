from typing import Any, Dict
import os

from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = ["set_env"]


def set_env(
    environ: Dict[str, Any],
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    for key, value in environ:
        os.environ[key] = value
    return True
