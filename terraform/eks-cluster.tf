#####
# EKS Cluster
#####
resource "aws_eks_cluster" "cluster" {
  name = var.name_prefix

  version  = var.eks_version
  role_arn = aws_iam_role.cluster.arn

  enabled_cluster_log_types = var.eks_enabled_log_types

  vpc_config {
    subnet_ids              = module.vpc_eks.private_subnets
    security_group_ids      = var.eks_security_group_ids
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_public_access_cidrs
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = module.eks_cluster.key_arn
    }
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.eks_service_ipv4_cidr
  }

  zonal_shift_config {
    enabled = true
  }
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.name_prefix}/cluster"
  retention_in_days = 7

  kms_key_id = module.eks_cluster.key_arn
}

resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.cluster_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachments_exclusive" "cluster" {
  role_name = aws_iam_role.cluster.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
}

#####
# Outputs
#####
output "eks_id" {
  value       = aws_eks_cluster.cluster.id
  description = "EKS cluster name."
}

output "eks_arn" {
  value       = aws_eks_cluster.cluster.arn
  description = "EKS cluster ARN."
}

output "eks_network_config" {
  value       = aws_eks_cluster.cluster.kubernetes_network_config
  description = "EKS cluster network configuration."
}
