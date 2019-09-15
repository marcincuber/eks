resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.oidc_thumbprint_list
  url             = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

output "aws_iam_openid_connect_provider_arn" {
  value = aws_iam_openid_connect_provider.cluster.arn
}
