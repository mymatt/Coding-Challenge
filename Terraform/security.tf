#---------------------------------------------------
# Security Group - Bastion
#---------------------------------------------------

resource "aws_security_group" "bastion_sg_pub" {
  name = "bastion_sg_pub"

  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8"
    to_port     = "0"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#---------------------------------------------------
# Security Group - ELB
#---------------------------------------------------

resource "aws_security_group" "elb_web_sg" {
  name = "elb_web_sg"

  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # No TLS
  # ingress {
  #   from_port   = "443"
  #   to_port     = "443"
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port   = "8"
    to_port     = "0"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#---------------------------------------------------
# Security Group - Web Server
#---------------------------------------------------

resource "aws_security_group" "web_sg" {
  name = "web_sg"

  depends_on = [aws_security_group.elb_web_sg]

  vpc_id = aws_vpc.default.id

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg_pub.id]
  }

  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.elb_web_sg.id, aws_security_group.bastion_sg_pub.id]
  }

  ingress {
    from_port       = "8"
    to_port         = "0"
    protocol        = "icmp"
    security_groups = [aws_security_group.bastion_sg_pub.id]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
