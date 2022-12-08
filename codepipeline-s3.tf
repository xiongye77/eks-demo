resource "aws_s3_bucket" "demo-artifacts" {
  bucket = "demo-artifacts-${random_string.random.result}"
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

resource "random_string" "random" {
  length  = 12
  special = false
  upper   = false
}
