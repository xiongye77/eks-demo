terraform {
  backend "s3" {
    bucket         = "terraform-up-and-running-state-code-test-defrgt"
    key            = "global/s3/terraform.tfstate"
    dynamodb_table = "terraform-up-and-running-locks-code-test"
    encrypt        = true
    region = "us-east-1"
  }
}
