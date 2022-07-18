resource "aws_codestarconnections_connection" "github" {
  name          = "${var.prefix}-github"
  provider_type = "GitHub"
}

resource "aws_iam_policy" "codepipeline" {
  name        = "${var.prefix}-codepipeline"
  description = "Policy used in trust relationship with CodePipeline"

  policy = templatefile("${path.module}/templates/codepipeline_iam_policy.json", {})
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.prefix}-codepipeline"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.codepipeline.arn]
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.prefix}-codepipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.artifact_store_location
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration    = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.repository_id
        BranchName       = var.branch_name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "${var.prefix}-codebuild"
      }
    }
  }
}
