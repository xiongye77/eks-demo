resource "aws_codepipeline" "demo" {
  name     = "demo-gitops-pipeline"
  role_arn = aws_iam_role.demo-codepipeline.arn
  
  artifact_store {
    location = aws_s3_bucket.demo-artifacts.bucket
    type     = "S3"
  }
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["demo-docker-source"]

      configuration = {
        RepositoryName = aws_codecommit_repository.demo.repository_name
        BranchName     = "main"
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
      input_artifacts  = ["demo-docker-source"]
      output_artifacts = ["demo-docker-build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_demo.name
      }
    }
  }

}
