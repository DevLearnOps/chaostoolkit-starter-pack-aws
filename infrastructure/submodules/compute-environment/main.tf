data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

data "aws_sns_topic" "notification" {
  count = length(var.sns_notification_topic_name) > 0 ? 1 : 0
  name  = var.sns_notification_topic_name
}

resource "aws_security_group" "default" {
  name        = "${var.name}-default-batch-secgroup"
  description = "Default security group for Batch Compute Environment"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "default" {
  security_group_id = aws_security_group.default.id

  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
}

###########################################################################
#  Journals Reporting S3 Bucket
###########################################################################
resource "aws_s3_bucket" "this" {
  count         = var.journals_bucket == "" ? 1 : 0
  bucket        = "${local.account_id}-${var.name}-ctk-journals"
  force_destroy = true
}

###########################################################################
#  Compute Environment
###########################################################################
data "aws_iam_policy_document" "service" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "service" {
  name               = "${var.name}-batch-service-role"
  assume_role_policy = data.aws_iam_policy_document.service.json
}

resource "aws_iam_role_policy_attachment" "service" {
  role       = aws_iam_role.service.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "this" {
  compute_environment_name = "${var.name}-compute-environment"

  compute_resources {
    type      = "FARGATE"
    max_vcpus = var.max_vcpus
    security_group_ids = [
      aws_security_group.default.id
    ]
    subnets = var.subnets
  }

  state        = "ENABLED"
  service_role = aws_iam_role.service.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.service]
}

###########################################################################
#  Job Definition
###########################################################################
data "aws_iam_policy_document" "ecs_execution" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "job_task_execution" {
  name               = "${var.name}-batch-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution.json
}

resource "aws_iam_role_policy_attachment" "job_task_execution" {
  role       = aws_iam_role.job_task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "job" {
  name               = "${var.name}-batch-job-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution.json
}

resource "aws_iam_role_policy" "job" {
  name = "${var.name}-batch-job-role-policy"
  role = aws_iam_role.job.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
          "ec2:*",
          "ssm:*",
          "ecs:*",
          "cloudwatch:*",
          "dynamodb:*",
          "iam:PassRole",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_batch_job_definition" "this" {
  name = "${var.name}-batch-job-definition"
  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = jsonencode({
    image            = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/chaos-starter-aws:latest"
    jobRoleArn       = aws_iam_role.job.arn
    executionRoleArn = aws_iam_role.job_task_execution.arn

    environment = concat(
      [{ "name" : "CHAOS_JOURNALS_BUCKET", "value" : var.journals_bucket == "" ? aws_s3_bucket.this[0].id : var.journals_bucket }],
      [for item in data.aws_sns_topic.notification : { "name" : "FAILED_EXPERIMENT_TOPIC_ARN", "value" : item.arn }],
      [for item in var.job_definition_environment : { "name" : item.name, "value" : item.value }],
    )

    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    logConfiguration = {
      logDriver = "awslogs",
    }

    resourceRequirements = [
      {
        type  = "VCPU"
        value = tostring(var.max_vcpus)
      },
      {
        type  = "MEMORY"
        value = tostring(var.task_memory)
      }
    ]

  })
}

###########################################################################
#  Job Queue
###########################################################################
resource "aws_batch_job_queue" "this" {
  name     = "${var.name}-batch-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.this.arn,
  ]
}
