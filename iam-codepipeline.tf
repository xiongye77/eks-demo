resource "aws_iam_role" "demo-codepipeline" {
  name = "demo-codepipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "demo-codepipeline-role-policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.demo-artifacts.arn,
      "${aws_s3_bucket.demo-artifacts.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = [
      "*",
    ]
  }
#  statement {
#    effect = "Allow"
#    actions = [
#      "sts:AssumeRole",
#    ]
#    resources = [
#      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/demo-codepipeline",
#    ]
#  }
  statement {
    effect = "Allow"
    actions = [
      "codecommit:UploadArchive",
      "codecommit:Get*",
      "codecommit:BatchGet*",
      "codecommit:Describe*",
      "codecommit:BatchDescribe*",
      "codecommit:GitPull",
    ]
    resources = [
      aws_codecommit_repository.demo.arn,
    ]
  }
}

resource "aws_iam_role_policy" "demo-codepipeline" {
  name   = "codepipeline-policy"
  role   = aws_iam_role.demo-codepipeline.id
  policy = data.aws_iam_policy_document.demo-codepipeline-role-policy.json
}
