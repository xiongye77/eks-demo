resource "tls_private_key" "eks_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save Private key locally
resource "local_file" "eks_private_key" {
  depends_on = [
    tls_private_key.eks_key,
  ]
  content  = tls_private_key.eks_key.private_key_pem
  filename = "eks_key.pem"
}

# Upload public key to create keypair on AWS
resource "aws_key_pair" "eks_public_key" {
  depends_on = [
    tls_private_key.eks_key,
  ]
  key_name   = "eks_public_key"
  public_key = tls_private_key.eks_key.public_key_openssh
}


resource "null_resource" "chmod_pem_key" {
  depends_on =[aws_key_pair.eks_public_key]
  provisioner "local-exec" {
    command = "chmod 400 eks_key.pem"
  }
}
