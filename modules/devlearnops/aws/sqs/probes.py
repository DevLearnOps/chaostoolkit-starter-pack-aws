import json
import time

from chaosaws import aws_client
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets

__all__ = ["wait_for_alarm_notification"]


def _filter_message(data, topic_arn, alarm_name):
    msg_type = data.get("Type")
    if msg_type != "Notification":
        return False

    topic = data.get("TopicArn")
    if topic_arn and topic != topic_arn:
        return False

    payload = data.get("Message")
    json_payload = json.loads(payload)

    if alarm_name:
        return json_payload.get("AlarmName") == alarm_name

    return False


def wait_for_alarm_notification(
    queue_url: str,
    topic_arn: str = None,
    alarm_name: str = None,
    consume_message: bool = True,
    timeout: int = 60,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> str:
    """
    Waits for an alarm notification to be published to an SQS topic

    Parameters
    ----------
    queue_url: str
        The AWS SQS queue url
    topic_arn: str
        The Arn of the topic
    alarm_name: str
        The name of the alarm that generated the notification
    consume_message: bool
        If set to True, the function will consume the message and remove it from
        the queue. Default: True
    timeout: int
        The timeout in seconds for the message to be received

    Returns
    -------
    str: the content of the notification
    """
    client = aws_client("sqs", configuration, secrets)

    time_limit = time.time() + timeout

    while time.time() < time_limit:
        results = client.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=20,
        )
        for msg in results.get("Messages", []):
            handle = msg.get("ReceiptHandle")
            body = msg.get("Body")
            data = json.loads(body)

            if _filter_message(data, topic_arn, alarm_name):
                if consume_message:
                    client.delete_message(
                        QueueUrl=queue_url,
                        ReceiptHandle=handle,
                    )
                payload = json.loads(data.get("Message"))
                return payload

    raise FailedActivity("Operation timed out.")
