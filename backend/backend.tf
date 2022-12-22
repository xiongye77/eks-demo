resource "aws_s3_bucket" "terraform-up-and-running-state-code-test" {
    bucket = "terraform-up-and-running-state-code-test-defrgt"
    versioning {
      enabled = true
    }
    acl = "private"

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = "AES256"
        }
      }
    }
    force_destroy = true
    #lifecycle {
    #  prevent_destroy = false
    #}

}

resource "aws_s3_bucket_public_access_block" "private-bucket-public-access-block" {
  bucket = aws_s3_bucket.terraform-up-and-running-state-code-test.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


resource "aws_dynamodb_table" "terraform-up-and-running-locks-code-test" {
  name = "terraform-up-and-running-locks-code-test"
  hash_key = "LockID"
  read_capacity = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }
}
