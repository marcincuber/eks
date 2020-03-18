aws_role_arn = "arn:aws:iam::423793869191:role/deploy-role"

cluster_name = "eks-dev-eu"

flux_args_extra = {
  "registry-exclude-image" = "*"
}

git_url  = "git@gitlab.com:umotif/devops/eks-global-platform-preprod-system.git"
git_path = "system-dev-eu"
