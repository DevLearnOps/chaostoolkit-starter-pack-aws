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

########################################################################
#  VPC Variables
########################################################################
variable "vpc_cidr" {
  description = "(Optional) The Cidr block for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "number_of_azs" {
  description = "(Optional) The number of Availability Zones to create for the VPC"
  type        = number
  default     = 2
  validation {
    condition     = var.number_of_azs >= 1 && var.number_of_azs <= 4
    error_message = "The number_of_azs parameter must be between 1 and 4."
  }
}

########################################################################
#  Application Variables
########################################################################
variable "application_name" {
  description = "The name of the application we will host in this infrastructure"
  type        = string
}

variable "application_db_instance_class" {
  description = "(Optional) The instance class for the application database"
  type        = string
  default     = "db.t4g.micro"
}

variable "application_db_allocated_storage" {
  description = "(Optional) The allocated storage for the application database in GB"
  type        = number
  default     = 20
}

########################################################################
#  Batch Compute Environment Variables
########################################################################
variable "sns_notification_topic_name" {
  description = "(Optional) The name of the SNS topic to use for job execution notifications"
  type        = string
  default     = ""
}

variable "journals_bucket" {
  description = "(Optional) The name of the S3 bucket to store experiment journals. If empty, a new bucket is created"
  type        = string
  default     = ""
}
