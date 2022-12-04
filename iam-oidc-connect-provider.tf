# Datasource: AWS Partition
# Use this data source to lookup information about the current AWS partition in which Terraform is working
data "aws_partition" "current" {}


data "tls_certificate" "cluster" {
  url = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

# Resource: AWS IAM Open ID Connect Provider
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
}

locals {
    aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc_provider.arn}"), 1)
}



