locals {
  sample_blog_port = 80
}

resource "null_resource" "sync_container" {
  count = var.deploy_sample_blog_application ? 1 : 0
  provisioner "local-exec" {
    command = <<EOF
    aws ecr get-login-password --region ${local.region} \
      | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${local.region}.amazonaws.com
    docker pull ${local.registry_prefix}/${var.application_name}-blog-sample:${var.application_version}
    EOF
  }
}

module "sample_blog_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.name}-blog-alb-sg"
  description = "Application load balancer security group for sample blog for ${var.application_name} app"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = [data.aws_ssm_parameter.vpc_cidr_block.value]
}

module "sample_blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"
  count   = var.deploy_sample_blog_application ? 1 : 0

  name = "${local.name}-sample-blog"

  load_balancer_type = "application"
  internal           = false

  vpc_id          = data.aws_ssm_parameter.vpc_id.value
  subnets         = split(",", data.aws_ssm_parameter.public_subnets.value)
  security_groups = [module.sample_blog_alb_security_group.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-sample-blog"
      backend_protocol = "HTTP"
      backend_port     = local.sample_blog_port
      target_type      = "ip"
      health_check = {
        matcher = "200,301,302"
        path    = "/"
      }
      deregistration_delay = local.tg_deregistration_delay
    },
  ]
}

module "sample_blog_cluster" {
  source       = "terraform-aws-modules/ecs/aws//modules/cluster"
  version      = "5.2.0"
  count        = var.deploy_sample_blog_application ? 1 : 0
  cluster_name = "${local.name}-sample-blog-cluster"
}

module "sample_blog_service" {
  source      = "terraform-aws-modules/ecs/aws//modules/service"
  version     = "5.2.0"
  count       = var.deploy_sample_blog_application ? 1 : 0
  name        = "${var.application_name}-sample-blog-service"
  cluster_arn = module.sample_blog_cluster[0].arn

  cpu         = local.cpu
  memory      = local.memory
  launch_type = "FARGATE"
  subnet_ids  = split(",", data.aws_ssm_parameter.private_subnets.value)

  force_delete = local.ecs_service_force_delete

  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 1

  container_definitions = {
    main = {
      name      = "${var.application_name}-sample-blog"
      cpu       = local.cpu
      memory    = local.memory
      essential = true
      image     = "${local.registry_prefix}/${var.application_name}-blog-sample:${var.application_version}"
      port_mappings = [
        {
          containerPort = local.sample_blog_port
          hostPort      = local.sample_blog_port
          protocol      = "tcp"
        },
      ]
      environment = [
        { "name" : "WEB_URL", "value" : "http://${module.public_alb.lb_dns_name}" },
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.sample_blog_alb[0].target_group_arns, 0)
      container_name   = "${var.application_name}-sample-blog"
      container_port   = local.sample_blog_port
    }
  }

  security_group_rules = merge(
    {
      alb_ingress_80 = {
        type                     = "ingress"
        description              = "Allow from LB to service port"
        from_port                = local.sample_blog_port
        to_port                  = local.sample_blog_port
        protocol                 = "tcp"
        source_security_group_id = module.sample_blog_alb_security_group.security_group_id
      }
    },
    local.container_egress_rules,
  )
}
