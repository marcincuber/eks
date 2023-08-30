module "eks_cluster" {
  source  = "native-cube/kms/aws"
  version = "~> 1.0.0"

  alias_name = local.name_prefix_env

  policy = data.aws_iam_policy_document.kms_policy_cluster.json
}
