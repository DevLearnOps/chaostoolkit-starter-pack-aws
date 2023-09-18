provider "aws" {
  default_tags {
    tags = merge(
      {
        Environment = var.environment
        Program     = var.program
        Application = var.application_name
      },
      var.tags,
    )
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = substr(
    "${var.environment}-${var.program}-${var.application_name}-${basename(path.cwd)}", 0, 18
  )

  account_id      = data.aws_caller_identity.current.account_id
  region          = data.aws_region.current.name
  registry_prefix = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/ecr-public/devlearnops"

  # Allow ECS services to be removed without waiting for scaling down to 0
  ecs_service_force_delete = true
  tg_deregistration_delay  = 30

  cpu         = var.generic_service_cpu_units
  memory      = var.generic_service_memory
  java_cpu    = var.java_service_cpu_units
  java_memory = var.java_service_memory

  web_port       = 3000
  api_port       = 8080
  spamcheck_port = 8000

  spamcheck_prefix = "/spam"
  api_prefix       = "/api"

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

resource "null_resource" "sync_containers" {
  provisioner "local-exec" {
    command = <<EOF
    aws ecr get-login-password --region ${local.region} \
      | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${local.region}.amazonaws.com
    docker pull ${local.registry_prefix}/${var.application_name}-spamcheck:${var.application_version}
    docker pull ${local.registry_prefix}/${var.application_name}-web:${var.application_version}
    docker pull ${local.registry_prefix}/${var.application_name}-api:${var.application_version}
    docker pull ${local.registry_prefix}/ecs-container-hog:latest
    EOF
  }
}

module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.name}-alb-sg"
  description = "Application load balancer security group for ${var.application_name} app"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = [data.aws_ssm_parameter.vpc_cidr_block.value]
}

module "public_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = "${local.name}-public"

  load_balancer_type = "application"
  internal           = false

  vpc_id          = data.aws_ssm_parameter.vpc_id.value
  subnets         = split(",", data.aws_ssm_parameter.public_subnets.value)
  security_groups = [module.alb_security_group.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-web"
      backend_protocol = "HTTP"
      backend_port     = local.web_port
      target_type      = "ip"
      health_check = {
        matcher = "200,301,302"
        path    = "/"
      }
      deregistration_delay = local.tg_deregistration_delay
    },
  ]
}

module "internal_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = "${local.name}-internal"

  load_balancer_type = "application"
  internal           = true

  vpc_id          = data.aws_ssm_parameter.vpc_id.value
  subnets         = split(",", data.aws_ssm_parameter.private_subnets.value)
  security_groups = [module.alb_security_group.security_group_id]

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
      name             = "${local.name}-api"
      backend_protocol = "HTTP"
      backend_port     = local.api_port
      target_type      = "ip"
      health_check = {
        matcher = "200,301,302"
        path    = "${local.api_prefix}/health"
      }
      deregistration_delay = local.tg_deregistration_delay
    },
    {
      name             = "${local.name}-spamcheck"
      backend_protocol = "HTTP"
      backend_port     = local.spamcheck_port
      target_type      = "ip"
      health_check = {
        matcher = "200,301,302"
        path    = "${local.spamcheck_prefix}/health"
      }
      deregistration_delay = local.tg_deregistration_delay
    },
  ]
}

module "app_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.0"

  cluster_name = "${local.name}-cluster"
}

module "app_cluster_ec2" {
  source = "../..//submodules/ecs-cluster-ec2-provider"

  name    = "${local.name}-ec2"
  vpc_id  = data.aws_ssm_parameter.vpc_id.value
  subnets = split(",", data.aws_ssm_parameter.private_subnets.value)

  instance_type = "t3.small"
  min_size      = 2
  max_size      = 5
  log_level     = "debug"

  key_name = var.bastion_key_pair_name

  sg_ingress_with_secgroup_id = {
    rule1 = {
      description                  = "Allow SSH access from bastion instance"
      ip_protocol                  = "tcp"
      from_port                    = 22
      to_port                      = 22
      referenced_security_group_id = data.aws_ssm_parameter.nat_bastion_secgroup_id.value
    },
  }

  sg_egress_with_prefix_list_ids = {
    rule1 = {
      description    = "Allow outbound access to S3"
      ip_protocol    = "tcp"
      from_port      = 443
      to_port        = 443
      prefix_list_id = data.aws_ssm_parameter.s3_prefix_list_id.value
    },
  }

  sg_egress_with_cidr_blocks = {
    rule1 = {
      description = "Allow outbound access within the VPC"
      ip_protocol = "tcp"
      from_port   = 0
      to_port     = 65535

      # Allow egress to the internet to install software packages
      cidr_ipv4 = "0.0.0.0/0"
      #cidr_ipv4   = data.aws_ssm_parameter.vpc_cidr_block.value
    },
  }
}

module "api_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.0"

  name        = "${var.application_name}-api-service"
  cluster_arn = module.app_cluster.arn

  cpu         = local.java_cpu
  memory      = local.java_memory
  launch_type = "FARGATE"
  subnet_ids  = split(",", data.aws_ssm_parameter.private_subnets.value)

  force_delete = local.ecs_service_force_delete

  desired_count            = var.autoscaling_min_capacity
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
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
    main = {
      name      = "${local.name}-api"
      cpu       = local.java_cpu
      memory    = local.java_memory
      essential = true
      image     = "${local.registry_prefix}/${var.application_name}-api:${var.application_version}"
      port_mappings = [
        {
          containerPort = local.api_port
          hostPort      = local.api_port
          protocol      = "tcp"
        },
      ]
      environment = [
        { "name" : "SPRING_DATASOURCE_URL", "value" : data.aws_ssm_parameter.application_db_connection_string.value },
        { "name" : "SPRING_DATASOURCE_USERNAME", "value" : data.aws_ssm_parameter.application_db_username.value },
        { "name" : "SPRING_DATASOURCE_PASSWORD", "value" : data.aws_ssm_parameter.application_db_password.value },
        { "name" : "APPLICATION_PATH_BASE", "value" : local.api_prefix },
        { "name" : "APPLICATION_SPAMCHECK_URL", "value" : "http://${module.internal_alb.lb_dns_name}${local.spamcheck_prefix}" },
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.internal_alb.target_group_arns, 0)
      container_name   = "${local.name}-api"
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
        #source_security_group_id = module.alb_security_group.security_group_id
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

###########################################################################
#  Models bucket for spamcheck application
###########################################################################
resource "aws_s3_bucket" "models_buket" {
  bucket        = "${local.account_id}-${local.name}-spamcheck-models"
  force_destroy = true
}

resource "aws_s3_bucket_object" "model_objects" {
  for_each = fileset("../../resources/models/", "*.pkl")

  bucket = aws_s3_bucket.models_bucket.id
  key    = each.key
  source = each.key
}

module "spamcheck_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.0"

  depends_on = [
    module.app_cluster_ec2,
  ]

  name        = "${var.application_name}-spamcheck-service"
  cluster_arn = module.app_cluster_ec2.cluster_arn

  cpu        = local.cpu
  memory     = local.memory
  subnet_ids = split(",", data.aws_ssm_parameter.private_subnets.value)

  force_delete = local.ecs_service_force_delete

  requires_compatibilities = ["EC2"]
  capacity_provider_strategy = {
    ondemand = {
      capacity_provider = module.app_cluster_ec2.autoscaling_capacity_providers["ondemand"].name
      weight            = 1
      base              = 1
    }
  }

  desired_count            = var.autoscaling_min_capacity
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  container_definitions = {
    main = {
      name      = "${var.application_name}-spamcheck"
      cpu       = local.cpu
      memory    = local.memory
      essential = true
      image     = "${local.registry_prefix}/${var.application_name}-spamcheck:${var.application_version}"
      port_mappings = [
        {
          containerPort = local.spamcheck_port
          hostPort      = local.spamcheck_port
          protocol      = "tcp"
        },
      ]
      environment = [
        { "name" : "APPLICATION_PATH_BASE", "value" : local.spamcheck_prefix },
        { "name" : "MODELS_LOCATION", "value" : "/app/models/" },
        { "name" : "MODELS_SOURCE_LOCATION_S3", "value" : "s3://${aws_s3_bucket.models_bucket.id}" },
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.internal_alb.target_group_arns, 1)
      container_name   = "${var.application_name}-spamcheck"
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
        #source_security_group_id = module.alb_security_group.security_group_id
      }
    },
    local.container_egress_rules,
  )
}

module "web_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.0"

  name        = "${var.application_name}-web-service"
  cluster_arn = module.app_cluster.arn

  cpu         = local.cpu
  memory      = local.memory
  launch_type = "FARGATE"
  subnet_ids  = split(",", data.aws_ssm_parameter.private_subnets.value)

  force_delete = local.ecs_service_force_delete

  desired_count            = var.autoscaling_min_capacity
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  container_definitions = {
    main = {
      name      = "${var.application_name}-web"
      cpu       = local.cpu
      memory    = local.memory
      essential = true
      image     = "${local.registry_prefix}/${var.application_name}-web:${var.application_version}"
      port_mappings = [
        {
          containerPort = local.web_port
          hostPort      = local.web_port
          protocol      = "tcp"
        },
      ]
      environment = [
        { "name" : "API_URL", "value" : "http://${module.internal_alb.lb_dns_name}${local.api_prefix}" },
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.public_alb.target_group_arns, 0)
      container_name   = "${var.application_name}-web"
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
        #source_security_group_id = module.alb_security_group.security_group_id
      }
    },
    local.container_egress_rules,
  )
}
