resource "kubernetes_service" "k8s_service" {
  metadata {
    name = "my-app-service"
    namespace = kubernetes_namespace.k8s_ns.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.k8s_deployment.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
    type = "ClusterIP"
  }
}
