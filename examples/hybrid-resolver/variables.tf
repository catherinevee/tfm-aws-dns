# Variables for Hybrid DNS with Route 53 Resolver Example

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

# Domain Configuration
variable "public_domain_name" {
  description = "The public domain name for the hosted zone"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.public_domain_name))
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

variable "on_premises_domain" {
  description = "The on-premises domain to forward DNS queries to"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.on_premises_domain))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

variable "additional_forward_domain" {
  description = "Additional domain to forward to on-premises DNS servers"
  type        = string
  default     = null

  validation {
    condition     = var.additional_forward_domain == null ? true : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.additional_forward_domain))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

# VPC Configuration
variable "vpc_id" {
  description = "The VPC ID for resolver endpoints"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8}([a-f0-9]{9})?$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

variable "resolver_subnet_names" {
  description = "Names of subnets to use for resolver endpoints (must be in different AZs)"
  type        = list(string)
  default     = ["private-subnet-1", "private-subnet-2"]

  validation {
    condition     = length(var.resolver_subnet_names) >= 2
    error_message = "At least 2 subnets are required for resolver endpoints in different AZs."
  }
}

# Network Configuration
variable "on_premises_cidr_blocks" {
  description = "CIDR blocks for on-premises networks"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.on_premises_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "on_premises_dns_servers" {
  description = "On-premises DNS servers for forwarding"
  type = list(object({
    ip   = string
    port = optional(number, 53)
  }))

  validation {
    condition = alltrue([
      for server in var.on_premises_dns_servers : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", server.ip))
    ])
    error_message = "All DNS server IPs must be valid IPv4 addresses."
  }
}

# Resolver Configuration
variable "enable_inbound_resolver" {
  description = "Enable inbound resolver endpoint for on-premises to AWS queries"
  type        = bool
  default     = true
}

variable "enable_outbound_resolver" {
  description = "Enable outbound resolver endpoint for AWS to on-premises queries"
  type        = bool
  default     = true
}

variable "inbound_resolver_ips" {
  description = "Static IP addresses for inbound resolver endpoints"
  type        = list(string)
  default     = null

  validation {
    condition = var.inbound_resolver_ips == null ? true : alltrue([
      for ip in var.inbound_resolver_ips : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", ip))
    ])
    error_message = "All resolver IPs must be valid IPv4 addresses."
  }
}

variable "outbound_resolver_ips" {
  description = "Static IP addresses for outbound resolver endpoints"
  type        = list(string)
  default     = null

  validation {
    condition = var.outbound_resolver_ips == null ? true : alltrue([
      for ip in var.outbound_resolver_ips : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", ip))
    ])
    error_message = "All resolver IPs must be valid IPv4 addresses."
  }
}

# Public DNS Configuration
variable "public_website_ip" {
  description = "Public IP address for the website"
  type        = string

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.public_website_ip))
    error_message = "Website IP must be a valid IPv4 address."
  }
}
