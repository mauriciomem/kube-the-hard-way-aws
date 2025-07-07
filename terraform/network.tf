
data "external" "my_local_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "ec2-k8s-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group = false

  tags = {
    type = "network"
  }
}

### Security Groups

resource "aws_security_group" "k8s_control_plane" {
  name        = "k8s-control-plane"
  description = "Kubernetes Control Plane SG"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group" "k8s_data_plane" {
  name        = "k8s-data-plane"
  description = "Kubernetes Data Plane SG"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group" "k8s_load_balancer" {
  name        = "k8s-ha-lb"
  description = "Security group for Kubernetes HA Load Balancer"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "public_access_from_my_ip" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.my_local_ip.result.ip}/32"]
  security_group_id = aws_security_group.k8s_load_balancer.id
  description       = "Allow public access to the Kubernetes API server from my local IP"
}

resource "aws_security_group_rule" "k8s_control_plane_access_ingress" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = concat(module.vpc.private_subnets_cidr_blocks, module.vpc.public_subnets_cidr_blocks)
  security_group_id = aws_security_group.k8s_control_plane.id
  description       = "Allow access to the Kubernetes control plane from private subnets"
}

resource "aws_security_group_rule" "k8s_control_plane_access_egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_control_plane.id
  description       = "Allow egress from the Kubernetes control plane to all destinations"
}

resource "aws_security_group_rule" "k8s_data_plane_access_ingress" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = concat(module.vpc.private_subnets_cidr_blocks, module.vpc.public_subnets_cidr_blocks)
  security_group_id = aws_security_group.k8s_data_plane.id
  description       = "Allow access to the Kubernetes data plane from private subnets"
}

resource "aws_security_group_rule" "k8s_data_plane_access_egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_data_plane.id
  description       = "Allow access to the Kubernetes data plane from private subnets"
}

resource "aws_security_group_rule" "lb_api_server_access_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = concat(module.vpc.public_subnets_cidr_blocks, module.vpc.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.k8s_load_balancer.id
  description       = "Allow access to the Kubernetes API server from public and private subnets"
}

resource "aws_security_group_rule" "lb_api_server_access_egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_load_balancer.id
  description       = "Allow egress from the Kubernetes HA Load Balancer to all destinations"
}