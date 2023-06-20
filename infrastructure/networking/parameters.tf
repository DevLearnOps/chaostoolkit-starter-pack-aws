# VPC parameters
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/vpc/id"
  value = module.vpc.vpc_id
  type  = "String"
}
resource "aws_ssm_parameter" "vpc_cidr_block" {
  name  = "/vpc/cidr-blocks/vpc"
  value = module.vpc.vpc_cidr_block
  type  = "String"
}
resource "aws_ssm_parameter" "public_subnets" {
  name  = "/vpc/public_subnets"
  value = join(",", module.vpc.public_subnets)
  type  = "String"
}
resource "aws_ssm_parameter" "private_subnets" {
  name  = "/vpc/private_subnets"
  value = join(",", module.vpc.private_subnets)
  type  = "String"
}
resource "aws_ssm_parameter" "private_subnets_cidr_blocks" {
  name  = "/vpc/cidr-blocks/private_subnets"
  value = join(",", module.vpc.private_subnets_cidr_blocks)
  type  = "String"
}
resource "aws_ssm_parameter" "public_subnets_cidr_blocks" {
  name  = "/vpc/cidr-blocks/public_subnets"
  value = join(",", module.vpc.public_subnets_cidr_blocks)
  type  = "String"
}
resource "aws_ssm_parameter" "s3_prefix_list_id" {
  name  = "/vpc/s3_prefix_list_id"
  value = module.vpc_endpoints.endpoints.s3.prefix_list_id
  type  = "String"
}

# Database parameters
resource "aws_ssm_parameter" "comments_db_password" {
  name  = "/app/comments/db_password"
  value = module.db_default.db_instance_password
  type  = "SecureString"
}
resource "aws_ssm_parameter" "comments_db_username" {
  name  = "/app/comments/db_username"
  value = local.db_username
  type  = "String"
}
resource "aws_ssm_parameter" "comments_db_connection_string" {
  name  = "/app/comments/db_connection_string"
  value = "jdbc:mysql://${module.db_default.db_instance_endpoint}/${local.db_schema}"
  type  = "String"
}
