module "avg_response_time_internal_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "4.3.0"

  alarm_name          = "TargetResponseTime-Avg/${var.environment}/${var.application_name}/internal-alb"
  alarm_description   = "Avg Target Response Time for Internal Alb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 1.0
  period              = 60

  namespace          = "AWS/ApplicationELB"
  metric_name        = "TargetResponseTime"
  statistic          = "Average"
  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = module.internal_alb.lb_arn_suffix
  }
}

module "avg_response_time_user_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "4.3.0"

  alarm_name          = "TargetResponseTime-Avg/${var.environment}/${var.application_name}/public-alb"
  alarm_description   = "Avg Target Response Time for User Facing Alb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 1.2
  period              = 60

  namespace          = "AWS/ApplicationELB"
  metric_name        = "TargetResponseTime"
  statistic          = "Average"
  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = module.public_alb.lb_arn_suffix
  }
}

module "http_target_5xx_count_internal_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "4.3.0"

  alarm_name          = "Target_5XX_Response-Count/${var.environment}/${var.application_name}/internal-alb"
  alarm_description   = "Avg Target Response Time for Internal Alb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 100
  period              = 60

  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_Target_5XX_Count"
  statistic          = "Sum"
  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = module.internal_alb.lb_arn_suffix
  }
}

module "ecs_service_max_capacity_alarms" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"

  for_each = {
    web = {
      cluster_name   = module.app_cluster.name
      service_name   = module.web_service.name
      max_containers = var.autoscaling_max_capacity
    },
    api = {
      cluster_name   = module.app_cluster.name
      service_name   = module.api_service.name
      max_containers = var.autoscaling_max_capacity
    },
    spamcheck = {
      cluster_name   = module.app_cluster_ec2.cluster_name
      service_name   = module.spamcheck_service.name
      max_containers = var.autoscaling_max_capacity
    },
  }

  alarm_name          = "Service-MaxCapacity/${var.environment}/${var.application_name}/${each.key}"
  alarm_description   = "Service ${each.value.service_name} reached max container capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 60
  unit                = "Count"
  threshold           = each.value.max_containers

  namespace   = "ECS/ContainerInsights"
  metric_name = "DesiredTaskCount"
  statistic   = "Maximum"

  dimensions = {
    ClusterName = each.value.cluster_name,
    ServiceName = each.value.service_name,
  }

  alarm_actions = [aws_sns_topic.sre_updates.arn]
}

###################################################################
# SRE Updates Topic
###################################################################
resource "aws_sns_topic" "sre_updates" {
  name         = "${local.name}-sre-updates"
  display_name = "Urgent Infrastructure Notifications for Site Reliability Engineering Team"
}
