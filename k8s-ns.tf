resource "kubernetes_namespace" "k8s_ns" {
  metadata {
    name = var.k8s_namespace
  }
}
