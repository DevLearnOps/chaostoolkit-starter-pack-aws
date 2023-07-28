variable "job_definition_environment" {
  description = "Additional environment variables for the AWS Batch job definition"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "name" {
  description = "The name for the compute environment resources"
  type        = string
}

variable "vpc_id" {
  description = "The Id of the VPC where you want to create the compute environment"
  type        = string
}

variable "subnets" {
  description = "A comma separated list of subnets to use for the compute environment"
  type        = list(string)
}

variable "sns_notification_topic_name" {
  description = "(Optional) The name of the SNS topic to use for job execution notifications"
  type        = string
  default     = ""
}

variable "max_vcpus" {
  description = "(Optional) The maximum allowed vcpus for the compute environment. Default: 1"
  type        = number
  default     = 1
}

variable "task_memory" {
  description = "(Optional) The default amount of memory to allocate for every batch job. Default: 2048"
  type        = number
  default     = 2048
}
