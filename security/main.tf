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

variable "azs" {
  type    = number
  default = 2
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  container_port = 80
  cpu            = 256
  memory         = 512
  account_id     = data.aws_caller_identity.current.account_id
  region         = data.aws_region.current.name
}

locals {
  name   = "chaos-${basename(path.cwd)}"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, var.azs)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-vpc"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  single_nat_gateway = true

  tags = local.tags
}

resource "aws_security_group" "vpc_endpoint_secgroup" {
  name        = "${local.name}-vpce-secgroup"
  description = "Allow TLS inbound traffic from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
  }
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoint_secgroup.id]
  subnet_ids = module.vpc.private_subnets

  endpoints = {
    s3 = {
      service = "s3"
      service_type = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    },
    logs = {
      service = "logs"
      service_type = "Interface"
      private_dns_enabled = true
    },
    ecr_api = {
      service = "ecr.api"
      service_type = "Interface"
      private_dns_enabled = true
    },
    ecr_dkr = {
      service = "ecr.dkr"
      service_type = "Interface"
      private_dns_enabled = true
    },
  }
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.name}-cluster"

  services = {
    nginx = {
      cpu = local.cpu
      memory = local.memory
      desired_count = 1
      launch_type = "FARGATE"
      subnet_ids = module.vpc.private_subnets

      container_definitions = {
        nginx = {
          cpu = local.cpu
          memory = local.memory
          essential = true
          image = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/security/nginx"
          port_mappings = [
            {
              containerPort = local.container_port
              hostPort = local.container_port
              protocol = "tcp"
            },
          ]
          readonly_root_filesystem = false
        }
      }

      load_balancer = {
        service = {
          target_group_arn = element(module.alb.target_group_arns, 0)
          container_name = "nginx"
          container_port = local.container_port
        }
      }

      security_group_rules = {
        alb_ingress_80 = {
          type = "ingress"
          description = "Allow from LB to service port"
          from_port = local.container_port
          to_port = local.container_port
          protocol = "tcp"
          source_security_group_id = module.alb_sg.security_group_id
        }
        egress_vpc_cidr = {
          type = "egress"
          description = "Allow outbound to VPC"
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = [module.vpc.vpc_cidr_block]
        }
        egress_s3_prefix_list = {
          type = "egress"
          description = "Allow outbound to S3 service endpoint"
          from_port = 443
          to_port = 443
          protocol = "tcp"
          prefix_list_ids = [module.vpc_endpoints.endpoints.s3.prefix_list_id]
        }
      }
    }
  }
}


module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${local.name}-service"
  description = "Service security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = local.name

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-nginx"
      backend_protocol = "HTTP"
      backend_port     = local.container_port
      target_type      = "ip"
    },
  ]

  tags = local.tags
}
