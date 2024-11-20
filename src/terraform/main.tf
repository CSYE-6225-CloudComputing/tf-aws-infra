data "aws_availability_zones" "available" {}

resource "aws_subnet" "my_public_subnets" {
  count             = length(var.public_subnets_cidrs_range)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnets_cidrs_range[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "my_private_subnets" {
  count             = length(var.private_subnets_cidrs_range)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnets_cidrs_range[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = var.public_cidr_routing_table
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  tags = {
    Name = var.public_routing_table_name
  }
}

resource "aws_route_table_association" "public_route_table_subnets_association" {
  count          = length(aws_subnet.my_public_subnets)
  subnet_id      = aws_subnet.my_public_subnets[count.index].id
  route_table_id = aws_route_table.my_public_route_table.id
}

resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = var.private_routing_table_name
  }
}

resource "aws_route_table_association" "private_route_table_subnets_association" {
  count          = length(aws_subnet.my_private_subnets)
  subnet_id      = aws_subnet.my_private_subnets[count.index].id
  route_table_id = aws_route_table.my_private_route_table.id
}



resource "aws_security_group" "db_sg" {
  name        = "db_security_group"
  description = "This is the Security group for RDS instances"
  vpc_id      = aws_vpc.my_vpc.id

  # Allow inbound traffic from the application security group on port 3306
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application_sg.id] # Allow traffic from app SG
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database Security Group"
  }
}


resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = aws_subnet.my_private_subnets[*].id

  tags = {
    Name = "DB Subnet Group for RDS"
  }
}


resource "aws_db_parameter_group" "parameter_group" {
  name        = "custom-db-parameter-group"
  family      = var.db_parameter_family
  description = "Custom parameter group for ${var.db_engine} ${var.db_engine_version}"


  parameter {
    name  = "max_connections"
    value = "200"
  }

  tags = {
    Name = "CustomDBParameterGroup"
  }
}


resource "aws_db_instance" "rds_instance" {
  identifier             = var.db_identifier
  allocated_storage      = var.db_allocated_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = var.db_public_access
  multi_az               = var.db_multiaz
  parameter_group_name   = aws_db_parameter_group.parameter_group.name
  skip_final_snapshot    = true


  tags = {
    Name = "MyRDSInstance"
  }
}

resource "random_uuid" "bucket_name" {}

resource "aws_s3_bucket" "my_private_bucket" {
  bucket        = random_uuid.bucket_name.result
  force_destroy = true

  tags = {
    Name = "MyS3PrivateBucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.my_private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.my_private_bucket.id

  rule {
    id     = "TransitionToIA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }


  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_access_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}


resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy to allow EC2 access to the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.my_private_bucket.arn}/*", # Access to objects in the bucket
          aws_s3_bucket.my_private_bucket.arn         # Access to the bucket itself
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_s3_policy_to_ec2_role" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.ec2_role.name
}


resource "aws_iam_instance_profile" "ec2_profile" {
  role = aws_iam_role.ec2_role.name
}


data "aws_route53_zone" "domain" {
  name = var.aws_route53_domain
}

resource "aws_route53_record" "subdomain_a_record" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = data.aws_route53_zone.domain.name
  type    = "A"
  alias {
    name                   = aws_lb.my_lb.dns_name
    zone_id                = aws_lb.my_lb.zone_id
    evaluate_target_health = true
  }

}


resource "aws_iam_policy" "custom_cloudwatch_agent_policy" {
  name        = "CloudWatchAgentServerPolicy"
  description = "IAM Policy for CloudWatch Agent permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CWACloudWatchServerPermissions"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "CWASSMServerPermissions"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "custom_cloudwatch_agent_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.custom_cloudwatch_agent_policy.arn
}


# Define the IAM Policy for Auto Scaling
resource "aws_iam_policy" "custom_autoscaling_policy" {
  name        = "AutoScalingPolicy"
  description = "IAM Policy for Auto Scaling permissions without CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AutoScalingEC2Permissions"
        Effect = "Allow"
        Action = [
          "autoscaling:AttachInstances",
          "autoscaling:DetachInstances",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "ec2:DescribeInstances",
          "ec2:RunInstances"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role" "autoscaling_role" {
  name = "AutoScalingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the custom Auto Scaling policy to the role
resource "aws_iam_role_policy_attachment" "attach_autoscaling_policy" {
  role       = aws_iam_role.autoscaling_role.name
  policy_arn = aws_iam_policy.custom_autoscaling_policy.arn
}


resource "aws_security_group" "lb_sg" {
  name        = "load_balancer_sg"
  description = "Security group for Load Balancer"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "LoadBalancerSecurityGroup"
  }
}

resource "aws_security_group" "application_sg" {
  name        = "application_sg"
  description = "This is the Security group for application instances"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Application Security Group"
  }
}


# Load Balancer configuration
resource "aws_lb" "my_lb" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.my_public_subnets.*.id

  enable_deletion_protection = false
}



resource "aws_lb_target_group" "app_target_group" {
  name        = "app-target-group"
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "instance"

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = var.health_check_interval
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 5
    port                = var.application_port
  }

  tags = {
    Name = "WebAppTargetGroup"
  }
}


# Listener for Load Balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}



resource "aws_launch_template" "csye6225_launch_template" {
  depends_on    = [aws_db_instance.rds_instance]
  name          = var.launchTemplateName
  image_id      = var.custom_ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application_sg.id]
  }

  user_data = base64encode(<<EOF
#!/bin/bash
sudo systemctl stop csye6225.service
sudo systemctl stop amazon-cloudwatch-agent
echo "# App Environment Variables"
echo "DB_URL=jdbc:mysql://${aws_db_instance.rds_instance.address}:3306/${var.db_name}" >> /etc/environment
echo "DB_USERNAME=${var.db_username}" >> /etc/environment
echo "DB_PASSWORD=${var.db_password}" >> /etc/environment
echo "AWS_S3_BUCKET_NAME=${aws_s3_bucket.my_private_bucket.id}" >> /etc/environment
echo "AWS_S3_REGION=${var.aws_region}" >> /etc/environment
echo "AWS_SNS_ARN=${aws_sns_topic.sns_topic.arn}" >> /etc/environment
echo "DOMAIN_NAME=${var.aws_route53_domain}" >> /etc/environment

sudo systemctl daemon-reload
sudo systemctl start csye6225.service
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent

echo 'Checking status of csye6225 service...'
sudo systemctl status csye6225.service
sudo journalctl -xeu csye6225.service
EOF
  )
}


resource "aws_autoscaling_group" "webapp_asg" {

  name = var.autoScalingGroupName
  launch_template {
    id      = aws_launch_template.csye6225_launch_template.id
    version = aws_launch_template.csye6225_launch_template.latest_version
  }

  min_size                  = var.min_instance_size
  max_size                  = var.max_instance_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = [for subnet in aws_subnet.my_public_subnets : subnet.id] # Attach ASG to public subnets
  target_group_arns         = ["${aws_lb_target_group.app_target_group.arn}"]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  default_cooldown          = 60

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_on_cpu"
  scaling_adjustment     = var.scaling_adjustment_up
  adjustment_type        = var.adjustment_type
  cooldown               = var.cooldown_period
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_on_cpu"
  scaling_adjustment     = var.scaling_adjustment_down
  adjustment_type        = var.adjustment_type
  cooldown               = var.cooldown_period
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
}


resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = var.metric_name
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.threshold_up
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = var.metric_name
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.threshold_down
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }
}


# Lambda Execution Role
resource "aws_iam_role" "lambda_role" {
  name = "sns_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "sns_lambda_policy"
  description = "Policy for Lambda to access SNS and cloudwatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:ListSubscriptions",
          "sns:ListSubscriptionsByTopic"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_sns_topic.sns_topic.arn}",
        ]
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


# Attach Lambda execution policy to the role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function
resource "aws_lambda_function" "sns_lambda" {
  function_name = "sns_lambda_function"

  role        = aws_iam_role.lambda_role.arn
  handler     = "awslambda.SnsLambdaFunction::handleRequest"
  runtime     = "java21"
  memory_size = 512
  timeout     = 60
  filename    = var.filename

  environment {
    variables = {
      MAIL_GUN_API_KEY     = var.mailgunapikey
      MAIL_GUN_DOMAIN_NAME = var.mailgundomain
    }
  }
}

# SNS Topic
resource "aws_sns_topic" "sns_topic" {
  name = "email_request_topic"
}

# SNS Subscription for Lambda
resource "aws_sns_topic_subscription" "sns_lambda_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_lambda.arn
}


data "aws_caller_identity" "current" {}

locals {
  aws_user_account_id = data.aws_caller_identity.current.account_id
}


data "aws_iam_policy_document" "sns-topic-policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "${local.aws_user_account_id}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sns_topic.sns_topic.arn}",
    ]

    sid = "__default_statement_ID"
  }
}


# IAM policy for SNS
resource "aws_iam_policy" "sns_iam_policy" {
  name   = "ec2_iam_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "SNS:Publish"
      ],
      "Resource": "${aws_sns_topic.sns_topic.arn}"
    }
  ]
}
EOF
}

# Attach the SNS topic policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_instance_sns" {
  policy_arn = aws_iam_policy.sns_iam_policy.arn
  role       = aws_iam_role.ec2_role.name
}


# Allow SNS to invoke the Lambda function
resource "aws_lambda_permission" "sns_lambda_permission" {
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn
}