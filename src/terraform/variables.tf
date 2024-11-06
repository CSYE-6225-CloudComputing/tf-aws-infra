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


variable "custom_ami_id" {
  description = "The custom AMI ID for the EC2 instance."
  type        = string
}

variable "application_port" {
  description = "The port on which the application runs."
  type        = number
  default     = 9001
}


variable "db_password" {
  description = "This is the db password."
  type        = string
  default     = "root"

}

variable "db_username" {
  description = "This is the db username."
  type        = string
  default     = "root"

}


variable "db_name" {
  description = "This is the db name"
  type        = string
  default     = "cloud"

}

variable "db_allocated_storage" {
  description = "This is the allocated db storage"
  type        = number
  default     = 20

}


variable "db_engine" {
  description = "This is the db engine"
  type        = string
  default     = "mysql"

}


variable "db_instance_class" {
  description = "This is db instance class"
  type        = string
  default     = "db.t3.micro"

}


variable "db_engine_version" {
  description = "The version of the database engine to use for the RDS instance."
  type        = string
}


variable "db_parameter_family" {
  description = "The family of the DB parameter group, depending on the engine (mysql8.0, postgres13, etc.)."
  type        = string
}



variable "db_public_access" {
  description = "This is the  publicly_accessible rule"
  type        = bool
  default     = false

}


variable "db_multiaz" {
  description = "Enable Multi-AZ deployment for the RDS instance."
  type        = bool
  default     = false
}

variable "instance_vol_type" {
  description = "Instance Volume Type"
  type        = string
  default     = "gp2"
}

variable "instance_vol_size" {
  description = "Instance Volume Type"
  type        = number
  default     = 50
}


variable "db_identifier" {
  description = "DB IDENTIFIER"
  type        = string
  default     = "csye6225"
}

variable "aws_route53_domain" {
  description = "This is route53 domain"
  type        = string
  default     = "dev.manalicloud.me"
}



variable "min_instance_size" {
  description = "This is min instance size"
  type        = number
  default     = 3
}


variable "max_instance_size" {
  description = "This is max instance"
  type        = number
  default     = 5
}


variable "desired_capacity" {
  description = "This is desired_capacity"
  type        = number
  default     = 3
}

variable "threshold_up" {
  description = "This is threshold for upscaling"
  type        = number
  default     = 7
}


variable "threshold_down" {
  description = "This is threshold for downscaling"
  type        = number
  default     = 6
}

variable "metric_name" {
  description = "This is metric name"
  type        = string
  default     = "CPUUtilization"
}

variable "health_check_interval" {
  description = "This is health_check_interval name"
  type        = number
  default     = 30
}

variable "scaling_adjustment_down" {
  description = "This is scaling_adjustment_down"
  type        = number
  default     = -1
}

variable "scaling_adjustment_up" {
  description = "This is scaling_adjustment_up"
  type        = number
  default     = 1
}

variable "cooldown_period" {
  description = "This is cooling down period"
  type        = number
  default     = 60
}

variable "adjustment_type" {
  description = "This is adjustment_type name"
  type        = string
  default     = "ChangeInCapacity"
}