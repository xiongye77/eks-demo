resource "aws_eks_node_group" "eks_ng_private_spot" {
  cluster_name    = aws_eks_cluster.eks_cluster.name

  node_group_name = "eks-ng-private-spot"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = [aws_subnet.eks-test-private-1a.id, aws_subnet.eks-test-private-1b.id]
  #version = var.cluster_version #(Optional: Defaults to EKS Cluster Kubernetes version)

  ami_type = "AL2_x86_64"
  capacity_type = "SPOT"
  #capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3.medium"]

  labels = {
    type_of_nodegroup = "spot"
  }

  #remote_access {
  #  ec2_ssh_key = "eks_public_key"
  #}

  scaling_config {
    desired_size = 3
    min_size     = 3
    max_size     = 5
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = 1
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
    #aws_iam_role_policy_attachment.eks-AmazonEC2SSM,  # if EKS node with this role, we can aws session manager to access eks node, but if without it, pod without service account assume IAM
 role could not access SSM
    aws_iam_role_policy_attachment.eks_cloudwatch_container_insights
    #kubernetes_config_map_v1.aws_auth
  ]
  tags = {
    Name = "Private-Node-Group-Spot"
    # Cluster Autoscaler Tags
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "TRUE"
  }
}


resource "aws_eks_node_group" "eks_ng_private_ondemand" {
  cluster_name    = aws_eks_cluster.eks_cluster.name

  node_group_name = "eks-ng-private-on-demand"

  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = [aws_subnet.eks-test-private-1a.id, aws_subnet.eks-test-private-1b.id]
  #version = var.cluster_version #(Optional: Defaults to EKS Cluster Kubernetes version)

  ami_type = "AL2_x86_64"
  #capacity_type = "SPOT"
  capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3.medium"]

  labels = {
    type_of_nodegroup = "ondemand"
  }

  #remote_access {
  #  ec2_ssh_key = "eks_public_key"
  #}

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = 1
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
    #aws_iam_role_policy_attachment.eks-AmazonEC2SSM,  # if EKS node with this role, we can aws session manager to access eks node, but if without it, pod without service account assume IAM
 role could not access SSM
    aws_iam_role_policy_attachment.eks_cloudwatch_container_insights
    #kubernetes_config_map_v1.aws_auth
  ]
  tags = {
    Name = "Private-Node-Group-OnDemand"
    # Cluster Autoscaler Tags
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "TRUE"
  }
}
