output "application_web_url" {
  value = "http://${module.public_alb.lb_dns_name}"
}

output "sample_blog_web_url" {
  value = length(module.sample_blog_alb) > 0 ? "http://${module.sample_blog_alb[0].lb_dns_name}" : ""
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

resource "aws_ssm_parameter" "sample_blog_web_url" {
  name  = "/${var.environment}/app/${var.application_name}/sample_blog_web_url"
  value = "http://${module.sample_blog_alb[0].lb_dns_name}"
  count = var.deploy_sample_blog_application ? 1 : 0
  type  = "String"
}