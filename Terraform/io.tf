#---------------------------------------------------
# Inputs
#---------------------------------------------------

variable "ec2profile" {
  default = "awsprofile"
}

variable "cred_file" {
  default = "~/.aws/credentials"
}

variable "region" {
  default = "awsregion"
}

variable "availability_zone_1" {
  default = "awsregiona"
}

variable "availability_zone_2" {
  default = "awsregionb"
}

# Instance Config for Bastion
variable "instance_config" {
  type = map

  default = {
    "0" = {
      name = "bastion"

      region = "awsregion"

      availability_zone = "awsregiona"

      instance_type = "t2.micro"

      subnet = "public"

      security_group = "bastion_sg_pub"
    }
  }
}

# Instance Config for Auto Scaling Group for web server
variable "instance_config_asg" {
  type = map

  default = {
    "0" = {
      name = "web"

      region = "awsregion"

      availability_zone = "awsregiona"

      instance_type = "t2.micro"

      subnet = "private"

      security_group = "web_sg"

      port = "80"

      min = "1"

      max = "3"

      desired = "2"

      min_elb = "2"
    }
  }
}

# Load Balancer config
variable "elb_config" {
  type = map

  default = {
    "0" = {
      name           = "elbweb"
      subnet         = "public"
      security_group = "elb_web_sg"
      internal       = "false"
    }
  }
}

# only one Load Balancer
variable "elb_num" {
  default = "1"
}

variable "key_name" {
  default = "key_ec2"
}

variable "private_ssh_key_path" {
  default = "~/.ssh/ec2_tf.pem"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  default = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  default = "10.0.4.0/24"
}

variable "git_address" {
  default = ""
}

variable "ami_name" {
  default = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
}

variable "ami_type" {
  default = "hvm"
}

variable "account_ami_owner" {
  default = "awsowner"
}

variable "ubuntu_ami_owner" {
  default = "099720109477" #Canonical
}

variable "web_ami_id" {
  default = "ami-038725607463d2cc6"
}

variable "bastion_ami_id" {
  default = "ami-0601358a5a8cdd8fa"
}

variable "sg" {
  default = "aws_security_group"
}

variable "id" {
  default = "id"
}

#---------------------------------------------------
# Outputs
#---------------------------------------------------

# Output Bastion IP for SSH into Web Server
output "bastion_public_ip" {
  value = "${data.aws_instance.bastion.public_ip}"
}

# output DNS name for Load Balancer to test
output "ext_proxy_elb_dns" {
  value = "${data.aws_elb.elb.dns_name}"
}
