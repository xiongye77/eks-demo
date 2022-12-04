variable "aws-vpc-cidr" {
  type= string
  default="10.0.0.0/16"
}

variable "public_1_subnetCIDR" {
    default = "10.0.1.0/24"
}

variable "public_2_subnetCIDR" {
    default = "10.0.2.0/24"
}

variable "private_1_subnetCIDR" {
    default = "10.0.3.0/24"
}

variable "private_2_subnetCIDR" {
    default = "10.0.4.0/24"
}


# Create VPC

resource "aws_vpc" "eks-test_vpc" {
  cidr_block = var.aws-vpc-cidr
  instance_tenancy = "default"
  enable_dns_hostnames=true
  tags = {
    Name = "eks-test VPC"
    Terrafrom = "True"
  }
}
# Create and Attach internet gateway

resource "aws_internet_gateway" "eks-test-igw" {
  vpc_id = aws_vpc.eks-test_vpc.id
  tags = {
    Name        = "eks-test Internet Gateway"
    Terraform   = "true"
  }
}
# CREATE ELASTIC IP ADDRESS FOR NAT GATEWAY

resource "aws_eip" "eks-test-nat1" {
}

resource "aws_eip" "eks-test-nat2" {
}
  

# CREATE NAT GATEWAY in Region-1A

resource "aws_nat_gateway" "eks-test-nat-gateway-1a" {
  allocation_id = aws_eip.eks-test-nat1.id
  subnet_id     = aws_subnet.eks-test-public-1a.id

  tags = {
    Name        = "Nat Gateway-1a"
    Terraform   = "True"
  }
}

# CREATE NAT GATEWAY in Region-1B

resource "aws_nat_gateway" "eks-test-nat-gateway-1b" {
  allocation_id = aws_eip.eks-test-nat2.id
  subnet_id     = aws_subnet.eks-test-public-1b.id

  tags = {
    Name        = "Nat Gateway-1b"
    Terraform   = "True"
  }
}
# Create Public Subnets

resource "aws_subnet" "eks-test-public-1a" {
  vpc_id = aws_vpc.eks-test_vpc.id
  cidr_block = var.public_1_subnetCIDR
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "eks-test Public Subnet - 1A"
    Terraform   = "True"
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
resource "aws_subnet" "eks-test-public-1b" {
  vpc_id = aws_vpc.eks-test_vpc.id
  cidr_block = var.public_2_subnetCIDR
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "eks-test Public Subnet - 1B"
    Terraform   = "True"
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


# Create Private Subnets


resource "aws_subnet" "eks-test-private-1a" {
  vpc_id = aws_vpc.eks-test_vpc.id
  cidr_block = var.private_1_subnetCIDR
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = "false"
  tags = {
    Name        = "eks-test Private Subnet - 1A"
    Terraform   = "True"
  }
}

resource "aws_subnet" "eks-test-private-1b" {
  vpc_id = aws_vpc.eks-test_vpc.id
  cidr_block = var.private_2_subnetCIDR
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = "false"
  tags = {
    Name        = "eks-test Private Subnet - 1B"
    Terraform   = "True"
  }
}
# Create first private route table and associate it with private subnet in Region-1a
 
resource "aws_route_table" "eks-test_private_route_table_1a" {
    vpc_id = aws_vpc.eks-test_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-test-nat-gateway-1a.id
  }
    tags =  {
        Name      = "eks-test Private route table 1A"
        Terraform = "True"
  }
}
 
resource "aws_route_table_association" "eks-test-1a" {
    subnet_id = aws_subnet.eks-test-private-1a.id
    route_table_id = aws_route_table.eks-test_private_route_table_1a.id
}
 
# Create second private route table and associate it with private subnet in Region-1b 
 
resource "aws_route_table" "eks-test_private_route_table_1b" {
    vpc_id = aws_vpc.eks-test_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-test-nat-gateway-1b.id
  }
    tags =  {
        Name      = "eks-test Private route table 1B"
        Terraform = "True"
  }
}
 
resource "aws_route_table_association" "eks-test-1b" {
    subnet_id = aws_subnet.eks-test-private-1b.id
    route_table_id = aws_route_table.eks-test_private_route_table_1b.id
}

# Create a public route table for Public Subnets

resource "aws_route_table" "eks-test-public" {
  vpc_id = aws_vpc.eks-test_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-test-igw.id
  }
  tags = {
    Name        = "eks-test Public Route Table"
    Terraform   = "true"
    }
}

# Attach a public route table to Public Subnets

resource "aws_route_table_association" "eks-test-public-1a-association" {
  subnet_id = aws_subnet.eks-test-public-1a.id
  route_table_id = aws_route_table.eks-test-public.id
}

resource "aws_route_table_association" "eks-test-public-1b-association" {
  subnet_id = aws_subnet.eks-test-public-1b.id
  route_table_id = aws_route_table.eks-test-public.id
}
