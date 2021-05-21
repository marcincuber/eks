resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.create_cluster ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.cluster[0].certificates.0.sha1_fingerprint], var.oidc_thumbprint_list)
  url             = aws_eks_cluster.cluster[0].identity.0.oidc.0.issuer
  
  tags = var.tags
}

output "aws_iam_openid_connect_provider_arn" {
  value = join("", aws_iam_openid_connect_provider.cluster.*.arn)
}
