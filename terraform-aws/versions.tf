#####
# Backend and provider config
#####

terraform {
  required_version = ">= 0.13.1"

  backend "remote" {
    hostname = "app.terraform.io"
  }
}

provider "aws" {
  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "EKS_deployment_session_${var.tags["Environment"]}"
  }

  version = ">= 3.5"
  region  = var.region
}
