output "application_web_url" {
  value = "http://${module.public_alb.lb_dns_name}"
}

resource "aws_ssm_parameter" "application_web_url" {
  name  = "/${var.environment}/app/${var.application_name}/web_url"
  value = "http://${module.public_alb.lb_dns_name}"
  type  = "String"
}

resource "aws_ssm_parameter" "internal_alb_dns_name" {
  name  = "/${var.environment}/app/${var.application_name}/internal_alb_dns_name"
  value = module.internal_alb.lb_dns_name
  type  = "String"
}

resource "aws_ssm_parameter" "app_cluster_ec2_autoscaling_name" {
  name  = "/${var.environment}/app/${var.application_name}/autoscaling_group/ondemand/name"
  value = module.app_cluster_ec2.autoscaling["ondemand"].autoscaling_group_name
  type  = "String"
}

resource "aws_ssm_parameter" "sre_notification_topic_arn" {
  name  = "/${var.environment}/app/${var.application_name}/sre/notification_topic_arn"
  value = aws_sns_topic.sre_updates.arn
  type  = "String"
}
