data "http" "efs_csi_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "efs_csi_iam_policy" {
  name        = "AmazonEKS_EFS_CSI_Driver_Policy"
  path        = "/"
  description = "EFS CSI IAM Policy"
  policy = data.http.efs_csi_iam_policy.body
}


# Resource: Create IAM Role and associate the EFS IAM Policy to it
resource "aws_iam_role" "efs_csi_iam_role" {
  name = "efs-csi-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.oidc_provider.arn}"
        }
        Condition = {
          StringEquals = {
            "${element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc_provider.arn}"), 1)}:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "efs-csi"
  }
}

# Associate EFS CSI IAM Policy to EFS CSI IAM Role
resource "aws_iam_role_policy_attachment" "efs_csi_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.efs_csi_iam_policy.arn
  role       = aws_iam_role.efs_csi_iam_role.name
}



resource "helm_release" "efs_csi_driver" {
  depends_on = [aws_iam_role.efs_csi_iam_role ]
  name       = "aws-efs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"

  namespace = "kube-system"

  set {
    name = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver" # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/lat
est/userguide/add-ons-images.html
  }

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.efs_csi_iam_role.arn}"
  }

}





resource "aws_security_group" "efs_allow_access" {
  name        = "efs-allow-nfs-from-eks-vpc"
  description = "Allow Inbound NFS Traffic from EKS VPC CIDR"
  vpc_id      =  aws_vpc.eks-test_vpc.id

  ingress {
    description      = "Allow Inbound NFS Traffic from EKS VPC CIDR to EFS File System"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [var.aws-vpc-cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_nfs_from_eks_vpc"
  }
}


# Resource: EFS File System
resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "efs-demo"
  tags = {
    Name = "efs-demo"
  }
}


resource "aws_efs_mount_target" "efs_mount_target1" {
  file_system_id = "${aws_efs_file_system.efs_file_system.id}"
  subnet_id      = aws_subnet.eks-test-private-1a.id
  security_groups = [aws_security_group.efs_allow_access.id]
}


resource "aws_efs_mount_target" "efs_mount_target2" {
  file_system_id = "${aws_efs_file_system.efs_file_system.id}"
  subnet_id      = aws_subnet.eks-test-private-1b.id
  security_groups = [aws_security_group.efs_allow_access.id]
}


resource "kubernetes_storage_class_v1" "efs_sc" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId = aws_efs_file_system.efs_file_system.id
    directoryPerms = "700"
    gidRangeStart = "1000" # optional
    gidRangeEnd = "2000" # optional
  }
}


resource "kubernetes_persistent_volume_claim_v1" "efs_pvc" {
  metadata {
    name = "efs-claim"
    namespace = "my-eks-app"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class_v1.efs_sc.metadata[0].name
    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }
}



resource "kubernetes_persistent_volume_v1" "efs_pv" {
  metadata {
    name = "efs-pv"
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class_v1.efs_sc.metadata[0].name
    persistent_volume_source {
      csi {
      driver = "efs.csi.aws.com"
      volume_handle = aws_efs_file_system.efs_file_system.id
      }
    }
  }
}
