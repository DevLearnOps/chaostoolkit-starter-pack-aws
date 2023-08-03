locals {
  cluster_name = "${var.name}-cluster"
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_security_group" "default" {
  name        = "${var.name}-autoscaling-sg"
  description = "Autoscaling security group for ${var.name} autoscaling group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "default_secgroup_id" {
  security_group_id = aws_security_group.default.id

  for_each = var.sg_ingress_with_secgroup_id

  description                  = each.value.description
  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  referenced_security_group_id = each.value.referenced_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "default_cidr_blocks" {
  security_group_id = aws_security_group.default.id

  for_each = var.sg_egress_with_cidr_blocks

  description = each.value.description
  ip_protocol = each.value.ip_protocol
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  cidr_ipv4   = each.value.cidr_ipv4
}

resource "aws_vpc_security_group_egress_rule" "default_prefix_list_ids" {
  security_group_id = aws_security_group.default.id

  for_each = var.sg_egress_with_prefix_list_ids

  description    = each.value.description
  ip_protocol    = each.value.ip_protocol
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  prefix_list_id = each.value.prefix_list_id
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.10.0"

  for_each = {
    ondemand = {
      instance_type              = var.instance_type
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.cluster_name}
        ECS_LOGLEVEL=${var.log_level}
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(var.container_instance_tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF

        # make sure Systems Manager Agent is running on instance
        systemctl enable amazon-ssm-agent --now
      EOT
    }
  }

  name          = "${var.name}-autoscaling-${each.key}"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.instance_type

  security_groups                 = [aws_security_group.default.id]
  user_data                       = base64encode(each.value.user_data)
  key_name                        = var.key_name
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = "${var.name}-autoscaling"
  iam_role_description        = "ECS role for ${var.name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

    # The AmaxonSSMManagedInstanceCore policy is necessary to allow chaos experiments to run commands
    # into this instance and simulate faults
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = var.subnets
  health_check_type   = "EC2"

  # In choosing the max capacity keep in mind that every container that uses 'awsvpc' network mode
  # will attach a new ENI in the host system and that EC2 instances have a maximum allowed
  # number of network interfaces.
  # See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.min_size

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # required for managed_termination_protection
  protect_from_scale_in = true

  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy
}

module "cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.0"

  cluster_name = local.cluster_name

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
