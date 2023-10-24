terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10"
    }
  }
}
provider "aws" {
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  default_tags {
    tags = {
      ChaosEngineeringTeam = true
    }
  }
}

####################################
#           Variables              #
####################################
variable "topic_arn" {
  type        = string
  description = "The SNS topic ARN to subscribe"
}

variable "bucket_metric_filter" {
  type        = string
  description = "(Optional): The metric filter for publishing CloudWatch metrics for the bucket"
  default     = "EntireBucket"
}

####################################
#           Resources              #
####################################
data "aws_caller_identity" "current" {}

resource "random_string" "bucket_name" {
  length  = 15
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket        = "${data.aws_caller_identity.current.account_id}-${random_string.bucket_name.result}"
  force_destroy = true
}

resource "aws_s3_bucket_metric" "this" {
  bucket = aws_s3_bucket.this.id
  name   = var.bucket_metric_filter
}

module "sqs_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.2"

  name = "_chaos__receive_notification_queue"

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid     = "SNSPublish"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      condition = {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [var.topic_arn]
      }
    }
  }
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = var.topic_arn
  protocol  = "sqs"
  endpoint  = module.sqs_queue.queue_arn
}

####################################
#            Outputs               #
####################################
output "queue_url" {
  value = module.sqs_queue.queue_url
}

output "bucket_name" {
  value = aws_s3_bucket.this.id
}
