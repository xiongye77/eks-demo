data "aws_ssm_parameter" "github_token" {
  name      = "my-github-token"
}

resource "aws_codebuild_project" "codebuild_demo" {
  name           = "codebuild_demo"
  description    = "codebuild docker build"
  build_timeout  = "30"
  service_role   = aws_iam_role.demo-codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }


  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.repo.name
    }
  
    environment_variable {
      name  = "githubtoken"
      value = data.aws_ssm_parameter.github_token.value
    }
 
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

}
