resource "aws_security_group" "nat_bastion_secgroup" {
  name        = "${local.name}-nat-bastion-sg"
  description = "NAT bastion security group"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "nat_bastion_sg_egress_http" {
  security_group_id = aws_security_group.nat_bastion_secgroup.id

  description = "Allow outbound HTTP access"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "nat_bastion_sg_egress_https" {
  security_group_id = aws_security_group.nat_bastion_secgroup.id

  description = "Allow outbound HTTPS access"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "nat_bastion_sg_ingress_http" {
  security_group_id = aws_security_group.nat_bastion_secgroup.id

  description = "Allow outbound HTTP access"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = module.vpc.vpc_cidr_block
}
resource "aws_vpc_security_group_ingress_rule" "nat_bastion_sg_ingress_https" {
  security_group_id = aws_security_group.nat_bastion_secgroup.id

  description = "Allow outbound HTTPS access"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = module.vpc.vpc_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "nat_bastion_sg_ingress_ssh" {
  count = var.bastion_key_pair_name == "" ? 0 : 1

  security_group_id = aws_security_group.nat_bastion_secgroup.id

  description = "Allow inbound SSH access"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "nat_bastion_sg_egress_default" {
  count = var.bastion_key_pair_name == "" ? 0 : 1

  security_group_id = aws_security_group.nat_bastion_secgroup.id

  description = "Allow outbound access within the VPC"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = module.vpc.vpc_cidr_block
}

locals {
  nat_user_data = <<-EOT
  #!/bin/bash
  yum install -y iptables-services
  sysctl -w net.ipv4.ip_forward=1; sysctl -p
  /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  service iptables save
  systemctl enable iptables --now
  EOT
}

module "ec2_nat_bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  name = "${local.name}-nat-bastion"

  instance_type               = "t3.micro"
  key_name                    = var.bastion_key_pair_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.nat_bastion_secgroup.id]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true

  # Disable source destination check for instance to act as a NAT
  source_dest_check = false

  user_data = base64encode(local.nat_user_data)
}

resource "aws_route" "nat_route" {
  depends_on = [
    module.vpc,
    module.ec2_nat_bastion,
  ]

  for_each = toset(module.vpc.private_route_table_ids)

  route_table_id         = each.key
  network_interface_id   = module.ec2_nat_bastion.primary_network_interface_id
  destination_cidr_block = "0.0.0.0/0"
}
