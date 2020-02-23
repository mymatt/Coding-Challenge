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