# Create KMS Key for ec2
resource "aws_kms_key" "ec2_kms_key" {
  description             = "KMS key for EBS"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
      },
      {
        "Sid" : "Allow service-linked role use of the customer managed key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:CreateGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : true
          }
        }
      }
    ] }
  )
}


#rds kms key
resource "aws_kms_key" "rds_kms_key" {
  description             = "KMS Key for RDS encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = {
    Name = "RDSKMSKey"
  }
}


# s3 kms key
resource "aws_kms_key" "s3_kms_key" {
  description             = "KMS Key for S3 encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-s3-policy",
    Statement: [
      {
        Sid       = "EnableRootPermissions",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "AllowS3Access",
        Effect    = "Allow",
        Principal = {
          AWS = aws_iam_role.ec2_role.arn
        },
        Action    = [
          "kms:GenerateDataKey",
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      }
    ]
  })

  tags = {
    Name = "S3KMSKey"
  }
}

# Secret Manager for (Database Password for RDS instance & Credentials for Email Service)

resource "aws_kms_key" "secrets_manager_kms_key" {
  description             = "KMS Key for Secrets Manager"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-secrets-manager-policy",
    Statement: [
      {
        Sid: "EnableRootPermissions",
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action: "kms:*",
        Resource: "*"
      },
      {
        Sid: "AllowSecretsManagerAccess",
        Effect: "Allow",
        Principal: {
          AWS: aws_iam_role.ec2_role.arn
        },
        Action: [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource: "*"
      }
    ]
  })

  tags = {
    Name = "SecretsManagerKMSKey"
  }
}


# # Create KMS Key for Secrets Manager
resource "aws_kms_key" "email_secrets_kms_key" {
  description             = "KMS Key for Lambda Email Service Credentials"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "EnableRootPermissions",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "AllowLambdaAccess",
        Effect    = "Allow",
        Principal = {
           AWS: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sns_lambda_execution_role"
        },
        Action    = [
          "kms:GenerateDataKey",
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      }
    ]
  })

  tags = {
    Name = "EmailSecretsKMSKey"
  }
}

