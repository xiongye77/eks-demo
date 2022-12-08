resource "kubernetes_namespace_v1" "argocd_ns" {
  metadata {
    name = "argocd"
  }
}



data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
  # Optional request headers
  request_headers = {
    Accept = "text/*"
  }
}

# Datasource: kubectl_file_documents
# This provider provides a data resource kubectl_file_documents to enable ease of splitting multi-document yaml content.
data "kubectl_file_documents" "argocd_install_docs" {
    content = data.http.argocd_install.body
}

# Resource: kubectl_manifest which will create k8s Resources from the URL specified in above datasource
resource "kubectl_manifest" "argocd" {
    depends_on = [kubernetes_namespace_v1.argocd_ns]
    override_namespace = "argocd"
    for_each = data.kubectl_file_documents.argocd_install_docs.manifests
    yaml_body = each.value
}




resource "null_resource" "patch_kubectl" {
  depends_on = [kubectl_manifest.argocd]
  provisioner "local-exec" {
        command = "chmod +x ./pathch_argo.sh ; ${path.module}/pathch_argo.sh"
    }
}

resource "time_sleep" "wait_300_seconds" {
  depends_on = [null_resource.patch_kubectl]

  create_duration = "300s"
}
resource "null_resource" "get_argoserver_url" {
  depends_on = [time_sleep.wait_300_seconds]
  provisioner "local-exec" {
        command = "kubectl get svc argocd-server -n argocd -o json | jq --raw-output .status.loadBalancer.ingress[0].hostname > ${path.module}/argoserver_url.txt"
    }
}


resource "null_resource" "get_argoserver_pwd" {
  depends_on = [null_resource.get_argoserver_url]
  provisioner "local-exec" {
        command = " chmod +x ./get_argo_pwd.sh ; ${path.module}/get_argo_pwd.sh"
    }
}


resource "null_resource" "login_argocd" {
  depends_on = [null_resource.get_argoserver_pwd]
  provisioner "local-exec" {
        command = " chmod +x ./login_argocd.sh ; ${path.module}/login_argocd.sh"
    }
}

