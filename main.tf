terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.56.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      owner      = "Fermino"
      managed-by = "Terraform"
      project    = "https://github.com/ferminolinux/remote-mk8s"
    }
  }
}

###############################################################################
# DATA
###############################################################################
# get public ip of terraform host machine
data "http" "remote-dns-resolver" {
  url = "https://ifconfig.me"
}

locals {
  tfhost_cidr = "${data.http.remote-dns-resolver.response_body}/32"
}

###############################################################################
# NETWORKING
###############################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name    = "main"
  version = "= 4.0.1"

  cidr                    = "172.23.0.0/16"
  azs                     = ["us-east-1a"]
  public_subnets          = ["172.23.100.0/24"]
  map_public_ip_on_launch = true
}

module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "= 4.17.2"

  name        = "main"
  description = "Security group for open ports to ssh and http"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      cidr_blocks = local.tfhost_cidr
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
    },
    {
      cidr_blocks = local.tfhost_cidr
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
    }
  ]

  egress_with_cidr_blocks = [
    {
      cidr_blocks = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
      protocol    = -1
    }
  ]
}

###############################################################################
# VIRTUAL MACHINES
###############################################################################

module "key" {
    source = "terraform-aws-modules/key-pair/aws"
    version = "= 2.0.2"
    key_name = "mk8s"
    public_key = file("./aws-key.pub")
}

module "ec2" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "= 5.0.0"
  name                   = "mk8s"
  ami                    = "ami-00ec2b52028b906bf"
  key_name = module.key.key_pair_name
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
}

###############################################################################
# PROVISIONER BLOCK: FOR ANSIBLE
###############################################################################
resource "terraform_data" "null_resource" {
  provisioner "local-exec" {
    command = "echo \"ansible_host: ${module.ec2.public_ip}\" > host_vars/mk8s.yaml"
  }
}

