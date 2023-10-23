"""Defines actions for InfoSec attacks against S3"""

import os
import random
import string
import uuid

from chaosaws import aws_client
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = [
    "put_dummy_objects",
]


def put_dummy_objects(
    bucket_name: str,
    objects_count: int,
    prefix: str = None,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    client = aws_client("s3", configuration, secrets)

    for _ in range(objects_count):
        obj_key = str(uuid.uuid4()) + ".txt"
        if prefix:
            obj_key = os.path.join(prefix, obj_key)
        payload = "".join(random.choices(string.ascii_letters, k=128))

        logger.info("Generating dummy S3 object %s", obj_key)
        client.put_object(Bucket=bucket_name, Key=obj_key, Body=payload)

    return True
