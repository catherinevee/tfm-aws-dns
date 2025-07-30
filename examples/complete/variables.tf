# Variables for Complete DNS Example

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "infrastructure-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# Domain Configuration
variable "domain_name" {
  description = "The public domain name for the hosted zone"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

variable "private_domain_name" {
  description = "The private domain name for internal resources"
  type        = string
  default     = "internal.example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.private_domain_name))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

# VPC Configuration
variable "vpc_id" {
  description = "The VPC ID for private DNS and resolver endpoints"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8}([a-f0-9]{9})?$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

# Website IP Addresses
variable "primary_website_ip" {
  description = "Primary website IP address"
  type        = string

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.primary_website_ip))
    error_message = "Primary website IP must be a valid IPv4 address."
  }
}

variable "secondary_website_ip" {
  description = "Secondary website IP address for failover"
  type        = string

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.secondary_website_ip))
    error_message = "Secondary website IP must be a valid IPv4 address."
  }
}

# API Endpoint IP Addresses
variable "api_us_east_ip" {
  description = "API endpoint IP address in US East"
  type        = string

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.api_us_east_ip))
    error_message = "API US East IP must be a valid IPv4 address."
  }
}

variable "api_us_west_ip" {
  description = "API endpoint IP address in US West"
  type        = string

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.api_us_west_ip))
    error_message = "API US West IP must be a valid IPv4 address."
  }
}

# Hybrid DNS Configuration
variable "enable_hybrid_dns" {
  description = "Enable hybrid DNS with Route 53 Resolver"
  type        = bool
  default     = false
}

variable "on_premises_domain" {
  description = "The on-premises domain to forward DNS queries to"
  type        = string
  default     = "corp.example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.on_premises_domain))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

variable "on_premises_dns_servers" {
  description = "On-premises DNS servers for forwarding"
  type = list(object({
    ip   = string
    port = optional(number, 53)
  }))
  default = [
    {
      ip   = "192.168.1.10"
      port = 53
    },
    {
      ip   = "192.168.1.11"
      port = 53
    }
  ]

  validation {
    condition = alltrue([
      for server in var.on_premises_dns_servers : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", server.ip))
    ])
    error_message = "All DNS server IPs must be valid IPv4 addresses."
  }
}
