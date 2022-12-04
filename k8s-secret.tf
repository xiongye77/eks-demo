data "aws_ecr_authorization_token" "ecr_token" {
  registry_id = aws_ecr_repository.repo.registry_id
}


resource "kubernetes_secret" "docker" {
  metadata {
    name      = "docker-cfg"
    namespace = kubernetes_namespace.k8s_ns.metadata.0.name
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${data.aws_ecr_authorization_token.ecr_token.proxy_endpoint}" = {
          auth = "${data.aws_ecr_authorization_token.ecr_token.authorization_token}"
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}
