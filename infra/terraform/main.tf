# main.tf - Core infrastructure for Phoenix Capstone

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the default subnets in the region
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for the cluster
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for ${var.cluster_name} cluster"
  vpc_id      = data.aws_vpc.default.id

  # SSH access from your IP only (you can restrict further)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Kubernetes API - restrict to internal traffic only
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Kubernetes API"
  }

  # Node-to-node communication
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Node-to-node communication"
  }

  # All outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-sg"
  }
}

# Create SSH key pair (if you don't have one already)
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

# Control plane node
resource "aws_instance" "control_plane" {
  count = var.control_plane_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.cluster.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "${var.cluster_name}-control-plane-${count.index + 1}"
  }
}

# Worker nodes
resource "aws_instance" "worker" {
  count = var.worker_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.cluster.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "${var.cluster_name}-worker-${count.index + 1}"
  }
}

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
