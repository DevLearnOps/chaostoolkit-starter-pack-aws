output "application_web_url" {
  value = "http://${module.public_alb.lb_dns_name}"
}

output "bastion_public_ip" {
  value = var.bastion_key_pair_name == "" ? "" : module.ec2_bastion[0].public_ip
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
