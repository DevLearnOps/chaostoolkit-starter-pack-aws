import time
from typing import List

from chaosaws import aws_client
from chaosaws.cloudwatch.probes import get_metric_statistics
from chaoslib.exceptions import FailedActivity
from chaoslib.types import Configuration, Secrets
from logzero import logger

__all__ = ["wait_for_service_attribute"]


def _get_service_alb_suffix(cluster, service, ecs_client, elbv2_client) -> str:
    response = ecs_client.describe_services(cluster=cluster, services=[service])
    if len(response.get("services", [])) != 1:
        raise FailedActivity(
            "Could not uniquely identify ECS service for"
            " cluster [{cluster}] and service [{service}]"
        )

    descriptor = response.get("services")[0]
    service_tg = descriptor["loadBalancers"][0]["targetGroupArn"]

    response = elbv2_client.describe_target_groups(TargetGroupArns=[service_tg])
    target_group = response["TargetGroups"][0]
    load_balancer_arn = target_group["LoadBalancerArns"][0]
    return load_balancer_arn.split("/", maxsplit=1)[1]


def _get_metric(metric_name, alb_suffix, duration):
    namespace = "AWS/ApplicationELB"
    return get_metric_statistics(
        namespace=namespace,
        metric_name=metric_name,
        dimensions=[{"Name": "LoadBalancer", "Value": alb_suffix}],
        statistic="Sum",
        unit="Count",
        duration=duration,
    )


def wait_for_service_attribute(
    cluster: str,
    service: str,
    attribute: str,
    expected: int,
    timeout: int = 60,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> bool:
    client = aws_client("ecs", configuration, secrets)

    time_limit = time.time() + timeout

    while time.time() < time_limit:
        results = client.describe_services(cluster=cluster, services=[service])
        if len(results.get("services", [])) != 1:
            raise FailedActivity(
                "Could not uniquely identify ECS service for"
                " cluster [{cluster}] and service [{service}]"
            )

        descriptor = results.get("services")[0]
        if descriptor.get(attribute) == expected:
            return True

        time.sleep(20)

    raise FailedActivity("Operation timed out.")


def get_cloudwatch_transactions_per_second(
    cluster: str,
    service: str,
    duration: int = 60,
    configuration: Configuration = None,
    secrets: Secrets = None,
) -> int:
    ecs_client = aws_client("ecs", configuration, secrets)
    elbv2_client = aws_client("elbv2", configuration, secrets)
    alb_suffix = _get_service_alb_suffix(
        cluster,
        service,
        ecs_client,
        elbv2_client,
    )

    http_200_count = _get_metric("HTTPCode_Target_2XX_Count", alb_suffix, duration)
    http_400_count = _get_metric("HTTPCode_Target_4XX_Count", alb_suffix, duration)
    total_requests_count = _get_metric("RequestCount", alb_suffix, duration)

    logger.info(
        f"CloudWatch: Metric Value for HTTPCode_Target_2XX_Count={http_200_count}"
    )
    logger.info(
        f"CloudWatch: Metric Value for HTTPCode_Target_4XX_Count={http_400_count}"
    )
    logger.info(f"CloudWatch: Metric Value for RequestCount={total_requests_count}")

    if total_requests_count > 0:
        avg_success_rate = int(
            ((http_200_count + http_400_count) / total_requests_count) * 100
        )
        return avg_success_rate

    return 0


get_cloudwatch_transactions_per_second(
    cluster="live-comments-full-cluster",
    service="comments-api-service",
    duration=120,
)
