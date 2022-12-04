resource "kubernetes_service_account" "pod_ssm_sa" {
  depends_on = [ aws_iam_role_policy_attachment.k8s_pod_iam_role_policy_attach ]
  metadata {
    name = "pod-ssm-sa"
    namespace = kubernetes_namespace.k8s_ns.metadata.0.name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.k8s_pod_iam_role.arn
      }
  }
}
