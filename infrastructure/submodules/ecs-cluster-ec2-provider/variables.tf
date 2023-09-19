variable "name" {
  description = "A common name for the resources in this module"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnets" {
  description = "The list of subnets"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for container instances"
  type        = string
}

variable "min_size" {
  description = "Minimum instance count"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum instance count"
  type        = number
  default     = 5
}

variable "log_level" {
  description = "The log level of container instances"
  type        = string
  default     = "info"
}

variable "key_name" {
  description = "(Optional) The name of the ssh key pair"
  type        = string
  default     = ""
}

variable "sg_ingress_with_secgroup_id" {
  description = "(Optional) The list of ingress rules for the security group with cidr blocks"
  type = map(object({
    description                  = string
    ip_protocol                  = string
    from_port                    = number
    to_port                      = number
    referenced_security_group_id = string
  }))
  default = {}
}

variable "sg_egress_with_cidr_blocks" {
  description = "(Optional) The list of egress rules for the security group with cidr blocks"
  type = map(object({
    description = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    cidr_ipv4   = string
  }))
  default = {}
}

variable "sg_egress_with_prefix_list_ids" {
  description = "(Optional) The list of egress rules for the security group with prefix list ids"
  type = map(object({
    description    = string
    ip_protocol    = string
    from_port      = number
    to_port        = number
    prefix_list_id = string
  }))
  default = {}
}

variable "container_instance_tags" {
  description = "(Optional) Additional user defined container instance tags"
  type        = map(string)
  default     = {}
}
