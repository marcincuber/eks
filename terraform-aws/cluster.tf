#####
# EKS Control Plane security group
#####

resource "aws_security_group_rule" "vpc_endpoint_eks_cluster_sg" {
  count = var.enable_managed_workers && var.create_cluster ? 1 : 0

  description              = "Allow EKS Security Group to communicate through vpc endpoints."
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoint.id
  source_security_group_id = aws_eks_cluster.cluster[0].vpc_config.0.cluster_security_group_id
  to_port                  = 443
  type                     = "ingress"

  depends_on = [aws_eks_cluster.cluster]
}

#####
# EKS Cluster
#####
module "kms-eks" {
  source  = "native-cube/kms/aws"
  version = "~> 1.0.0"

  alias_name = local.name_prefix

  tags = var.tags
}

resource "aws_eks_cluster" "cluster" {
  count = var.create_cluster ? 1 : 0

  enabled_cluster_log_types = var.eks_enabled_log_types
  name                      = local.name_prefix
  role_arn                  = aws_iam_role.cluster.arn
  version                   = var.eks_version

  vpc_config {
    subnet_ids              = flatten([module.vpc.public_subnets, module.vpc.private_subnets])
    security_group_ids      = []
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = module.kms-eks.key_arn
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
    aws_cloudwatch_log_group.cluster
  ]
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.name_prefix}/cluster"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEKSClusterPolicy" : "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEKSServicePolicy" : "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEKSVPCResourceController" : "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

#####
# Outputs
#####

output "eks_cluster_security_group_id" {
  value = join("", aws_eks_cluster.cluster.*.vpc_config.0.cluster_security_group_id)
}

output "eks_cluster_name" {
  value = join("", aws_eks_cluster.cluster.*.id)
}

output "eks_cluster_endpoint" {
  value = join("", aws_eks_cluster.cluster.*.endpoint)
}

output "eks_cluster_platform_version" {
  value = join("", aws_eks_cluster.cluster.*.platform_version)
}

output "eks_cluster_kubernetes_version" {
  value = join("", aws_eks_cluster.cluster.*.version)
}

output "eks_cluster_vpc_config" {
  value = join("", aws_eks_cluster.cluster.*.vpc_config.0.vpc_id)
}

output "cluster_role_arn" {
  value = join("", aws_iam_role.cluster.*.arn)
}
