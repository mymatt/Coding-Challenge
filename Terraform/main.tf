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
