terraform {
  required_version = ">= 0.13.1"
  required_providers {
    aws  = "~> 3.73.0"
  }
}

provider "aws" {
  region = "us-east-1"
}
