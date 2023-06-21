output "frontend_url" {
  value = "http://${module.public_alb.lb_dns_name}"
}
output "internal_url" {
  value = "http://${module.internal_alb.lb_dns_name}"
}

resource "aws_ssm_parameter" "application_web_url" {
  name  = "/app/${var.application_name}/${var.environment}/web_url"
  value = "http://${module.public_alb.lb_dns_name}"
  type  = "String"
}
