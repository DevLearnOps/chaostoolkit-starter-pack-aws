data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  max_vcpus  = 1
  memory     = 2048
}

resource "aws_security_group" "default" {
  name        = "${var.environment}-${var.program}-default-batch-secgroup"
  description = "Default security group for Batch Compute Environment"
  vpc_id      = var.vpc_id
}

###########################################################################
#  Journals Reporting S3 Bucket
###########################################################################
resource "aws_s3_bucket" "this" {
  bucket = "${local.account_id}-${var.environment}-ctk-journals"
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
  name               = "${var.environment}-${var.program}-batch-service-role"
  assume_role_policy = data.aws_iam_policy_document.service.json
}

resource "aws_iam_role_policy_attachment" "service" {
  role       = aws_iam_role.service.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "this" {
  compute_environment_name = "${var.environment}-${var.program}-compute-environment"

  compute_resources {
    type      = "FARGATE"
    max_vcpus = local.max_vcpus
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
  name               = "${var.environment}-${var.program}-batch-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution.json
}

resource "aws_iam_role_policy_attachment" "job_task_execution" {
  role       = aws_iam_role.job_task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "job" {
  name               = "${var.environment}-${var.program}-batch-job-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution.json
}

resource "aws_iam_role_policy" "job" {
  name = "${var.environment}-${var.program}-batch-job-role-policy"
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
          "iam:PassRole",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_batch_job_definition" "this" {
  name = "${var.environment}-${var.program}-batch-job-definition"
  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = jsonencode({
    image            = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/chaos-starter-aws:latest"
    jobRoleArn       = aws_iam_role.job.arn
    executionRoleArn = aws_iam_role.job_task_execution.arn

    environment = [
      { "name" : "JOURNALS_BUCKET", "value" : aws_s3_bucket.this.id },
    ]

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
        value = tostring(local.max_vcpus)
      },
      {
        type  = "MEMORY"
        value = tostring(local.memory)
      }
    ]

  })
}

###########################################################################
#  Job Queue
###########################################################################
resource "aws_batch_job_queue" "this" {
  name     = "${var.environment}-${var.program}-batch-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.this.arn,
  ]
}
