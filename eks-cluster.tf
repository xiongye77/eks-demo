resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.cluster_name}"
  role_arn = aws_iam_role.eks_master_role.arn
  #version = var.cluster_version

  vpc_config {
    subnet_ids = [aws_subnet.eks-test-private-1a.id, aws_subnet.eks-test-private-1b.id]
  }

  #kubernetes_network_config {
  #  service_ipv4_cidr = var.cluster_service_ipv4_cidr
  #}
  
  # Enable EKS Cluster Control Plane Logging
  #enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}
