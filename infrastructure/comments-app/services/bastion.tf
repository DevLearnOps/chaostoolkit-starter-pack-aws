resource "aws_security_group" "bastion_secgroup" {
  count = var.bastion_key_pair_name == "" ? 0 : 1

  name        = "${local.name}-bastion-sg"
  description = "Autoscaling security group bastion"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
}

resource "aws_vpc_security_group_ingress_rule" "bastion_sg_ingress_default" {
  count = var.bastion_key_pair_name == "" ? 0 : 1

  security_group_id = aws_security_group.bastion_secgroup[0].id

  description = "Allow inbound SSH access"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "bastion_sg_egress_default" {
  count = var.bastion_key_pair_name == "" ? 0 : 1

  security_group_id = aws_security_group.bastion_secgroup[0].id

  description = "Allow outbound access within the VPC"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = data.aws_ssm_parameter.vpc_cidr_block.value
}

resource "aws_vpc_security_group_ingress_rule" "autoscaling_sg_ingress_ssh" {
  count = var.bastion_key_pair_name == "" ? 0 : 1

  security_group_id = module.app_cluster_ec2.autoscaling_security_group_id

  description                  = "Allow inbound SSH access from bastion instance"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion_secgroup[0].id
}

module "ec2_bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  count = var.bastion_key_pair_name == "" ? 0 : 1

  name = "${local.name}-bastion"

  instance_type               = "t3.micro"
  key_name                    = var.bastion_key_pair_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.bastion_secgroup[0].id]
  subnet_id                   = element(split(",", data.aws_ssm_parameter.public_subnets.value), 1)
  associate_public_ip_address = true
}
