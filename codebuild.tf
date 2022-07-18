resource "aws_iam_policy" "codebuild" {
  name        = "${var.prefix}-codebuild"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Resource": [
          "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/codebuild/${var.prefix}-codebuild",
          "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/codebuild/${var.prefix}-codebuild:*"
        ],
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        "Effect": "Allow",
        "Resource": [
          "arn:aws:s3:::codepipeline-${local.aws_region}-*"
        ],
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        "Resource": [
          "arn:aws:codebuild:${local.aws_region}:${local.aws_account_id}:report-group/${var.prefix}-codebuild-*"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "codebuild" {
  name = "${var.prefix}-codebuild"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.codebuild.arn]
}

resource "aws_codebuild_project" "terraform" {
  name          = "${var.prefix}-codebuild"
  build_timeout = "10"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.prefix}-codebuild"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}

