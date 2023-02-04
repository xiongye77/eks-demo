data "aws_ami" "amazon-linux-2-bastion" {
 most_recent = true
 filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
 owners = ["137112412989"] # AWS
}

resource "aws_security_group" "eks_bastion_sg" {
  vpc_id = aws_vpc.eks-test_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name        = "EKS Bastion host Security Group"
    Terraform   = "true"
    } 
}


# CREATE BASTION HOST IN PUBLIC SUBNET

resource "aws_instance" "bastion_host-1a" {
  #ami = "ami-09b42976632b27e9b" ami-0912f71e06545ad88 https://aws.amazon.com/amazon-linux-ami/
  ami = data.aws_ami.amazon-linux-2-bastion.id  
  instance_type = "t2.medium"
  key_name = aws_key_pair.eks_public_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.eks_bastion_sg.id]
  subnet_id = aws_subnet.eks-test-public-1a.id
  tags = {
    Name = "EKS Bastion Host - 1A"
    Terraform = true
  }
}


resource "aws_iam_role" "bastion_host_role" {
  name = "bastion-host-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "bastionhost-AmazonEC2SSM" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion_host_role.name
}
