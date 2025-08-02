# Multi-VPC DNS Integration Variables

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

# VPC Configuration
variable "production_vpc_cidr" {
  description = "CIDR block for production VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.production_vpc_cidr, 0))
    error_message = "Production VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "development_vpc_cidr" {
  description = "CIDR block for development VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.development_vpc_cidr, 0))
    error_message = "Development VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "shared_services_vpc_cidr" {
  description = "CIDR block for shared services VPC"
  type        = string
  default     = "10.2.0.0/16"

  validation {
    condition     = can(cidrhost(var.shared_services_vpc_cidr, 0))
    error_message = "Shared services VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# Subnet Configuration
variable "production_private_cidrs" {
  description = "CIDR blocks for production private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.production_private_cidrs) >= 1
    error_message = "At least one production private subnet CIDR must be specified."
  }
}

variable "development_private_cidrs" {
  description = "CIDR blocks for development private subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]

  validation {
    condition     = length(var.development_private_cidrs) >= 1
    error_message = "At least one development private subnet CIDR must be specified."
  }
}

variable "shared_services_private_cidrs" {
  description = "CIDR blocks for shared services private subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]

  validation {
    condition     = length(var.shared_services_private_cidrs) >= 1
    error_message = "At least one shared services private subnet CIDR must be specified."
  }
}

# DNS Configuration
variable "shared_domain_name" {
  description = "Shared private domain name for cross-VPC DNS resolution"
  type        = string
  default     = "internal.company.local"

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.shared_domain_name))
    error_message = "Domain name must be a valid DNS domain (lowercase, alphanumeric, dots, and hyphens only)."
  }
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type for all instances"
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t2.micro", "t2.small", "t2.medium", "t2.large",
      "m5.large", "m5.xlarge", "c5.large", "c5.xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "production_instance_count" {
  description = "Number of EC2 instances in production VPC"
  type        = number
  default     = 2

  validation {
    condition     = var.production_instance_count >= 1 && var.production_instance_count <= 10
    error_message = "Production instance count must be between 1 and 10."
  }
}

variable "development_instance_count" {
  description = "Number of EC2 instances in development VPC"
  type        = number
  default     = 2

  validation {
    condition     = var.development_instance_count >= 1 && var.development_instance_count <= 10
    error_message = "Development instance count must be between 1 and 10."
  }
}

variable "shared_services_instance_count" {
  description = "Number of EC2 instances in shared services VPC"
  type        = number
  default     = 2

  validation {
    condition     = var.shared_services_instance_count >= 1 && var.shared_services_instance_count <= 5
    error_message = "Shared services instance count must be between 1 and 5."
  }
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 instance access (optional)"
  type        = string
  default     = null
}

# VPC Peering Configuration
variable "enable_cross_environment_peering" {
  description = "Enable direct peering between production and development VPCs"
  type        = bool
  default     = false
}

# Tagging
variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "multi-vpc-demo"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.environment))
    error_message = "Environment name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "multi-vpc-dns"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.project_name))
    error_message = "Project name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "owner" {
  description = "Owner/team responsible for the resources"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "engineering"
}

# Advanced DNS Configuration
variable "dns_ttl_default" {
  description = "Default TTL for DNS records in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.dns_ttl_default >= 60 && var.dns_ttl_default <= 86400
    error_message = "DNS TTL must be between 60 seconds and 24 hours (86400 seconds)."
  }
}

variable "dns_ttl_short" {
  description = "Short TTL for frequently changing DNS records in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.dns_ttl_short >= 30 && var.dns_ttl_short <= 300
    error_message = "Short DNS TTL must be between 30 and 300 seconds."
  }
}

variable "enable_dns_logging" {
  description = "Enable DNS query logging for the private zone"
  type        = bool
  default     = false
}

# Security Configuration
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "Additional CIDR blocks allowed to access resources"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All allowed CIDR blocks must be valid IPv4 CIDR blocks."
  }
}
