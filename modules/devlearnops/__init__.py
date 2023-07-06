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
