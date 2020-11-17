#####
# Backend and provider config
#####
terraform {
  required_version = ">= 0.13.5"

  backend "remote" {
    hostname = "app.terraform.io"
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.5"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 2.2"
    }
  }
}

provider "aws" {
  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "EKS_deployment_session_${var.tags["Environment"]}"
  }
  
  region = var.region
}
