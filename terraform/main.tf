#####
# EKS Cluster
#####
resource "aws_eks_cluster" "cluster" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_version

  enabled_cluster_log_types = var.eks_enabled_log_types

  vpc_config {
    subnet_ids              = data.aws_subnets.private.ids
    security_group_ids      = []
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
    public_access_cidrs     = var.eks_public_access_cidrs
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = module.kms_eks_cluster.key_arn
    }
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.eks_service_ipv4_cidr
  }
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.name_prefix}/cluster"
  retention_in_days = 7

  kms_key_id = module.kms_eks_cluster.key_arn
}

resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.cluster_role_assume_role_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
}
