data "aws_iam_policy_document" "ssm_management" {
  statement {
    sid = "ssm"

    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:SendCommand",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "ssmmessages"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "ec2messages"
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_key_pair" "ssh_public_key" {
  key_name   = "admin-public-key"
  public_key = var.ssh_public_key
}

resource "aws_iam_policy" "k8s_ssm_policy" {
  name        = "test_policy"
  path        = "/"
  description = "ec2-k8s IAM policy"
  policy      = data.aws_iam_policy_document.ssm_management.json
}

locals {
  server_instances = {
    k8s-master-1 = {
      instance_type     = "t3.small"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.private_subnets, 0)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 0), 10)
    }
    k8s-master-2 = {
      instance_type     = "t3.small"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.private_subnets, 0)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 0), 11)
    }
    k8s-worker-1 = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 1)
      subnet_id         = element(module.vpc.private_subnets, 1)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 1), 12)
    }
    k8s-worker-2 = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 1)
      subnet_id         = element(module.vpc.private_subnets, 1)
      private_ip        = cidrhost(element(module.vpc.private_subnets_cidr_blocks, 1), 13)
    }
    k8s-ha-lb = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.public_subnets, 0)
      private_ip        = cidrhost(element(module.vpc.public_subnets_cidr_blocks, 0), 10)
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
    }
  }
}

locals {
  cluster_hosts = keys(local.server_instances)
  cluster_ips   = [for k in keys(local.server_instances) : local.server_instances[k].private_ip]
  client_hosts  = keys(local.client_instances)
  client_ips    = [for k in keys(local.client_instances) : local.client_instances[k].private_ip]
}

module "ec2_k8s_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  for_each = local.server_instances

  name = each.key

  ami               = "ami-0b93ce03dcbcb10f6" # ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20221212
  instance_type     = each.value.instance_type
  availability_zone = each.value.availability_zone
  subnet_id         = each.value.subnet_id
  private_ip        = each.value.private_ip
  key_name          = aws_key_pair.ssh_public_key.id
  user_data = base64encode(templatefile(var.ssm_tunnel_instance_server,
  { cluster_hosts = local.cluster_hosts, cluster_ips = local.cluster_ips, aws_region = var.aws_region }))

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
    AmazonSSMManagement          = aws_iam_policy.k8s_ssm_policy.arn
  }

  tags = {
    ec2-type = "server"
  }
}

module "ec2_client" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  for_each = local.client_instances

  name = each.key

  ami               = "ami-0b93ce03dcbcb10f6" # ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20221212
  instance_type     = each.value.instance_type
  availability_zone = each.value.availability_zone
  subnet_id         = each.value.subnet_id
  private_ip        = each.value.private_ip
  key_name          = aws_key_pair.ssh_public_key.id
  user_data = base64encode(templatefile(var.ssm_tunnel_instance_client, {
    client_hosts = local.client_hosts, client_ips = local.client_ips,
  cluster_hosts = local.cluster_hosts, cluster_ips = local.cluster_ips, aws_region = var.aws_region }))
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
    AmazonSSMManagement          = aws_iam_policy.k8s_ssm_policy.arn
  }

  tags = {
    ec2-type = "client"
  }

  depends_on = [
    module.ec2_k8s_cluster
  ]
}