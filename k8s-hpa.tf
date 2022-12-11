resource "kubernetes_horizontal_pod_autoscaler" "hpa_myapp" {
  metadata {  
  name = "hpa-myapp"
  namespace = kubernetes_namespace.k8s_ns.metadata.0.name
  }
  spec {
    max_replicas = 10
    min_replicas = 3
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment.k8s_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 20
  }
}
