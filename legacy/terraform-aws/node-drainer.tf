resource "aws_lambda_function" "node_drainer" {
  count = var.enable_spot_workers && var.create_cluster ? length(module.vpc.private_subnets) : 0

  filename      = "node_drainer.zip"
  function_name = "${local.name_prefix}-node-drainer-function-${count.index}"
  role          = aws_iam_role.node_drainer.arn
  handler       = "handler.lambda_handler"
  memory_size   = "256"
  timeout       = "300"

  source_code_hash = filebase64sha256("node_drainer.zip")

  runtime = "python3.7"

  environment {
    variables = {
      CLUSTER_NAME = aws_eks_cluster.cluster[0].id
      REGION       = var.region
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.nonmanaged_workers_sg[0].id]
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_invoke_function_1" {
  count = var.enable_spot_workers && var.create_cluster ? length(module.vpc.private_subnets) : 0

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_drainer[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.node_drainer[count.index].arn
}

resource "aws_lambda_permission" "allow_invoke_function_2" {
  count = var.enable_spot_workers && var.create_cluster ? length(module.vpc.private_subnets) : 0

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_drainer[count.index].function_name
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "node_drainer" {
  count = var.enable_spot_workers && var.create_cluster ? length(module.vpc.private_subnets) : 0

  name        = "${local.name_prefix}-node-drainer-event-rule-${count.index}"
  description = "EKS node drainer Event Rule"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "EC2 Instance-terminate Lifecycle Action"
  ],
  "source": [
    "aws.autoscaling"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${local.name_prefix}-spot-node-group-${count.index}"
    ]
  }
}
PATTERN

  tags = var.tags

  depends_on = [aws_cloudformation_stack.spot_worker]
}

resource "aws_cloudwatch_event_target" "node_drainer" {
  count = var.enable_spot_workers && var.create_cluster ? length(module.vpc.private_subnets) : 0

  rule = aws_cloudwatch_event_rule.node_drainer[count.index].name
  arn  = aws_lambda_function.node_drainer[count.index].arn
}

resource "aws_iam_role" "node_drainer" {
  name = "${local.name_prefix}-node-drainer-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_iam_policy" "node_drainer" {
  name = "${local.name_prefix}-node-drainer-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:CompleteLifecycleAction",
        "ec2:DescribeInstances",
        "eks:DescribeCluster",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_drainer_attach" {
  role       = aws_iam_role.node_drainer.name
  policy_arn = aws_iam_policy.node_drainer.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attach" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" : "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.node_drainer.name
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution_attach" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" : "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.node_drainer.name
}
