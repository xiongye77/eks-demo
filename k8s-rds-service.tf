resource "kubernetes_service" "k8s_rds_service" {
  metadata {
    name = "my-rds-service"
    namespace = kubernetes_namespace.k8s_ns.metadata.0.name
  }
  spec {
    external_name = "${aws_db_instance.k8s-pod-db.address}"
    type = "ExternalName"
  }
}
