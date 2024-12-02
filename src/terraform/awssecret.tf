# Store Email Credentials in Secrets Manager
resource "aws_secretsmanager_secret" "email_service_secret" {
  name        = var.email_credentials_name
  description = "Credentials for Mailgun email service"
  kms_key_id  = aws_kms_key.email_secrets_kms_key.id

  tags = {
    Name = "EmailServiceCredentials"
  }
}

resource "aws_secretsmanager_secret_version" "email_service_secret_version" {
  secret_id = aws_secretsmanager_secret.email_service_secret.id
  secret_string = jsonencode({
    MAILGUN_API_KEY     = var.mailgunapikey
    MAILGUN_DOMAIN_NAME = var.mailgundomain
  })
}

# IAM Policy to Access Secrets Manager
resource "aws_iam_policy" "email_service_secrets_policy" {
  name        = "EmailServiceSecretsAccess"
  description = "Allow Lambda to access email service credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSecretsManagerAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.email_service_secret.arn
      }
    ]
  })
}

# Attach Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_email_service_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.email_service_secrets_policy.arn
}





# Store the Database Password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password_secret" {
  name        = var.db_password_secret
  description = "Database password for RDS instance"
  kms_key_id  = aws_kms_key.secrets_manager_kms_key.id

  tags = {
    Name = "DatabasePasswordSecret"
  }
}


resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id = aws_secretsmanager_secret.db_password_secret.id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
}

resource "aws_iam_policy" "secrets_manager_access_policy" {
  name = "SecretsManagerAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSecretsManagerAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.db_password_secret.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_access_policy.arn
}
