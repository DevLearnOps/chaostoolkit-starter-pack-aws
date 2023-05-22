terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10"
    }
  }
}
provider "aws" {
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  default_tags {
    tags = {
      ChaosEngineeringTeam = true
    }
  }
}

locals {
  filter_tags = {
    Name        = "chaos-security"
    Application = "Nginx"
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/vpc/id"
}
data "aws_ssm_parameter" "private_subnets_cidr_blocks" {
  name = "/vpc/cidr-blocks/private_subnets"
}

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "chaos-dummy-secgroup"
  description = "A dummy security group for chaos engineering testing"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = split(",", data.aws_ssm_parameter.private_subnets_cidr_blocks.value)
}

data "aws_lb" "application_lb" {
  tags = local.filter_tags
}

data "aws_security_group" "current_secgroup" {
  tags = merge(local.filter_tags, { Role = "alb-main" })
}

output "alb_name" {
  value = data.aws_lb.application_lb.name
}

output "alb_arn_suffix" {
  value = data.aws_lb.application_lb.arn_suffix
}

output "alb_public_url" {
  value = "http://${data.aws_lb.application_lb.dns_name}"
}

output "current_alb_id" {
  value = data.aws_security_group.current_secgroup.id
}

output "dummy_alb_id" {
  value = module.alb_sg.security_group_id
}
