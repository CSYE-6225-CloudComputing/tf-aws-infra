data "aws_availability_zones" "available" {}

resource "aws_subnet" "my_public_subnets" {
  count             = length(var.public_subnets_cidrs_range)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnets_cidrs_range[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "my_private_subnets" {
  count             = length(var.private_subnets_cidrs_range)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnets_cidrs_range[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = var.public_cidr_routing_table
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  tags = {
    Name = var.public_routing_table_name
  }
}

resource "aws_route_table_association" "public_route_table_subnets_association" {
  count          = length(aws_subnet.my_public_subnets)
  subnet_id      = aws_subnet.my_public_subnets[count.index].id
  route_table_id = aws_route_table.my_public_route_table.id
}

resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = var.private_routing_table_name
  }
}

resource "aws_route_table_association" "private_route_table_subnets_association" {
  count          = length(aws_subnet.my_private_subnets)
  subnet_id      = aws_subnet.my_private_subnets[count.index].id
  route_table_id = aws_route_table.my_private_route_table.id
}

resource "aws_security_group" "application_sg" {
  name        = "application_sg"
  description = "Security group for application instances"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.application_port # Use a variable for application port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Application Security Group"
  }
}

resource "aws_instance" "my_app_instance" {
  ami                         = var.custom_ami_id # Custom AMI ID
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.my_public_subnets[0].id     # Public subnet
  vpc_security_group_ids      = [aws_security_group.application_sg.id] # Security group
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name = "MyAppInstance"
  }
}
