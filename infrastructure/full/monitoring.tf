module "avg_response_time_internal_alarm" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"

  alarm_name          = "internal-alb-avg-target-response-time"
  alarm_description   = "Avg Target Response Time for Internal Alb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 0.5
  period              = 60

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  statistic   = "Average"

  dimensions = {
    LoadBalancer = module.internal_alb.lb_arn_suffix
  }
}
