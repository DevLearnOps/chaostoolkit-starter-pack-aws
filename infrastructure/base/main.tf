provider "aws" {
  default_tags {
    tags = merge(
      {
        Environment = var.environment
        Program     = var.program
      },
      var.tags,
    )
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = "${var.environment}-${var.program}"

  azs        = slice(data.aws_availability_zones.available.names, 0, var.number_of_azs)
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

########################################################################
#  AWS VPC
########################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]

  # cost saving measure. No outbound access for private subnets
  single_nat_gateway = true
  enable_nat_gateway = false
}

resource "aws_security_group" "vpc_endpoint_secgroup" {
  name        = "${local.name}-vpce-secgroup"
  description = "Allow TLS inbound traffic from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.0.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoint_secgroup.id]
  subnet_ids         = module.vpc.private_subnets

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    },
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
    },
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = true
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = true
    },
  }
}

########################################################################
#  Create Application Databases
########################################################################
locals {
  db_port     = 3306
  db_username = "${var.application_name}_user"
  db_schema   = "${upper(var.application_name)}_SCHEMA"
}

module "app_database_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.name}-${var.application_name}-db-secgroup"
  description = "MySQL security group for ${var.application_name} application database"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]
}

module "application_database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.9.0"

  identifier = "${local.name}-${var.application_name}-db"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = var.application_db_instance_class

  allocated_storage = var.application_db_allocated_storage

  db_name                = local.db_schema
  username               = local.db_username
  port                   = local.db_port
  create_random_password = true

  multi_az = true

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.app_database_security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Application = var.application_name,
  }
}

module "compute_environment" {
  source = "../submodules/compute-environment"

  name = local.name

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  job_definition_environment = [{
    name  = "CHAOS_CONTEXT"
    value = var.environment
  }]

  sns_notification_topic_name = var.sns_notification_topic_name
}
