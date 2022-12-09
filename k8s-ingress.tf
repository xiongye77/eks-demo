resource "kubernetes_ingress_v1" "ingress_app1" {
  metadata {
    name = "k8s-ingress"
    namespace = kubernetes_namespace.k8s_ns.metadata.0.name
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-groups-demo"
      # Ingress Core Settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/wafv2-acl-arn" = "${aws_wafv2_web_acl.my_web_acl.arn}"
      # Health Check Settings
      "alb.ingress.kubernetes.io/healthcheck-protocol" =  "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" = "traffic-port"
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = 15
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = 5
      "alb.ingress.kubernetes.io/success-codes" = 200
      "alb.ingress.kubernetes.io/healthy-threshold-count" = 2
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" = 2
      #alb.ingress.kubernetes.io/security-groups: sg-08043e2c21117694234  ALB SG name
      ## SSL Settings
      # Option-1: Using Terraform jsonencode Function
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{"HTTP" = 80}])
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{"HTTPS" = 443}, {"HTTP" = 80}])
      # Option-2: Using Terraform File Function      
      #"alb.ingress.kubernetes.io/listen-ports" = file("${path.module}/listen-ports/listen-ports.json")
      "alb.ingress.kubernetes.io/certificate-arn" =  "${aws_acm_certificate.myapp_alb.arn}"    
      "alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01" #Optional (Picks default if not used)    
      # SSL Redirect Setting
      "alb.ingress.kubernetes.io/ssl-redirect" = 443
      # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "${var.demo_dns_name}.${data.aws_route53_zone.public.name}"
      # Ingress Groups
      "alb.ingress.kubernetes.io/group.name" = "myapps.web"
      "alb.ingress.kubernetes.io/group.order" = 10
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "access_logs.s3.enabled=true,access_logs.s3.bucket=${aws_s3_bucket.alb_logging_bucket.id},access_logs.s3.prefix=ingress-groups-demo"
    }    
  }

  spec {
    default_backend {
      service {
        name = kubernetes_service.k8s_service.metadata[0].name
        port {
          number = 80
        }
      }
    }
    ingress_class_name = "my-aws-ingress-class" # Ingress Class        
    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service.k8s_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
          path = "/"
          path_type = "Prefix"
        }
      }
    }

  }
}
