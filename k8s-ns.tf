resource "null_resource" "create_appmesh" {
  depends_on = [kubernetes_namespace.k8s_ns]
  provisioner "local-exec" {
        command = " kubectl apply -f ./appmesh-k8sapp.yaml"
    }
}


resource "kubernetes_namespace" "k8s_ns" {
  depends_on = [helm_release.appmesh-controller]
  metadata {
    name = var.k8s_namespace
    labels = {
     "mesh" = "my-eks-app"
     "appmesh.k8s.aws/sidecarInjectorWebhook" = "enabled"
     "gateway" = "ingress-gw"
   }

  }
}
