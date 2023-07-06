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
  name = "chaos-${basename(path.cwd)}"

  vpc_cidr   = "10.0.0.0/16"
  azs        = slice(data.aws_availability_zones.available.names, 0, var.azs)
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  alb_tags = {
    Name        = local.name
    Application = "Back"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  single_nat_gateway = true
  enable_nat_gateway = true
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
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

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

locals {
  db_port     = 3306
  db_username = "comments_user"
  db_schema   = "COMMENTS_API"
}

module "db_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = local.name
  description = "Complete MySQL example security group"
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

module "db_default" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.9.0"

  identifier = "${local.name}-default"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t4g.micro"

  allocated_storage = 20

  db_name                = local.db_schema
  username               = local.db_username
  port                   = local.db_port
  create_random_password = true

  multi_az = true

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
}

module "compute_environment" {
  source = "../compute-environment"

  environment = "live"
  program     = "chaos"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  notification_topic = "chaos-experiment-result-status"
}
