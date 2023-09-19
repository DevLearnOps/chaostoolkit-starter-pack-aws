import math
from typing import List


def sanitize_name_for_path(name, max_len: int = 50) -> str:
    """
    Returns a name that can be used in paths

    Parameters
    ----------
    name: str
        the name to sanitize
    max_len: int
        truncate name to max_len characters
    """
    return (
        name.strip()
        .replace(" ", "-")
        .replace(".", "")
        .replace("/", "")
        .replace("'", "")
        .replace('"', "")
        .lower()[: max(1, max_len)]
    )


def select_items(items: List, count: int = None, percent: int = 100) -> List:
    """
    Selects a subset of items based on count or percentage.
    If not argument is provided, by default all items are selected.

    Parameters
    ----------
    items: List
        the list of items to select from
    count: int
        (Optional) the absolute number of items to select
    percent: int
        (Optional) the percentage of the total items to select
    """
    if not count:
        count = math.ceil(len(items) * (percent / 100))

    return items[: min(count, len(items))]
