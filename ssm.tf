resource "aws_ssm_parameter" "interview_parameter" {
  name  = "interview-parameter"
  type        = "SecureString"
  value = "parameter is eks-test"
}
