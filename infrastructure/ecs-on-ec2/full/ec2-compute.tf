locals {
  tags = {
    Name    = local.name
    Example = local.name
  }
}
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.name}-autoscaling-sg"
  description = "Autoscaling security group for ${var.application_name} app"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = [data.aws_ssm_parameter.vpc_cidr_block.value]
  egress_with_prefix_list_ids = [
    {
      description     = "Allow outbound to S3 service endpoint"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      prefix_list_ids = data.aws_ssm_parameter.s3_prefix_list_id.value
    },
  ]

}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.10.0"

  for_each = {
    ondemand = {
      instance_type              = "t3.medium"
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.name}-cluster
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF
      EOT
    }
  }

  name          = "${local.name}-autoscaling-${each.key}"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-autoscaling"
  iam_role_description        = "ECS role for ${local.name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = split(",", data.aws_ssm_parameter.private_subnets.value)
  health_check_type   = "EC2"

  # In choosing the max capacity keep in mind that every container that uses 'awsvpc' network mode
  # will attach a new ENI in the host system and that EC2 instances have a maximum allowed
  # number of network interfaces.
  # See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI
  min_size         = 2
  max_size         = 6
  desired_capacity = 2

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # required for managed_termination_protection
  protect_from_scale_in = true

  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy
}

module "app_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.0"

  cluster_name = "${local.name}-cluster"

  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    # On-demand instances
    ondemand = {
      auto_scaling_group_arn         = module.autoscaling["ondemand"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        # The target capacity utilisation between 1 and 100.
        # For example: to keep a spare capacity of 10% use a value of 90
        target_capacity = 100
      }

      default_capacity_provider_strategy = {
        weight = 1
        base   = 1
      }
    }
  }
}

