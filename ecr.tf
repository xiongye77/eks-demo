resource "aws_ecr_repository" "repo" {
  name = var.ecr_repo_name
}

resource "null_resource" "push" {

  provisioner "local-exec" {
    command     = "chmod +x ./push.sh ; ${coalesce(var.push_script, "${path.module}/push.sh")} ${var.source_path} ${aws_ecr_repository.repo.repository_url} ${var.tag}"
    interpreter = ["bash", "-c"]
  }
}



