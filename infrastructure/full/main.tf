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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  full_name = "${var.environment}-${var.application_name}-${basename(path.cwd)}"
  name      = substr(local.full_name, 0, 18)

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  spamcheck_port = 8000
  api_port       = 8080
  web_port       = 3000

  spamcheck_prefix = "/spam"
  api_prefix       = "/api"

  cpu    = 256
  memory = 512

  container_egress_rules = {
    egress_vpc_cidr = {
      type        = "egress"
      description = "Allow outbound traffic to VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [data.aws_ssm_parameter.vpc_cidr_block.value]
    }
    egress_s3_prefix_list = {
      type            = "egress"
      description     = "Allow outbound to S3 service endpoint"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      prefix_list_ids = [data.aws_ssm_parameter.s3_prefix_list_id.value]
    }
  }
}


module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${local.name}-service"
  description = "Service security group"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = [data.aws_ssm_parameter.vpc_cidr_block.value]

  tags = {
    Role = "alb-main"
  }
}

module "public_alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "${local.name}-public"

  load_balancer_type = "application"
  internal           = false

  vpc_id          = data.aws_ssm_parameter.vpc_id.value
  subnets         = split(",", data.aws_ssm_parameter.public_subnets.value)
  security_groups = [module.alb_sg.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-front"
      backend_protocol = "HTTP"
      backend_port     = local.web_port
      target_type      = "ip"
      health_check = {
        matcher = "200,301,302"
        path    = "/"
      }
    },
  ]

  tags = {
    Role = "alb-public"
  }
}

module "internal_alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "${local.name}-internal"

  load_balancer_type = "application"
  internal           = true

  vpc_id          = data.aws_ssm_parameter.vpc_id.value
  subnets         = split(",", data.aws_ssm_parameter.private_subnets.value)
  security_groups = [module.alb_sg.security_group_id]

  http_tcp_listeners = [
    {
      port     = 80
      protocol = "HTTP"
    },
  ]

  http_tcp_listener_rules = [
    {
      http_tcp_listener_index = 0
      priority                = 1000

      actions = [
        {
          type               = "forward"
          target_group_index = 0
        },
      ]

      conditions = [{
        path_patterns = ["${local.api_prefix}", "${local.api_prefix}/*"]
      }]
    },
    {
      http_tcp_listener_index = 0
      priority                = 2000

      actions = [
        {
          type               = "forward"
          target_group_index = 1
        },
      ]

      conditions = [{
        path_patterns = ["${local.spamcheck_prefix}", "${local.spamcheck_prefix}/*"]
      }]
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-comments-api"
      backend_protocol = "HTTP"
      backend_port     = local.api_port
      target_type      = "ip"
      health_check = {
        matcher = "200,301,302"
        path    = "${local.api_prefix}/health"
      }
    },
    {
      name             = "${local.name}-spam-check"
      backend_protocol = "HTTP"
      backend_port     = local.spamcheck_port
      target_type      = "ip"
      health_check = {
        matcher = "200,301,302"
        path    = "${local.spamcheck_prefix}/health"
      }
    },
  ]

  tags = {
    Role = "alb-internal"
  }
}

module "app_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = "${local.name}-cluster"
}

module "comments_api_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "comments-api-service"
  cluster_arn = module.app_cluster.arn

  cpu         = local.cpu
  memory      = local.memory
  launch_type = "FARGATE"
  subnet_ids  = split(",", data.aws_ssm_parameter.private_subnets.value)

  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3
  autoscaling_policies = {
    "requests" : {
      "policy_type" : "TargetTrackingScaling"
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ALBRequestCountPerTarget"
          "resource_label" : "${module.internal_alb.lb_arn_suffix}/${module.internal_alb.target_group_arn_suffixes[0]}"
        },
        "target_value" : 6000
        "scale_in_cooldown" : 300
        "scale_out_cooldown" : 180
      }
    },
    "cpu" : {
      "policy_type" : "TargetTrackingScaling"
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageCPUUtilization"
        },
        "target_value" : 70
        "scale_in_cooldown" : 300
        "scale_out_cooldown" : 180
      }
    },
    "memory" : {
      "policy_type" : "TargetTrackingScaling"
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageMemoryUtilization"
        },
        "target_value" : 70
        "scale_in_cooldown" : 300
        "scale_out_cooldown" : 180
      }
    }
  }

  container_definitions = {
    comments_api = {
      cpu       = local.cpu
      memory    = local.memory
      essential = true
      image     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/middleservice:v1"
      port_mappings = [
        {
          containerPort = local.api_port
          hostPort      = local.api_port
          protocol      = "tcp"
        },
      ]
      environment = [
        { "name" : "BACK_URL", "value" : "http://${module.internal_alb.lb_dns_name}${local.spamcheck_prefix}" },
        { "name" : "SPRING_DATASOURCE_URL", "value" : data.aws_ssm_parameter.comments_db_connection_string.value },
        { "name" : "SPRING_DATASOURCE_USERNAME", "value" : data.aws_ssm_parameter.comments_db_username.value },
        { "name" : "SPRING_DATASOURCE_PASSWORD", "value" : data.aws_ssm_parameter.comments_db_password.value },
        { "name" : "APPLICATION_PATH_BASE", "value" : local.api_prefix },
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.internal_alb.target_group_arns, 0)
      container_name   = "comments_api"
      container_port   = local.api_port
    }
  }

  security_group_rules = merge(
    {
      alb_ingress_8080 = {
        type        = "ingress"
        description = "Allow from LB to service port"
        from_port   = local.api_port
        to_port     = local.api_port
        protocol    = "tcp"
        # Chaos :: Insecure practice should get discovered by alb/ecs-alb-insgress/experiment.yaml
        cidr_blocks = ["0.0.0.0/0"]
        #source_security_group_id = module.alb_sg.security_group_id
      }
    },
    local.container_egress_rules,
  )

  tasks_iam_role_statements = {
    exec_command = {
      actions = [
        "s3:*",
      ]
      effect    = "Allow"
      resources = ["*"]
    }
  }
}

module "spam_check_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "spam-check-service"
  cluster_arn = module.app_cluster.arn

  cpu         = local.cpu
  memory      = local.memory
  launch_type = "FARGATE"
  subnet_ids  = split(",", data.aws_ssm_parameter.private_subnets.value)

  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  container_definitions = {
    spamcheck_service = {
      cpu       = local.cpu
      memory    = local.memory
      essential = true
      image     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/backservice:v1"
      port_mappings = [
        {
          containerPort = local.spamcheck_port
          hostPort      = local.spamcheck_port
          protocol      = "tcp"
        },
      ]
      environment = [
        { "name" : "APPLICATION_PATH_BASE", "value" : local.spamcheck_prefix },
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.internal_alb.target_group_arns, 1)
      container_name   = "spamcheck_service"
      container_port   = local.spamcheck_port
    }
  }

  security_group_rules = merge(
    {
      alb_ingress_8000 = {
        type        = "ingress"
        description = "Allow from LB to service port"
        from_port   = local.spamcheck_port
        to_port     = local.spamcheck_port
        protocol    = "tcp"
        # Chaos :: Insecure practice should get discovered by alb/ecs-alb-insgress/experiment.yaml
        cidr_blocks = ["0.0.0.0/0"]
        #source_security_group_id = module.alb_sg.security_group_id
      }
    },
    local.container_egress_rules,
  )
}

module "web_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "web-service"
  cluster_arn = module.app_cluster.arn

  cpu         = local.cpu
  memory      = local.memory
  launch_type = "FARGATE"
  subnet_ids  = split(",", data.aws_ssm_parameter.private_subnets.value)

  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  container_definitions = {
    web_service = {
      cpu       = local.cpu
      memory    = local.memory
      essential = true
      image     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/frontservice:v1"
      port_mappings = [
        {
          containerPort = local.web_port
          hostPort      = local.web_port
          protocol      = "tcp"
        },
      ]
      environment = [
        { "name" : "MIDDLE_URL", "value" : "http://${module.internal_alb.lb_dns_name}${local.api_prefix}" },
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.public_alb.target_group_arns, 0)
      container_name   = "web_service"
      container_port   = local.web_port
    }
  }

  security_group_rules = merge(
    {
      alb_ingress_3000 = {
        type        = "ingress"
        description = "Allow from LB to service port"
        from_port   = local.web_port
        to_port     = local.web_port
        protocol    = "tcp"
        # Chaos :: Insecure practice should get discovered by alb/ecs-alb-insgress/experiment.yaml
        cidr_blocks = ["0.0.0.0/0"]
        #source_security_group_id = module.alb_sg.security_group_id
      }
    },
    local.container_egress_rules,
  )
}
