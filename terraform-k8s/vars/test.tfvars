aws_role_arn = ""

cluster_name = "eks-test-eu"

flux_args_extra = {
  "registry-exclude-image" = "*"
}

git_url  = "git@gitlab.com:test-org/devops/eks-global-platform-preprod-system.git"
git_path = "system-test"
