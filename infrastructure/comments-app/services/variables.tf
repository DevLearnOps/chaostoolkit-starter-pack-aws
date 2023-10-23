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

variable "bastion_key_pair_name" {
  description = "(Optional) SSH key pair for bastion access into the infrastructure"
  type        = string
  default     = ""
}

variable "deploy_sample_blog_application" {
  description = "(Optional) Deploy the sample blog application. Default: false"
  type        = bool
  default     = false
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

variable "generic_service_cpu_units" {
  description = "(Optional) The amount of cpu units to be allocated for tasks"
  type        = number
  default     = 256
}

variable "generic_service_memory" {
  description = "(Optional) The amount of memory in MB to be allocated for tasks"
  type        = number
  default     = 512
}

variable "java_service_cpu_units" {
  description = "(Optional) The amount of cpu units to be allocated for tasks running Java applications"
  type        = number
  default     = 1024
}

variable "java_service_memory" {
  description = "(Optional) The amount of memory in MB to be allocated for tasks running Java applications"
  type        = number
  default     = 2048
}

variable "alb_access_logs_to_bucket_enabled" {
  description = "(Optional) Store ALB access logs to S3 bucket"
  type        = bool
  default     = false
}
