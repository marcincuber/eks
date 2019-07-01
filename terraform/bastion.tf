#####
# Bastion Host configuration
#####

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

resource "aws_eip" "bastion" {
  vpc        = true
  depends_on = [module.vpc.igw_id]
}

resource "aws_launch_template" "bastion" {
  name_prefix = "launch-template-${var.cluster_name}-${var.environment}-bastion-"
  image_id    = data.aws_ami.amazon_linux.id
  key_name    = var.ssh_key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion.name
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.bastion.id, module.vpc.default_security_group_id]
  }

  user_data = base64encode(templatefile("scripts/bastion-userdata.sh", { ELASTIC_IP = aws_eip.bastion.id, REGION = var.region }))

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name_prefix         = "${var.cluster_name}-${var.environment}-bastion-asg-"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = flatten([module.vpc.public_subnets])

  force_delete         = true
  termination_policies = ["OldestInstance"]


  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage_above_base_capacity = 0
      on_demand_base_capacity                  = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.bastion.id
        version            = "$Latest"
      }

      override {
        instance_type = "t3.nano"
      }

      override {
        instance_type = "t3.micro"
      }

      override {
        instance_type = "t3.small"
      }

      override {
        instance_type = "t3.medium"
      }

      override {
        instance_type = "t3.large"
      }
    }
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster_name}-${var.environment}-bastion"
      propagate_at_launch = true
    },
    {
      key                 = "ServiceName"
      value               = "${var.cluster_name}-${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "ServiceOwner"
      value               = "cloudengineering@news.co.uk"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
  ]

  timeouts {
    delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_launch_template.bastion"]
}

resource "aws_autoscaling_schedule" "asg_scale_down" {
  scheduled_action_name  = "bastion_asg_scale_down"
  autoscaling_group_name = aws_autoscaling_group.bastion.name
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 20 * * MON-FRI"

  depends_on = ["aws_autoscaling_group.bastion"]
}

resource "aws_autoscaling_schedule" "asg_scale_up" {
  scheduled_action_name  = "bastion_asg_scale_up"
  autoscaling_group_name = aws_autoscaling_group.bastion.name
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 6 * * MON-FRI"

  depends_on = ["aws_autoscaling_group.bastion"]
}


resource "aws_security_group" "bastion" {
  name   = "Allow ssh access"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.cluster_name}-${var.environment}-bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "${var.cluster_name}-${var.environment}-bastion-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_iam_policy" "bastion" {
  name = "${var.cluster_name}-${var.environment}-bastion-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeAddresses",
        "ec2:AllocateAddress",
        "ec2:DescribeInstances",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion" {
  role       = "${aws_iam_role.bastion.name}"
  policy_arn = "${aws_iam_policy.bastion.arn}"
}

resource "aws_route53_record" "bastion" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "bastion-eks"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.bastion.public_ip}"]
}

#####
# Outputs
#####

output "bastion_host_public_ip" {
  value = aws_eip.bastion.public_ip
}

output "bastion_host_route53_record_name" {
  value = aws_route53_record.bastion.*.name
}

output "bastion_host_route53_record_fqdn" {
  value = aws_route53_record.bastion.*.fqdn
}

output "bastion_host_instance_profile_arn" {
  value = aws_iam_instance_profile.bastion.arn
}

output "bastion_host_policy_arn" {
  value = aws_iam_policy.bastion.arn
}

output "bastion_host_autoscaling_group_arn" {
  value = aws_autoscaling_group.bastion.arn
}

output "bastion_host_launch_template_arn" {
  value = aws_launch_template.bastion.arn
}
