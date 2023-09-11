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

####################################
#           Variables              #
####################################
variable "environment" {
  type        = string
  description = "The name of the environment"
}
variable "vpc_id_parameter" {
  type        = string
  description = "The SSM parameter name that contains the VPC Id"
}
variable "subnets_parameter" {
  type        = string
  description = "The SSM parameter name that contains the list of subnet Ids"
}
variable "instance_type" {
  type        = string
  description = "(Optional) The EC2 instance type for the proxy server"
  default     = "t3.micro"
}
variable "associate_public_ip_address" {
  type        = bool
  description = "(Optional) Associate a public IP address to the ToxiProxy instance for remote access. Default: false"
  default     = false
}

data "aws_ssm_parameter" "vpc_id" {
  name = var.vpc_id_parameter
}
data "aws_ssm_parameter" "subnets" {
  name = var.subnets_parameter
}

####################################
#           Resources              #
####################################
module "ec2_secgroup" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.environment}-toxiproxy-ec2"
  description = "Toxiproxy EC2 security group"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress_rules       = ["http-80-tcp", "ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8474
      to_port     = 8474
      protocol    = "tcp"
      description = "Ingress for toxiproxy admin API"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8000
      to_port     = 9000
      protocol    = "tcp"
      description = "Ingress for proxies"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Ingress for MySQL/Aurora proxies"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.environment}-toxiproxy"

  instance_type          = var.instance_type
  monitoring             = true
  vpc_security_group_ids = [module.ec2_secgroup.security_group_id]
  subnet_id              = element(split(",", data.aws_ssm_parameter.subnets.value), 0)

  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = <<EOF
#!/bin/bash
wget https://github.com/Shopify/toxiproxy/releases/download/v2.5.0/toxiproxy_2.5.0_linux_amd64.rpm
sudo yum localinstall -y toxiproxy_2.5.0_linux_amd64.rpm
nohup toxiproxy-server --host 0.0.0.0 --port 8474 &
EOF
  user_data_replace_on_change = true
}

####################################
#            Outputs               #
####################################
output "toxiproxy_admin_url" {
  value = var.associate_public_ip_address ? "http://${module.ec2_instance.public_ip}:8474" : "http://${module.ec2_instance.private_ip}:8474"
}
output "toxiproxy_private_ip" {
  value = module.ec2_instance.private_ip
}
