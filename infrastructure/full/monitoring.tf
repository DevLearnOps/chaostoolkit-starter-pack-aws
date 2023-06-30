module "avg_response_time_internal_alarm" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"

  alarm_name          = "internal-alb-avg-target-response-time"
  alarm_description   = "Avg Target Response Time for Internal Alb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 1.0
  period              = 60

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  statistic   = "Average"
  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = module.internal_alb.lb_arn_suffix
  }
}

module "avg_response_time_user_alarm" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"

  alarm_name          = "user-facing-alb-avg-target-response-time"
  alarm_description   = "Avg Target Response Time for User Facing Alb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 1.2
  period              = 60

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  statistic   = "Average"
  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = module.public_alb.lb_arn_suffix
  }
}

module "http_target_5xx_count_internal_alarm" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"

  alarm_name          = "internal-http-target-5xx-count-alarm"
  alarm_description   = "Avg Target Response Time for Internal Alb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 100
  period              = 60

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"
  statistic   = "Sum"
  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = module.internal_alb.lb_arn_suffix
  }
}
