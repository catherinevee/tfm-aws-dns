variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "public_domain_name" {
  description = "Public domain name for external access"
  type        = string
  default     = "example.com"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.public_domain_name))
    error_message = "Public domain name must be a valid domain format (e.g., example.com)."
  }
}

variable "private_domain_name" {
  description = "Private domain name for internal VPC DNS"
  type        = string
  default     = "internal.local"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.private_domain_name))
    error_message = "Private domain name must be a valid domain format (e.g., internal.local)."
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  
  validation {
    condition     = length(var.private_subnet_cidrs) >= 1
    error_message = "At least one private subnet CIDR must be provided."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "At least one public subnet CIDR must be provided."
  }
}

# EC2 Configuration
variable "key_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
  default     = null
}

variable "web_instance_count" {
  description = "Number of web server instances"
  type        = number
  default     = 2
  
  validation {
    condition     = var.web_instance_count >= 1 && var.web_instance_count <= 10
    error_message = "Web instance count must be between 1 and 10."
  }
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_count" {
  description = "Number of database server instances"
  type        = number
  default     = 2
  
  validation {
    condition     = var.db_instance_count >= 1 && var.db_instance_count <= 5
    error_message = "Database instance count must be between 1 and 5."
  }
}

variable "db_instance_type" {
  description = "Instance type for database servers"
  type        = string
  default     = "t3.micro"
}
