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
  type = string
}

####################################
#           Resources              #
####################################
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
