#---------------------------------------------------
# Terraform State file Location on S3 Bucket
#---------------------------------------------------
terraform {
  backend "s3" {
    bucket  = "tf-mm-state"
    key     = "terraform_aws_wp.tfstate"
    region  = "ap-southeast-2"
    profile = "ec2play"
  }
}

#---------------------------------------------------
# AWS Provider - Credentials for Authentication
#---------------------------------------------------
provider "aws" {
  region                  = var.region
  shared_credentials_file = var.cred_file
  profile                 = var.ec2profile
}

#---------------------------------------------------
# Create SSH key for Web Server
#---------------------------------------------------
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.generated.public_key_openssh
}

resource "local_file" "vpc_id" {
  content  = tls_private_key.generated.private_key_pem
  filename = "${var.key_name}.pem"

  provisioner "local-exec" {
    command = "chmod 600 ${var.key_name}.pem"
  }
}

#---------------------------------------------------
# Setup IAM Role for EC2
#---------------------------------------------------
resource "aws_iam_role" "ec2_access_role" {
  name               = "ec2_role"
  assume_role_policy = data.aws_iam_policy_document.ec2policy.json
}

data "aws_iam_policy_document" "ec2policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_iam_profile"
  role = aws_iam_role.ec2_access_role.name
}

#---------------------------------------------------
# Get AMI - Created by Packer (Immutable Infrastructure)
#---------------------------------------------------

data "aws_ami" "web" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.web_ami_id]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ami_type]
  }

  owners = [var.account_ami_owner]
}

data "aws_ami" "bastion" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.bastion_ami_id]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ami_type]
  }

  owners = [var.ubuntu_ami_owner]
}

#---------------------------------------------------
# Local variables for use in Dynamic Creation of resources
#---------------------------------------------------

# If we need more than one Load Balancer or EC2 Resource etc
locals {
  count_inst_asg = "${length(var.instance_config_asg) >= 1 ? length(var.instance_config_asg) : 0}"
  count_elb      = "${length(var.elb_config) >= 1 ? length(var.elb_config) : 0}"
}

#---------------------------------------------------
# Create Bastion
#---------------------------------------------------
resource "aws_instance" "bastion" {
  private_ip    = cidrhost(var.public_subnet_cidr, 21)
  ami           = data.aws_ami.bastion.id
  instance_type = lookup(var.instance_config[0], "instance_type")
  key_name      = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.bastion_sg_pub.id]
  subnet_id              = aws_subnet.public-subnet.id

  tags = {
    Name = lookup(var.instance_config[0], "name")
  }
}
