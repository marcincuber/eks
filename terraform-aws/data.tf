data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Fetch latest ami_id for specified ${var.eks_version}
data "aws_ssm_parameter" "eks_optimized_ami_id" {
  name            = "/aws/service/eks/optimized-ami/${var.eks_version_latest_ami}/amazon-linux-2/recommended/image_id"
  with_decryption = true
}

data "tls_certificate" "cluster" {
  count = var.create_cluster ? 1 : 0

  url = aws_eks_cluster.cluster[0].identity.0.oidc.0.issuer
}

# Fetch OIDC provider thumbprint for root CA
data "external" "thumbprint" {
  program = ["./scripts/oidc-thumbprint.sh", data.aws_region.current.name]
}

# data "aws_eks_cluster_auth" "cluster_auth" {
#   name = aws_eks_cluster.cluster[0].id
# }
