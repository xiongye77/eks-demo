resource "aws_iam_role" "k8s_pod_iam_role" {
  name = "k8s-pod-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.oidc_provider.arn}"
        }
        Condition = {
          StringEquals = {            
            "${element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc_provider.arn}"), 1)}:sub": "system:serviceaccount:${var.k8s_namespace}:pod-ssm-sa"
          }
        }        

      },
    ]
  })

  tags = {
    tag-key = "k8s-pod-iam-role"
  }
}

# Associate IAM Role and Policy
resource "aws_iam_role_policy_attachment" "k8s_pod_iam_role_policy_attach" {
  policy_arn = "${aws_iam_policy.k8s_sa_ssm_read.arn}"
  role       = aws_iam_role.k8s_pod_iam_role.name
}



resource "aws_iam_policy" "k8s_sa_ssm_read" {
  name        = "iam_policy_k8s_sa_ssm_read"
  path        = "/"
  description = "IAM policy for k8s service account read SSM"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
         "ssm:GetParameter"
      ],
      "Resource": ["${aws_ssm_parameter.interview_parameter.arn}","${aws_ssm_parameter.rds-endpoint.arn}","${aws_ssm_parameter.rdspassword.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}
