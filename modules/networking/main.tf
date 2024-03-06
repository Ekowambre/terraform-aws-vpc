resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.vpc_tags
}

resource "aws_subnet" "public" {
  count             = length(var.pub_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.pub_cidrs[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "public-${count.index}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public"
  }
}

#create route table association
resource "aws_route_table_association" "public" {
  count          = length(var.pub_cidrs)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  count             = length(var.priv_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.priv_cidrs[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index % length(data.aws_availability_zones.az.names)] // Ensure index doesn't exceed the length of availability zones list

  tags = {
    Name = "private-${count.index}"
  }
}

resource "aws_eip" "main" {
  count = length(var.pub_cidrs)
  domain = "vpc"
}


resource "aws_nat_gateway" "main" {
  count         = length(var.pub_cidrs)
  allocation_id = aws_eip.main[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "main-${count.index}"
  }

  # Ensure proper ordering by adding an explicit dependency on the Internet Gateway for the VPC
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "private"
  }
}


resource "aws_route_table_association" "private" {
  count          = length(var.priv_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Key Pair
resource "aws_key_pair" "key" {
  key_name   = "main"
  public_key = tls_private_key.rsa.public_key_openssh
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create Security Group (With Outbound Rule Attached)
resource "aws_security_group" "main_sg" {
  name   = "main"
  vpc_id = aws_vpc.main.id

  ingress  {
    description = "http port"
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }

  ingress  {
    description = "ssh port"
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main_sg"
  }
}