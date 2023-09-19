import boto3


def get_account_id():
    return boto3.client("sts").get_caller_identity().get("Account")


def get_current_region():
    session = boto3.session.Session()
    return session.region_name
