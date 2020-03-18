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
    session_name = "EKS_deployment_session_${var.tags["Environment"]}"
  }

  version = "~> 2.53.0"
  region  = var.region
}
