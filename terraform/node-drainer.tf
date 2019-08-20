resource "aws_lambda_function" "node_drainer" {
  filename      = "node_drainer.zip"
  function_name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-node-drainer-function"
  role          = "${aws_iam_role.node_drainer.arn}"
  handler       = "handler.lambda_handler"
  memory_size   = "256"
  timeout       = "300"

  source_code_hash = "${filebase64sha256("node_drainer.zip")}"

  runtime = "python3.7"

  environment {
    variables = {
      CLUSTER_NAME = aws_eks_cluster.cluster.id
      REGION       = var.region
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.node.id]
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_invoke_function_1" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_drainer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.node_drainer.arn
}

resource "aws_lambda_permission" "allow_invoke_function_2" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_drainer.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "node_drainer" {
  name        = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-node-drainer-event-rule"
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
      "${var.tags["ServiceType"]}-${var.tags["Environment"]}-spot-node-group"
    ]
  }
}
PATTERN

  tags = var.tags

  depends_on = [aws_cloudformation_stack.spot_worker]
}

resource "aws_cloudwatch_event_target" "node_drainer" {
  rule = "${aws_cloudwatch_event_rule.node_drainer.name}"
  arn  = "${aws_lambda_function.node_drainer.arn}"
}

resource "aws_iam_role" "node_drainer" {
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-node-drainer-role"
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
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-node-drainer-policy"

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
}

data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "lambda_vpc_access_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "node_drainer_attach" {
  role       = aws_iam_role.node_drainer.name
  policy_arn = aws_iam_policy.node_drainer.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attach" {
  role       = aws_iam_role.node_drainer.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution_attach" {
  role       = aws_iam_role.node_drainer.name
  policy_arn = data.aws_iam_policy.lambda_vpc_access_execution.arn
}
