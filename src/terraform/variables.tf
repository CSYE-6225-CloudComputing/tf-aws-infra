variable "vpc_name" {
  description = "This is the name of the VPC"
  type        = string
}

variable "vpc_cidr_range" {
  description = "This is the CIDR range for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidrs_range" {
  description = "This is the Public Subnets CIDR values"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets_cidrs_range" {
  description = "This is the Private Subnets CIDR values"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "internet_gateway_name" {
  description = "This is the name of the Internet Gateway"
  type        = string
}

variable "public_routing_table_name" {
  description = "This is the name of the Public Routing Table"
  type        = string
}

variable "public_cidr_routing_table" {
  description = "This is CIDR range for public routing table"
  type        = string
}

variable "private_routing_table_name" {
  description = "This is the name of the private routing tables"
  type        = string
}

variable "aws_region" {
  description = "This is the name of the current AWS region"
  type        = string
}

variable "instance_type" {
  description = "This is the name of the instance type"
  type        = string
}

variable "key_name" {
  description = "This is the key name"
  type        = string
}

variable "custom_ami_id" {
  description = "The custom AMI ID for the EC2 instance."
  type        = string
}

variable "application_port" {
  description = "The port on which the application runs."
  type        = number
  default     = 9001
}