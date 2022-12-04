#!/bin/bash
#
# Builds a Docker image and pushes to an AWS ECR repository
#
# Invoked by the terraform-aws-ecr-docker-image Terraform module.
#
# Usage:
#
# # Acquire an AWS session token
# $ ./push.sh . 123456789012.dkr.ecr.us-west-1.amazonaws.com/hello-world latest
#

set -e

source_path="$1"
repository_url="$2"
tag="${3:-latest}"

AWS_DEFAULT_REGION="$(echo "$repository_url" | cut -d. -f4)"
image_name="$(echo "$repository_url" | cut -d/ -f2)"

(cd "$source_path" && docker build -t "$image_name":$(git rev-parse HEAD) .)
printf "begin docker login\n"
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$repository_url"
#aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin "$repository_url"
docker tag "$image_name":$(git rev-parse HEAD) "$repository_url":$(git rev-parse HEAD)
docker push "$repository_url":$(git rev-parse HEAD)
