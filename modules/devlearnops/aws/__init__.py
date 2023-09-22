import boto3


def get_account_id() -> str:
    """
    Returns the current AWS account ID
    """
    return boto3.client("sts").get_caller_identity().get("Account")


def get_current_region() -> str:
    """
    Returns the current AWS region name
    """
    return boto3.client("s3").meta.region_name
