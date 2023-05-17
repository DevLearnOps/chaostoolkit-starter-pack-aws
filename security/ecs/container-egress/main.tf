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

variable "target_service_secgroup" {
  type    = string
  default = ""
}

data "aws_ssm_parameter" "vpcid" {
  name = "/devlearnops/vpc-id"
}
data "aws_ssm_parameter" "private_subnets" {
  name = "/devlearnops/private-subnet-ids"
}
data "aws_ssm_parameter" "public_subnets" {
  name = "/devlearnops/public-subnet-ids"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  container_port = 8000
  cpu            = 256
  memory         = 512
  account_id     = data.aws_caller_identity.current.account_id
  region         = data.aws_region.current.name
}

resource "aws_ecs_cluster" "cluster" {
  name = "chaosprobe"
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name = "chaos-cloudwatch-log-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Effect = "Allow"
        Sid    = ""
        Resource = [
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "task_role" {
  name = "chaosprobe-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    aws_iam_policy.cloudwatch_policy.arn,
  ]
}

resource "aws_iam_role" "task_execution_role" {
  name = "chaosprobe-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.cloudwatch_policy.arn,
  ]
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "chaosprobe"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.cpu
  memory                   = local.memory
  container_definitions = jsonencode([
    {
      name      = "chaosprobe"
      image     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/devlearnops/chaosprobe"
      cpu       = local.cpu
      memory    = local.memory
      essential = true
      portMappings = [
        {
          containerPort = local.container_port
          hostPort      = local.container_port
        }
      ]
    }
  ])
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.task_execution_role.arn
}

resource "aws_security_group" "container_secgroup" {
  name        = "chaosprobe_secgroup"
  description = "Default security group for chaosprobe service"
  vpc_id      = data.aws_ssm_parameter.vpcid.value

  ingress {
    description      = "Ingress on container port"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all egress"
    from_port        = 1
    to_port          = 1
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_service" "service" {
  depends_on = [
    aws_lb_listener.alb_listener
  ]
  name                  = "chaosprobe_svc"
  wait_for_steady_state = false
  cluster               = aws_ecs_cluster.cluster.id
  task_definition       = aws_ecs_task_definition.task_definition.arn
  desired_count         = 1
  launch_type           = "FARGATE"

  network_configuration {
    assign_public_ip = false
    subnets          = split(",", data.aws_ssm_parameter.private_subnets.value)
    security_groups  = var.target_service_secgroup != "" ? [aws_security_group.container_secgroup.id, var.target_service_secgroup] : [aws_security_group.container_secgroup.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    container_name   = "chaosprobe"
    container_port   = 8000
  }
}

resource "aws_security_group" "alb_secgroup" {
  name        = "chaosprobe_alb_secgroup"
  description = "Security group for test load balancer"
  vpc_id      = data.aws_ssm_parameter.vpcid.value

  ingress {
    description      = "Ingress on container port"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all egress"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [
      aws_security_group.container_secgroup.id,
    ]
  }
}

resource "aws_lb" "alb" {
  name               = "chaosprobe-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_secgroup.id]
  subnets            = split(",", data.aws_ssm_parameter.public_subnets.value)
}

resource "aws_lb_target_group" "alb_tg" {
  name        = "chaosprobe-alb-tg"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_ssm_parameter.vpcid.value
}


resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

output "dns_name" {
  value = "http://${aws_lb.alb.dns_name}"
}
output "chaosprobe_cluster" {
  value = "chaosprobe"
}
output "chaosprobe_service" {
  value = "chaosprobe_svc"
}
