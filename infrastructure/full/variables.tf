variable "application_name" {
  type    = string
  default = "comments"
}

variable "environment" {
  type    = string
  default = "live"
}

variable "s3_prefix_list_id_parameter" {
  type    = string
  default = "/vpc/s3_prefix_list_id"
}
variable "vpc_id_parameter" {
  type    = string
  default = "/vpc/id"
}
variable "public_subnets_parameter" {
  type    = string
  default = "/vpc/public_subnets"
}
variable "private_subnets_parameter" {
  type    = string
  default = "/vpc/private_subnets"
}
variable "vpc_cidr_block_parameter" {
  type    = string
  default = "/vpc/cidr-blocks/vpc"
}
variable "private_subnets_cidr_blocks_parameter" {
  type    = string
  default = "/vpc/cidr-blocks/private_subnets"
}

variable "comments_db_password_parameter" {
  type    = string
  default = "/app/comments/db_password"
}
variable "comments_db_username_parameter" {
  type    = string
  default = "/app/comments/db_username"
}
variable "comments_db_connection_string_parameter" {
  type    = string
  default = "/app/comments/db_connection_string"
}

# Resolve parameters
data "aws_ssm_parameter" "s3_prefix_list_id" {
  name = var.s3_prefix_list_id_parameter
}
data "aws_ssm_parameter" "vpc_id" {
  name = var.vpc_id_parameter
}
data "aws_ssm_parameter" "public_subnets" {
  name = var.public_subnets_parameter
}
data "aws_ssm_parameter" "private_subnets" {
  name = var.private_subnets_parameter
}
data "aws_ssm_parameter" "vpc_cidr_block" {
  name = var.vpc_cidr_block_parameter
}
data "aws_ssm_parameter" "private_subnets_cidr_blocks" {
  name = var.private_subnets_cidr_blocks_parameter
}

data "aws_ssm_parameter" "comments_db_password" {
  name = var.comments_db_password_parameter
}
data "aws_ssm_parameter" "comments_db_username" {
  name = var.comments_db_username_parameter
}
data "aws_ssm_parameter" "comments_db_connection_string" {
  name = var.comments_db_connection_string_parameter
}
