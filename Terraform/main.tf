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

#---------------------------------------------------
# Create AWS launch configurations for ASG's
#---------------------------------------------------
resource "aws_launch_configuration" "tf_lc" {
  count = local.count_inst_asg

  image_id = data.aws_ami.web.id

  # associate_public_ip_address = true

  instance_type        = lookup(var.instance_config_asg[count.index], "instance_type")
  key_name             = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  security_groups = [aws_security_group.web_sg.id]

  # no user_data, using Packer

  lifecycle {
    create_before_destroy = true
  }
}

#---------------------------------------------------
# Create AWS autoscaling groups
#---------------------------------------------------
resource "aws_autoscaling_group" "tf_asg" {
  count = local.count_inst_asg

  depends_on = [aws_elb.elb]

  name                 = "${lookup(var.instance_config_asg[count.index], "name")}-${element(aws_launch_configuration.tf_lc.*.name, count.index)}"
  launch_configuration = element(aws_launch_configuration.tf_lc.*.name, count.index)

  load_balancers = [lookup(var.elb_config[count.index], "name")]

  vpc_zone_identifier = [aws_subnet.private-subnet.id, aws_subnet.private-subnet-2.id]

  min_size         = lookup(var.instance_config_asg[count.index], "min")
  max_size         = lookup(var.instance_config_asg[count.index], "max")
  desired_capacity = lookup(var.instance_config_asg[count.index], "desired")

  health_check_type         = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = lookup(var.instance_config_asg[count.index], "name")
    propagate_at_launch = true
  }
}

#---------------------------------------------------
# Create Elastic Load Balancer
#---------------------------------------------------
resource "aws_elb" "elb" {
  count = local.count_elb

  name = lookup(var.elb_config[count.index], "name")

  subnets = ["${lookup(var.elb_config[count.index], "subnet") == "private" ? aws_subnet.private-subnet.id : aws_subnet.public-subnet.id}", "${lookup(var.elb_config[count.index], "subnet") == "private" ? aws_subnet.private-subnet-2.id : aws_subnet.public-subnet-2.id}"]

  security_groups = [aws_security_group.elb_web_sg.id]

  cross_zone_load_balancing = true

  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  internal = lookup(var.elb_config[count.index], "internal")

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 8
    timeout             = 60
    interval            = 300
    target              = "HTTP:80/"
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  tags = {
    Name = lookup(var.elb_config[count.index], "name")
  }
}

#---------------------------------------------------
# Scaling Up - Policy and Alarm
#---------------------------------------------------
resource "aws_autoscaling_policy" "up_policy" {
  count                  = local.count_inst_asg
  name                   = "up_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = element(aws_autoscaling_group.tf_asg.*.name, count.index)
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  count               = local.count_inst_asg
  alarm_name          = "alarm_cpu_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = element(aws_autoscaling_group.tf_asg.*.name, count.index)
  }

  alarm_description = "CPU utilization EC2 - Up"
  alarm_actions     = [element(aws_autoscaling_policy.up_policy.*.arn, count.index)]
}

#---------------------------------------------------
# Scaling Down - Policy and Alarm
#---------------------------------------------------
resource "aws_autoscaling_policy" "down_policy" {
  count                  = local.count_inst_asg
  name                   = "down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = element(aws_autoscaling_group.tf_asg.*.name, count.index)
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  count               = local.count_inst_asg
  alarm_name          = "alarm_cpu_down"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoScalingGroupName = element(aws_autoscaling_group.tf_asg.*.name, count.index)
  }

  alarm_description = "CPU utilization EC2 - Down"
  alarm_actions     = [element(aws_autoscaling_policy.down_policy.*.arn, count.index)]
}
