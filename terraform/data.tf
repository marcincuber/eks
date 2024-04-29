data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# Fetch latest ami_id for specified ${var.eks_version}
data "aws_ssm_parameter" "eks_optimized_ami_id" {
  name            = "/aws/service/eks/optimized-ami/${var.eks_version}/amazon-linux-2/recommended/image_id"
  with_decryption = true
}

data "aws_ssm_parameter" "eks_al2023" {
  name            = "/aws/service/eks/optimized-ami/${var.eks_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
  with_decryption = true
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "cluster_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_group_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_custom_inline_policy" {
  statement {
    actions = [
      "ecr:CreateRepository",
      "ecr:ReplicateImage",
      "ecr:BatchImportUpstreamImage"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kms_policy_cluster" {
  statement {
    actions = [
      "kms:*"
    ]

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.${data.aws_partition.current.dns_suffix}"]
    }
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:RetireGrant"
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["events.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "aws_iam_policy_document" "karpenter_spot_interruption" {
  statement {
    actions = [
      "sqs:SendMessage"
    ]

    resources = [aws_sqs_queue.karpenter_spot_interruption.arn]

    principals {
      type = "Service"
      identifiers = [
        "events.${data.aws_partition.current.dns_suffix}",
        "sqs.${data.aws_partition.current.dns_suffix}"
      ]
    }
  }
}
