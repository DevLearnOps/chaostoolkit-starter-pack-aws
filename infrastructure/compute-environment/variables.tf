variable "environment" {
  type = string
}

variable "program" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}
