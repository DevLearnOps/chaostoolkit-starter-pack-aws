import time
from typing import Any, Dict

import requests
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = ["wait_for_service_active"]


def wait_for_service_active(
    url: str,
    timeout: int = 60,
    status: int = 200,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    time_limit = time.time() + timeout

    while time.time() < time_limit:
        try:
            response = requests.get(url)
            if response.status_code == status:
                return True
        except requests.exceptions.ConnectionError:
            pass

        time.sleep(5)

    raise FailedActivity("Service still unstable after timeout.")
