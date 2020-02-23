#---------------------------------------------------
# Inputs
#---------------------------------------------------

variable "ec2profile" {
  default = "ec2play"
}

variable "cred_file" {
  default = "~/.aws/credentials"
}

variable "region" {
  default = "ap-southeast-2"
}

variable "availability_zone_1" {
  default = "ap-southeast-2a"
}

variable "availability_zone_2" {
  default = "ap-southeast-2b"
}

# Instance Config for Bastion
variable "instance_config" {
  type = map

  default = {
    "0" = {
      name = "bastion"

      region = "ap-southeast-2"

      availability_zone = "ap-southeast-2a"

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

      region = "ap-southeast-2"

      availability_zone = "ap-southeast-2a"

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

variable "amis" {
  type = map

  default = {
    "ap-southeast-2" = "ami-5e8bb23b"
  }
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
