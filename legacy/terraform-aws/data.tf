data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
data "aws_partition" "current" {}

# Fetch latest ami_id for specified ${var.eks_version}
data "aws_ssm_parameter" "eks_optimized_ami_id" {
  name            = "/aws/service/eks/optimized-ami/${var.eks_version_latest_ami}/amazon-linux-2/recommended/image_id"
  with_decryption = true
}

data "tls_certificate" "cluster" {
  count = var.create_cluster ? 1 : 0

  url = aws_eks_cluster.cluster[0].identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "managed_workers_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.aws_partition == "china" ? ["ec2.amazonaws.com.cn"] : ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "worker_node_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.aws_partition == "china" ? ["ec2.amazonaws.com.cn"] : ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "karpenter_controller" {
  count = var.create_cluster ? 1 : 0

  statement {
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
      "ssm:GetParameter",
      "pricing:GetProducts"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]

    resources = [aws_iam_role.eks_node_karpenter[0].arn]
  }
}
