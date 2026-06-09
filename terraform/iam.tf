# ===== IAM ROLE FOR EC2 =====
# This is the identity EC2 assumes when talking to AWS services
resource "aws_iam_role" "ec2_role" {
  name = "ec2-web-server-role"

  # Trust policy — allows EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ec2-web-server-role"
  }
}

# ===== IAM POLICY =====
# Defines exactly what EC2 is allowed to do — nothing more
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2-web-server-policy"
  description = "Least privilege policy for EC2 web servers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow EC2 to write logs to CloudWatch
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # Allow EC2 to read its own tags
        Sid    = "DescribeTags"
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        # Allow EC2 to read secrets from Secrets Manager
        # This is how EC2 gets the DB password without hardcoding it
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:multi-tier/*"
      }
    ]
  })
}

# ===== ATTACH POLICY TO ROLE =====
resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# ===== INSTANCE PROFILE =====
# A wrapper around the IAM role that EC2 can actually use
# EC2 doesn't use roles directly — it uses instance profiles
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-web-server-profile"
  role = aws_iam_role.ec2_role.name
}