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
  description = "This is the Security group for application instances"
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
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Application Security Group"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db_security_group"
  description = "This is the Security group for RDS instances"
  vpc_id      = aws_vpc.my_vpc.id

  # Allow inbound traffic from the application security group on port 3306
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application_sg.id] # Allow traffic from app SG
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database Security Group"
  }
}


resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = aws_subnet.my_private_subnets[*].id

  tags = {
    Name = "DB Subnet Group for RDS"
  }
}


resource "aws_db_parameter_group" "parameter_group" {
  name        = "custom-db-parameter-group"
  family      = var.db_parameter_family # Define the DB family (e.g., mysql8.0, postgres13, etc.)
  description = "Custom parameter group for ${var.db_engine} ${var.db_engine_version}"


  parameter {
    name  = "max_connections"
    value = "200"
  }

  tags = {
    Name = "CustomDBParameterGroup"
  }
}


resource "aws_db_instance" "rds_instance" {
  allocated_storage      = var.db_allocated_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = var.db_public_access
  multi_az               = var.db_multiaz
  parameter_group_name   = aws_db_parameter_group.parameter_group.name
  skip_final_snapshot    = true

  tags = {
    Name = "MyRDSInstance"
  }
}


resource "aws_instance" "my_app_instance" {
  ami                         = var.custom_ami_id # Custom AMI ID
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.my_public_subnets[0].id     # Public subnet
  vpc_security_group_ids      = [aws_security_group.application_sg.id] # Security group
  associate_public_ip_address = true
  key_name                    = var.key_name

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_type           = var.instance_vol_type
    volume_size           = var.instance_vol_size
    delete_on_termination = true
  }

  user_data = <<EOF
#!/bin/bash
echo "# App Environment Variables"
echo "DB_URL=jdbc:mysql://${aws_db_instance.rds_instance.address}:3306/${var.db_name}" >> /etc/environment
echo "DB_USERNAME=${var.db_username}" >> /etc/environment
echo "DB_PASSWORD=${var.db_password}" >> /etc/environment

sudo systemctl start csye6225.service
sudo systemctl enable csye6225.service
echo 'Checking status of csye6225 service...'
sudo systemctl status csye6225.service
sudo journalctl -xeu csye6225.service
EOF
  tags = {
    "Name" = "myappinstance"
  }
  depends_on = [aws_db_instance.rds_instance]
}

