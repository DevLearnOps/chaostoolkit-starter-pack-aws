########################################################################
#  Resolve SSM Parameters
########################################################################

data "aws_ssm_parameter" "s3_prefix_list_id" {
  name = "/${var.environment}/vpc/s3_prefix_list_id"
}
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.environment}/vpc/id"
}
data "aws_ssm_parameter" "public_subnets" {
  name = "/${var.environment}/vpc/public_subnets"
}
data "aws_ssm_parameter" "private_subnets" {
  name = "/${var.environment}/vpc/private_subnets"
}
data "aws_ssm_parameter" "vpc_cidr_block" {
  name = "/${var.environment}/vpc/cidr-blocks/vpc"
}
data "aws_ssm_parameter" "private_subnets_cidr_blocks" {
  name = "/${var.environment}/vpc/cidr-blocks/private_subnets"
}

data "aws_ssm_parameter" "application_db_password" {
  name = "/${var.environment}/app/${var.application_name}/db_password"
}
data "aws_ssm_parameter" "application_db_username" {
  name = "/${var.environment}/app/${var.application_name}/db_username"
}
data "aws_ssm_parameter" "application_db_connection_string" {
  name = "/${var.environment}/app/${var.application_name}/db_connection_string"
}
