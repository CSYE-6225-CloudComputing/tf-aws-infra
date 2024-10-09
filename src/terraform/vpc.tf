resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_range
  
  # Introduce a syntax error by adding an extra quote or wrong syntax
  tags = { 
    Name = var.vpc_name
  }"
}