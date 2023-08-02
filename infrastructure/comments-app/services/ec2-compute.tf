locals {
  tags = {
    Name    = local.name
    Example = local.name
  }
  ec2_cluster_instance_type = "t3.small"
  ec2_cluster_min_size      = 2
  ec2_cluster_max_size      = 5
  ec2_cluster_name          = "${local.name}-cluster-ec2"
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_security_group" "autoscaling_secgroup" {
  name        = "${local.name}-autoscaling-sg"
  description = "Autoscaling security group for ${var.application_name} app"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
}

resource "aws_vpc_security_group_egress_rule" "autoscaling_sg_egress_default" {
  security_group_id = aws_security_group.autoscaling_secgroup.id

  description = "Allow outbound access within the VPC"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = data.aws_ssm_parameter.vpc_cidr_block.value
}

resource "aws_vpc_security_group_egress_rule" "autoscaling_sg_egress_s3" {
  security_group_id = aws_security_group.autoscaling_secgroup.id

  description    = "Allow outbound to S3 service endpoint"
  ip_protocol    = "tcp"
  from_port      = 443
  to_port        = 443
  prefix_list_id = data.aws_ssm_parameter.s3_prefix_list_id.value
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.10.0"

  for_each = {
    ondemand = {
      instance_type              = local.ec2_cluster_instance_type
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.ec2_cluster_name}
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

  security_groups                 = [aws_security_group.autoscaling_secgroup.id]
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
  min_size         = local.ec2_cluster_min_size
  max_size         = local.ec2_cluster_max_size
  desired_capacity = local.ec2_cluster_min_size

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # required for managed_termination_protection
  protect_from_scale_in = true

  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy
}

module "app_cluster_ec2" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.0"

  cluster_name = local.ec2_cluster_name

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

