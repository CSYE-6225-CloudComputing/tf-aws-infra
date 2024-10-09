resource "aws_vpc1 "my_vpc" {
  cidr_block = var.vpc_cidr_range

  tags = {
    Name = var.vpc_name
  }
}