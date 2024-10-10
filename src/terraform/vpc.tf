resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_range

  tags = {
    Name = var.vpc_name
  }
}
