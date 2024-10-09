variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "vpc_cidr_range" {
    description = "The CIDR ranage for VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "public_subnets_cidrs" {
    description = "Public Subnets CIDR values"   
    type        = list(string)
    default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
 
variable "private_subnets_cidrs" {
    description = "Private Subnets CIDR values"
    type        = list(string)
    default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
    description = "List of availability zones"
    type        = list(string)
}

variable "internet_gateway_name" {
  description = "The name of the Internet Gateway"
  type        = string
}

variable "public_routing_table_name" {
  description = "The name of the Public Routing Table"
  type        = string
}

variable "public_cidr_routing_table"{
    description = "This is CIDR range for public routing table"
    type        = string
}

variable "private_routing_table_name"{
    description = "The name of the private routing tables"
    type        = string
}  

variable "aws_region"{
    description = "The name of aws current region"
    type        = string
}