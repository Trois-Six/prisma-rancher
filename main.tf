data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  tags = {
    Customer = var.name
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = format("%s-vpc", var.name)

  cidr            = var.vpc_cidr_block
  azs             = [for v in data.aws_availability_zones.available.names : v]
  private_subnets = [for k, v in data.aws_availability_zones.available.names : cidrsubnet(var.private_subnet_prefix, 7, k)]
  public_subnets  = [for k, v in data.aws_availability_zones.available.names : cidrsubnet(var.public_subnet_prefix, 7, k)]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

data "aws_ami" "sles" {
  most_recent = true
  owners      = ["013907871322"]

  filter {
    name   = "name"
    values = ["suse-sles-15-sp3*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

resource "aws_key_pair" "key_pair" {
  key_name_prefix = "${var.name}-"
  public_key      = tls_private_key.global_key.public_key_openssh

  tags = local.tags
}

resource "aws_security_group" "allow_all" {
  name        = "${var.name}-allow_all"
  description = "Allow all traffic"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_instance" "server" {
  ami           = data.aws_ami.sles.id
  instance_type = var.server_instance_type

  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  root_block_device {
    volume_size = 16
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-server"
    }
  )
}

resource "random_password" "rancher_admin_password" {
  length  = 16
  special = true
}

module "rancher_common" {
  source = "./modules/rancher-common"

  node_public_ip        = aws_instance.server.public_ip
  node_internal_ip      = aws_instance.server.private_ip
  node_username         = var.username
  ssh_private_key_pem   = tls_private_key.global_key.private_key_pem
  rancher_version       = var.rancher_version
  rancher_server_dns    = "169.254.169.253"
  admin_password        = random_password.rancher_admin_password.result
  workload_cluster_name = var.name
}

resource "aws_instance" "nodes" {
  count = var.node_instances_count

  ami           = data.aws_ami.sles.id
  instance_type = var.nodes_instance_type

  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = module.vpc.public_subnets[count.index % length(module.vpc.private_subnets)]
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  user_data = templatefile(
    join("/", [path.module, "tpl/node_userdata.tpl"]),
    {
      username         = var.username
      register_command = module.rancher_common.custom_cluster_command
    }
  )

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-node-${count.index}"
    }
  )
}
