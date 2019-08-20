#####
# Backend and provider config
#####

terraform {
  required_version = "~> 0.12.6"

  backend "remote" {
    hostname = "app.terraform.io"
  }
}

provider "aws" {
  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "EKS_deployment_session_${var.tags["Environment"]}"
  }

  version = "~> 2.24.0"
  region  = var.region
}

provider "kubernetes" {
  version = "~> 1.8.1"

  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
}
