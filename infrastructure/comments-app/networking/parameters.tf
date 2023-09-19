########################################################################
#  VPC Parameters
########################################################################
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.environment}/vpc/id"
  value = module.vpc.vpc_id
  type  = "String"
}
resource "aws_ssm_parameter" "vpc_cidr_block" {
  name  = "/${var.environment}/vpc/cidr-blocks/vpc"
  value = module.vpc.vpc_cidr_block
  type  = "String"
}
resource "aws_ssm_parameter" "public_subnets" {
  name  = "/${var.environment}/vpc/public_subnets"
  value = join(",", module.vpc.public_subnets)
  type  = "String"
}
resource "aws_ssm_parameter" "private_subnets" {
  name  = "/${var.environment}/vpc/private_subnets"
  value = join(",", module.vpc.private_subnets)
  type  = "String"
}
resource "aws_ssm_parameter" "private_subnets_cidr_blocks" {
  name  = "/${var.environment}/vpc/cidr-blocks/private_subnets"
  value = join(",", module.vpc.private_subnets_cidr_blocks)
  type  = "String"
}
resource "aws_ssm_parameter" "public_subnets_cidr_blocks" {
  name  = "/${var.environment}/vpc/cidr-blocks/public_subnets"
  value = join(",", module.vpc.public_subnets_cidr_blocks)
  type  = "String"
}
resource "aws_ssm_parameter" "s3_prefix_list_id" {
  name  = "/${var.environment}/vpc/s3_prefix_list_id"
  value = module.vpc_endpoints.endpoints.s3.prefix_list_id
  type  = "String"
}
resource "aws_ssm_parameter" "nat_bastion_secgroup_id" {
  name  = "/${var.environment}/vpc/nat-bastion/security_group_id"
  value = aws_security_group.nat_bastion_secgroup.id
  type  = "String"
}

########################################################################
#  Application Database Parameters
########################################################################
resource "aws_ssm_parameter" "application_db_password" {
  name  = "/${var.environment}/app/${var.application_name}/db_password"
  value = module.application_database.db_instance_password
  type  = "SecureString"
}
resource "aws_ssm_parameter" "application_db_username" {
  name  = "/${var.environment}/app/${var.application_name}/db_username"
  value = local.db_username
  type  = "String"
}
resource "aws_ssm_parameter" "application_db_connection_string" {
  name  = "/${var.environment}/app/${var.application_name}/db_connection_string"
  value = "jdbc:mysql://${module.application_database.db_instance_endpoint}/${local.db_schema}"
  type  = "String"
}
resource "aws_ssm_parameter" "application_db_instance_address" {
  name  = "/${var.environment}/app/${var.application_name}/db_instance_address"
  value = module.application_database.db_instance_address
  type  = "String"
}
