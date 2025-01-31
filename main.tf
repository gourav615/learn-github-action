# Define AWS Provider
provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "gourav-tf-statebucket-31012025"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}
# IAM Role
resource "aws_iam_role" "service_role" {
  name = "service-role"
  
  # Trust relationship policy (assume role policy)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"  # This allows EC2 service to assume this role
        }
      }
    ]
  })

  # Optional: Add tags
  tags = {
    Environment = "Production"
    Purpose     = "Service-Role"
  }
}

# IAM Policy Document
data "aws_iam_policy_document" "service_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::example-bucket/*",
      "arn:aws:s3:::example-bucket"
    ]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }
}

# IAM Policy
resource "aws_iam_policy" "service_policy" {
  name        = "service-policy"
  description = "Policy for service role"
  policy      = data.aws_iam_policy_document.service_policy.json
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "service_policy_attachment" {
  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.service_policy.arn
}

# Optional: Attach AWS Managed Policy
resource "aws_iam_role_policy_attachment" "service_ssm_policy" {
  role       = aws_iam_role.service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  # AWS managed policy for SSM
}

# Outputs
output "role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.service_role.arn
}

output "role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.service_role.name
}