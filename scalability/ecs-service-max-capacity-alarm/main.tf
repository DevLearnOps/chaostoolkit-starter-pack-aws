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
variable "cluster_name" {
  type    = string
}

variable "service_name" {
  type    = string
}

variable "max_container_count" {
  type    = number
}

variable "statistic" {
  type    = string
  default = "Maximum"
}

####################################
#           Resources              #
####################################
locals {
  evaluation_periods = 1
  period_seconds     = 60
}

module "sqs_queue" {
  source = "terraform-aws-modules/sqs/aws"

  name = "urgent-updates-queue"

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
        values   = [aws_sns_topic.urgent_updates.arn]
      }
    }
  }
}

resource "aws_sns_topic" "urgent_updates" {
  name         = "urgent-updates-topic"
  display_name = "Urgent Infrastructure Notifications"
}

resource "aws_sns_topic_subscription" "urgent_updates_sqs_target" {
  topic_arn = aws_sns_topic.urgent_updates.arn
  protocol  = "sqs"
  endpoint  = module.sqs_queue.queue_arn
}


module "metric_alarm" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"

  alarm_name          = "${var.cluster_name}-${var.service_name}-max-capacity"
  alarm_description   = "Service ${var.service_name} reached max container capacity"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods
  threshold           = var.max_container_count
  period              = local.period_seconds
  unit                = "Count"

  namespace   = "ECS/ContainerInsights"
  metric_name = "DesiredTaskCount"
  statistic   = var.statistic

  dimensions = {
    ClusterName = var.cluster_name,
    ServiceName = var.service_name
  }

  alarm_actions = [aws_sns_topic.urgent_updates.arn]
}

####################################
#            Outputs               #
####################################
output "queue_url" {
  value = module.sqs_queue.queue_url
}
output "topic_arn" {
  value = aws_sns_topic.urgent_updates.arn
}
output "alarm_name" {
  value = module.metric_alarm.cloudwatch_metric_alarm_id
}
