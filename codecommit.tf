resource "aws_codecommit_repository" "demo" {
  repository_name = var.codecommit_repo
  description     = "This is the demo repository"
}


resource "null_resource" "codecommit_push" {
  depends_on =[aws_codecommit_repository.demo]
  provisioner "local-exec" {
    command = "chmod +x ./codecommit_push.sh;./codecommit_push.sh ${var.codecommit_repo}"
  }
}
