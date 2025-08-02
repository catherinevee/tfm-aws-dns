variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "domain_name" {
  description = "Private domain name for internal DNS"
  type        = string
  default     = "internal.local"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format (e.g., internal.local)."
  }
}

variable "vpc_id" {
  description = "VPC ID for private DNS zone (uses default VPC if not specified)"
  type        = string
  default     = null
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

# Database server IPs
variable "db_primary_ip" {
  description = "IP address of primary database server"
  type        = string
  default     = "10.0.1.10"
  
  validation {
    condition     = can(cidrhost("${var.db_primary_ip}/32", 0))
    error_message = "Database primary IP must be a valid IPv4 address."
  }
}

variable "db_replica_ip" {
  description = "IP address of database replica server"
  type        = string
  default     = "10.0.1.11"
  
  validation {
    condition     = can(cidrhost("${var.db_replica_ip}/32", 0))
    error_message = "Database replica IP must be a valid IPv4 address."
  }
}

# Application server IPs
variable "app_server_1_ip" {
  description = "IP address of application server 1"
  type        = string
  default     = "10.0.2.10"
  
  validation {
    condition     = can(cidrhost("${var.app_server_1_ip}/32", 0))
    error_message = "Application server 1 IP must be a valid IPv4 address."
  }
}

variable "app_server_2_ip" {
  description = "IP address of application server 2"
  type        = string
  default     = "10.0.2.11"
  
  validation {
    condition     = can(cidrhost("${var.app_server_2_ip}/32", 0))
    error_message = "Application server 2 IP must be a valid IPv4 address."
  }
}

# Cache server IPs
variable "redis_primary_ip" {
  description = "IP address of primary Redis server"
  type        = string
  default     = "10.0.3.10"
  
  validation {
    condition     = can(cidrhost("${var.redis_primary_ip}/32", 0))
    error_message = "Redis primary IP must be a valid IPv4 address."
  }
}

variable "redis_replica_ip" {
  description = "IP address of Redis replica server"
  type        = string
  default     = "10.0.3.11"
  
  validation {
    condition     = can(cidrhost("${var.redis_replica_ip}/32", 0))
    error_message = "Redis replica IP must be a valid IPv4 address."
  }
}

# Infrastructure server IPs
variable "internal_lb_ip" {
  description = "IP address of internal load balancer"
  type        = string
  default     = "10.0.4.10"
  
  validation {
    condition     = can(cidrhost("${var.internal_lb_ip}/32", 0))
    error_message = "Internal load balancer IP must be a valid IPv4 address."
  }
}

variable "monitoring_server_ip" {
  description = "IP address of monitoring server"
  type        = string
  default     = "10.0.5.10"
  
  validation {
    condition     = can(cidrhost("${var.monitoring_server_ip}/32", 0))
    error_message = "Monitoring server IP must be a valid IPv4 address."
  }
}

variable "log_server_ip" {
  description = "IP address of log aggregation server"
  type        = string
  default     = "10.0.5.11"
  
  validation {
    condition     = can(cidrhost("${var.log_server_ip}/32", 0))
    error_message = "Log server IP must be a valid IPv4 address."
  }
}
