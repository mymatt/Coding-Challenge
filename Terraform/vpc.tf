#---------------------------------------------------
# Define VPC
#---------------------------------------------------

resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tf-vpc"
  }
}

#---------------------------------------------------
# Setup Public Subnets - for ALB
#---------------------------------------------------

resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone_1

  map_public_ip_on_launch = "true"

  tags = {
    Name = "tf-public-subnet"
  }
}

# Backup for ALB
resource "aws_subnet" "public-subnet-2" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet_2_cidr
  availability_zone = var.availability_zone_2

  map_public_ip_on_launch = "true"

  tags = {
    Name = "tf-public-subnet-2"
  }
}

#---------------------------------------------------
# Internet Gateway - Public Subnet
#---------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "tf-gateway"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "tf-pub-route-table"
  }
}

resource "aws_route" "pub_int_gateway" {
  route_table_id         = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# assign route table to public subnet
resource "aws_route_table_association" "rt-as-pub-1" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "rt-as-pub-2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-rt.id
}

#---------------------------------------------------
# Private Subnets - For Web Server
#---------------------------------------------------

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-private-subnet"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-private-subnet-2"
  }
}

#---------------------------------------------------
# NAT gateways
#---------------------------------------------------

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public-subnet.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public-subnet-2.id
  depends_on    = [aws_internet_gateway.igw]
}
