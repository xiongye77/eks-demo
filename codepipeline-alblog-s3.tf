resource "aws_s3_bucket" "demo-artifacts" {
  bucket = "demo-artifacts-${random_string.codepipeline-random.result}"
  acl    = "private"
  force_destroy = true

  lifecycle_rule {
    id      = "clean-up"
    enabled = "true"

    expiration {
      days = 30
    }
  }
}

resource "random_string" "codepipeline-random" {
  length  = 12
  special = false
  upper   = false
}


resource "aws_s3_bucket" "alb_logging_bucket" {
  bucket = "alb-logging-${random_string.alb-random.result}"
  acl    = "private"
  force_destroy = true

  lifecycle_rule {
    id      = "clean-up"
    enabled = "true"

    expiration {
      days = 30
    }
  }
}

resource "random_string" "alb-random" {
  length  = 12
  special = false
  upper   = false
}

data "aws_iam_policy_document" "allow-lb" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::127311923021:root"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.alb_logging_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}


resource "aws_s3_bucket_policy" "allow-lb" {
  bucket = aws_s3_bucket.alb_logging_bucket.id
  policy = data.aws_iam_policy_document.allow-lb.json
}
