data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  # Ubuntu AMI ID search
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "k8s_ssm_commands" {
  statement {
    actions = [
      "ssm:SendCommand",
    ]

    resources = ["*"]
  }
}

resource "aws_key_pair" "ssh_public_key" {
  key_name   = "admin-public-key"
  public_key = var.ssh_public_key
}

resource "aws_iam_policy" "k8s_ssm_commands" {
  name        = "SendSSMCommands"
  path        = "/"
  description = "SSM Send command IAM policy"
  policy      = data.aws_iam_policy_document.k8s_ssm_commands.json
}

locals {
  server_instances = {
    k8s-master-1 = {
      instance_type     = "t3.small"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.private_subnets, 0)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 0), 10)
      security_group_id = aws_security_group.k8s_control_plane.id
    }
    k8s-master-2 = {
      instance_type     = "t3.small"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.private_subnets, 0)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 0), 11)
      security_group_id = aws_security_group.k8s_control_plane.id
    }
    k8s-worker-1 = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 1)
      subnet_id         = element(module.vpc.private_subnets, 1)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 1), 12)
      security_group_id = aws_security_group.k8s_data_plane.id
    }
    k8s-worker-2 = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 1)
      subnet_id         = element(module.vpc.private_subnets, 1)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 1), 13)
      security_group_id = aws_security_group.k8s_data_plane.id
    }
    k8s-ha-lb = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.public_subnets, 0)
      private_ip        = cidrhost(element(module.vpc.public_subnets_cidr_blocks, 0), 10)
      public_ip         = true
      security_group_id = aws_security_group.k8s_load_balancer.id
    }
  }
}

locals {
  client_instances = {
    k8s-client = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.private_subnets, 0)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 0), 9)
      security_group_id = aws_security_group.k8s_data_plane.id
    }
  }
}

locals {
  ssm_tunnel_instance_server = var.kubeadm_on ? var.ssm_tunnel_instance_server_kubeadm : var.ssm_tunnel_instance_server
  cluster_hosts              = keys(local.server_instances)
  cluster_ips                = [for k in keys(local.server_instances) : local.server_instances[k].private_ip]
  client_hosts               = keys(local.client_instances)
  client_ips                 = [for k in keys(local.client_instances) : local.client_instances[k].private_ip]
}

module "ec2_k8s_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.2"

  for_each = local.server_instances

  name = each.key

  ami               = data.aws_ami.ubuntu.id
  instance_type     = each.value.instance_type
  availability_zone = each.value.availability_zone

  subnet_id                   = each.value.subnet_id
  private_ip                  = each.value.private_ip
  associate_public_ip_address = try(each.value.public_ip, false)

  create_security_group  = false
  vpc_security_group_ids = [each.value.security_group_id]

  key_name = aws_key_pair.ssh_public_key.id
  user_data = templatefile(local.ssm_tunnel_instance_server,
  { cluster_hosts = local.cluster_hosts, cluster_ips = local.cluster_ips, aws_region = var.aws_region })

  enable_volume_tags = false

  create_iam_instance_profile = true
  iam_role_name               = "ec2-k8s-asg-iam-role"
  iam_role_description        = "ec2-k8s IAM role"
  iam_role_path               = "/ec2/"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonSSMCommands            = aws_iam_policy.k8s_ssm_commands.arn
  }

  tags = {
    ec2-type = "server"
  }
}

module "ec2_client" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.2"

  for_each = local.client_instances

  name = each.key

  ami               = data.aws_ami.ubuntu.id
  instance_type     = each.value.instance_type
  availability_zone = each.value.availability_zone
  subnet_id         = each.value.subnet_id
  private_ip        = each.value.private_ip

  create_security_group  = false
  vpc_security_group_ids = [each.value.security_group_id]

  key_name = aws_key_pair.ssh_public_key.id
  user_data = templatefile(var.ssm_tunnel_instance_client, {
    client_hosts = local.client_hosts, client_ips = local.client_ips,
  cluster_hosts = local.cluster_hosts, cluster_ips = local.cluster_ips, aws_region = var.aws_region })

  enable_volume_tags = false

  create_iam_instance_profile = true
  iam_role_name               = "ec2-k8s-asg-iam-role"
  iam_role_description        = "ec2-k8s IAM role"
  iam_role_path               = "/ec2/"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonSSMCommands            = aws_iam_policy.k8s_ssm_commands.arn
  }

  tags = {
    ec2-type = "client"
  }

  depends_on = [
    module.ec2_k8s_cluster
  ]
}