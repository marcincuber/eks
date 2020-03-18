#####
# Backend and provider config
#####

terraform {
  required_version = "~> 0.12.23"

  backend "remote" {
    hostname = "app.terraform.io"
  }
}

provider "aws" {
  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "deployment_session"
  }

  version = "~> 2.53.0"
  region  = var.region
}

provider "kubernetes" {
  version = "~> 1.11.1"

  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
}

