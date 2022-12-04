terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }     
  }

}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      uuid    = "pr1PY"
    }
  }
}


provider "aws" {
  alias = "account_route53" # Specific to your setup
  version = ">= 3.4.0"
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.id
}

# Terraform Kubernetes Provider
provider "kubernetes" {
  host = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster.token
}


provider "kubectl" {
  # Configuration options
  host  = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate =  base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
