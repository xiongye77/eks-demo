data "external" "git_checkout" {
  program = ["sh","${path.module}/get_sha.sh"]
}
resource "kubernetes_deployment" "k8s_deployment" {
  metadata {
    name = var.k8s_deployment
    namespace = kubernetes_namespace.k8s_ns.metadata.0.name
    labels = {
      app = "my-app"
    }
  } 
 
  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
               label_selector {
                match_expressions {
                  key = "app"
                  operator = "In"
                  values = ["my-app"]
                }
               }
               topology_key = "kubernetes.io/hostname"
              }
            }
          }
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              preference {
               match_expressions {
                key      = "type_of_nodegroup"
                operator = "In"
                values   = ["spot"]
               }
              }
           }
          }
        }
        volume {
          name = "persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.efs_pvc.metadata[0].name
          }
        }


        container {
          image = "${aws_ecr_repository.repo.repository_url}:${data.external.git_checkout.result.sha}"
          name  = "my-app"
          port {
            container_port = 8080
          }
          resources {
            limits = {
              cpu = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu = "200m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8080

            }

            initial_delay_seconds = 30
            timeout_seconds = 10
            period_seconds        = 10
            failure_threshold = 3
          }
          readiness_probe {
            http_get {
             path = "/"
             port = 8080
            }
            initial_delay_seconds = 30
            timeout_seconds = 10
            period_seconds = 10
            failure_threshold = 3
          }
          }
        }
      }
    }
}
