terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }

  cloud {
    organization = "dare-preprod"

    workspaces {
      name = "tf-eng-infra-dev-aws-eks-infra"
    }
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Environment = "dev"
      Team        = "Cloud Native Platform CNP"
      Repository  = "https://github.com/dare-global/tf-eng-infra-dev/aws/eks-infra"
      Service     = "eks"
    }
  }
}
