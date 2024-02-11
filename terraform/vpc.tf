
data "external" "my_local_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "ec2-k8s-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    type = "network"
  }
}

# resource "aws_security_group_rule" "public_access_from_my_ip" {
#  type              = "ingress"
#  from_port         = 6443
#  to_port           = 6443
#  protocol          = "tcp"
#  cidr_blocks       = ["${data.external.my_local_ip.result.ip}/32"]
#  security_group_id = module.vpc.default_security_group_id
# }