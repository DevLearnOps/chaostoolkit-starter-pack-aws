variable "environment" {
  description = "The environment name for the infrastructure deployment"
  type        = string
}

variable "program" {
  description = "The name of the program or team that manages this infrastructure"
  type        = string
}

variable "tags" {
  description = "(Optional) Additional user defined tags for created resources"
  type        = map(string)
  default     = {}
}

########################################################################
#  Application Variables
########################################################################
variable "application_name" {
  description = "The name of the application we will host in this infrastructure"
  type        = string
}

variable "application_version" {
  description = "The version of the application to deploy"
  type        = string
}

variable "autoscaling_max_capacity" {
  description = "(Optional) The maximum autoscaling capacity of services"
  type        = number
  default     = 4
}

variable "autoscaling_min_capacity" {
  description = "(Optional) The minimum autoscaling capacity of services"
  type        = number
  default     = 2
}

variable "service_cpu_units" {
  description = "(Optional) The amount of cpu units to be allocated for tasks"
  type        = number
  default     = 256
}

variable "service_memory" {
  description = "(Optional) The amount of memory in MB to be allocated for tasks"
  type        = number
  default     = 512
}

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
