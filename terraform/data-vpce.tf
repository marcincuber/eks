data "aws_vpc_endpoint_service" "ecr_dkr" {
  service_type = "Interface"
  filter {
    name   = "service-name"
    values = ["*ecr.dkr*"]
  }
}

data "aws_vpc_endpoint_service" "sts" {
  service_type = "Interface"
  filter {
    name   = "service-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.sts"]
  }
}

data "aws_vpc_endpoint_service" "s3" {
  service_type = "Interface"
  filter {
    name   = "service-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.s3"]
  }
}

data "aws_vpc_endpoint_service" "guardduty" {
  service_type = "Interface"
  filter {
    name   = "service-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.guardduty-data"]
  }
}

data "aws_vpc_endpoint_service" "aps_workspaces" {
  service_type = "Interface"
  filter {
    name   = "service-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.aps-workspaces"]
  }
}

data "aws_iam_policy_document" "eks_vpc_guardduty" {
  statement {
    actions = ["*"]

    effect = "Allow"

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["*"]

    effect = "Deny"

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"

      values = [data.aws_caller_identity.current.account_id]
    }
  }
}
