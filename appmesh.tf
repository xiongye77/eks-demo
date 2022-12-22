resource "kubernetes_namespace_v1" "appmesh_system" {
  metadata {
    name = "appmesh-system"
  }
}


data "http" "get_appmesh_crd" {
  url = "https://raw.githubusercontent.com/aws/eks-charts/master/stable/appmesh-controller/crds/crds.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}



data "kubectl_file_documents" "appmesh_docs" {
    content = data.http.get_appmesh_crd.body
}

# Resource: kubectl_manifest which will create k8s Resources from the URL specified in above datasource
resource "kubectl_manifest" "appmesh_crd" {
    depends_on = [kubernetes_namespace_v1.appmesh_system]
    for_each = data.kubectl_file_documents.appmesh_docs.manifests
    yaml_body = each.value
}



data "http" "controller-iam-policy" {
  url = "https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "appmesh_controller_iam_policy" {
  name        = "AmazonEKS_AppMesh_Controller_Policy"
  path        = "/"
  description = "AppMesh Controller IAM Policy"
  policy = data.http.controller-iam-policy.body
}


# Resource: Create IAM Role and associate the EFS IAM Policy to it
resource "aws_iam_role" "appmesh_controller_iam_role" {
  name = "appmesh-controller-iam-role"

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
            "${element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc_provider.arn}"), 1)}:sub": "system:serviceaccount:appmesh-system:appmesh-controller"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "appmesh-controller"
  }
}

# Associate app mesh controller IAM Policy to app mesh IAM Role
resource "aws_iam_role_policy_attachment" "appmesh_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.appmesh_controller_iam_policy.arn
  role       = aws_iam_role.appmesh_controller_iam_role.name
}


#resource "kubernetes_service_account" "appmesh_controller_sa" {
#  depends_on = [aws_iam_role_policy_attachment.appmesh_iam_role_policy_attach ]
#  metadata {
#    name = "appmesh-controller"
#    namespace = kubernetes_namespace_v1.appmesh_system.metadata.0.name
#    annotations = {
#      "eks.amazonaws.com/role-arn" = aws_iam_role.appmesh_controller_iam_role.arn
#      }
#  }
#}


resource "helm_release" "appmesh-controller" {
  depends_on = [aws_iam_role.appmesh_controller_iam_role]
  name       = "appmesh-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "appmesh-controller"

  namespace = "appmesh-system"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "appmesh-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.appmesh_controller_iam_role.arn}"
  }

  set {
    name = "tracing.enabled"
    value = "true"
  }

  set {
    name = "tracing.provider"
    value = "x-ray"
  }
}
