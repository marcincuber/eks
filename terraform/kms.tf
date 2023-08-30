module "eks_cluster" {
  source  = "native-cube/kms/aws"
  version = "~> 1.0.0"

  alias_name = var.name_prefix

  policy = data.aws_iam_policy_document.kms_policy_cluster.json
}
