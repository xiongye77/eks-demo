variable "cluster_name" {
  type= string
  default="airflow-test"
}

variable "k8s_namespace"{
  type = string
  default = "my-eks-app"
}


variable "k8s_deployment"{
  type = string
  default = "my-app"
}


variable "aws_region"{
  type = string
  default = "us-east-1"
}

variable "ecr_repo_name" {
  description = "Name of ECR repo"
  type        = string
  default = "ecr-repo-random-123456"
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest"
}


variable "push_script" {
  description = "Path to script to build and push Docker image"
  type        = string
  default     = ""
}


variable "source_path" {
  description = "Path to Docker image source"
  type        = string
  default = "$PWD"
}



variable "demo_dns_zone" {
  description = "Specific to your setup, pick a domain you have in route53"
  default = "cmcloudlab950.info"

}


variable "demo_dns_name" {
  description = "Just a demo domain name"
  default     = "ssldemo-eks-alb"
}
