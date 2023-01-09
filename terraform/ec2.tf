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
  multiple_instances = {
    k8s-master-1 = {
      instance_type     = "t3.small"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.private_subnets, 0)
      private_ip        = "10.0.1.10"
    }
    k8s-master-2 = {
      instance_type     = "t3.small"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.private_subnets, 0)
      private_ip        = "10.0.1.11"
    }
    k8s-worker-1 = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 1)
      subnet_id         = element(module.vpc.private_subnets, 1)
      private_ip        = "10.0.2.12"
    }
    k8s-worker-2 = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 1)
      subnet_id         = element(module.vpc.private_subnets, 1)
      private_ip        = "10.0.2.13"
    }
    k8s-ha-lb = {
      instance_type     = "t3.micro"
      availability_zone = element(module.vpc.azs, 0)
      subnet_id         = element(module.vpc.public_subnets, 0)
      private_ip        = "10.0.101.10"
    }
  }
}

module "ec2_k8s_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  for_each = local.multiple_instances

  name = each.key

  ami = "ami-0b93ce03dcbcb10f6" # ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20221212
  instance_type     = each.value.instance_type
  availability_zone = each.value.availability_zone
  subnet_id         = each.value.subnet_id
  private_ip        = each.value.private_ip
  key_name          = aws_key_pair.ssh_public_key.id
  user_data         = base64encode(templatefile(var.ssm_tunnel_instance_server, {}))

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

  name = "k8s-client"

  ami = "ami-0b93ce03dcbcb10f6" # ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20221212
  instance_type     = "t3.small"
  availability_zone = element(module.vpc.azs, 0)
  subnet_id         = element(module.vpc.private_subnets, 0)
  private_ip        = "10.0.1.9"
  key_name          = aws_key_pair.ssh_public_key.id
  user_data         = base64encode(templatefile(var.ssm_tunnel_instance_client, {}))

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