aws_role_arn = "arn:aws:iam::541285974496:role/deploy-role"

cluster_name = "eks-prod-eu"

flux_args_extra = {
  "registry-exclude-image" = "*"
}

git_url  = "git@gitlab.com:umotif/devops/eks-global-platform-prod-system.git"
git_path = "system-prod-eu"
