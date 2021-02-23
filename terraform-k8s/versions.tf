#####
# Backend and provider config
#####

terraform {
  required_version = ">= 0.14.5"

  backend "remote" {
    hostname = "app.terraform.io"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.28"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0.0"
    }
  }
}

provider "aws" {
  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "deployment_session"
  }

  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}
