from botocore.exceptions import ClientError
from chaosaws import aws_client
from chaosaws.types import AWSResponse
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets

__all__ = [
    "start_db_instance",
]


def start_db_instance(
    db_instance_identifier: str,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> AWSResponse:
    """
    Starts a RDS DB instance

    - db_instance_identifier: the instance identifier of the RDS instance
    """
    client = aws_client("rds", configuration, secrets)

    params = dict(DBInstanceIdentifier=db_instance_identifier)

    try:
        return client.start_db_instance(**params)
    except ClientError as e:
        raise FailedActivity(
            "Failed to start RDS DB instance %s: %s"
            % (db_instance_identifier, e.response["Error"]["Message"])
        )
