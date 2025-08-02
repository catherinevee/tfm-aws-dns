variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
  default     = "example.com"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format (e.g., example.com)."
  }
}

# Main domain server IPs
variable "main_server_ip" {
  description = "IP address of main domain server"
  type        = string
  default     = "192.0.2.1"
  
  validation {
    condition     = can(cidrhost("${var.main_server_ip}/32", 0))
    error_message = "Main server IP must be a valid IPv4 address."
  }
}

variable "mail_server_ip" {
  description = "IP address of mail server"
  type        = string
  default     = "192.0.2.10"
  
  validation {
    condition     = can(cidrhost("${var.mail_server_ip}/32", 0))
    error_message = "Mail server IP must be a valid IPv4 address."
  }
}

# Subdomain delegation nameservers
variable "api_subdomain_nameservers" {
  description = "Nameservers for API subdomain delegation"
  type        = list(string)
  default = [
    "ns1.api-provider.com",
    "ns2.api-provider.com"
  ]
}

variable "blog_subdomain_nameservers" {
  description = "Nameservers for blog subdomain delegation"
  type        = list(string)
  default = [
    "ns1.wordpress.com",
    "ns2.wordpress.com"
  ]
}

variable "staging_subdomain_nameservers" {
  description = "Nameservers for staging subdomain delegation"
  type        = list(string)
  default = [
    "ns-1234.awsdns-12.org",
    "ns-5678.awsdns-34.net"
  ]
}

variable "dev_subdomain_nameservers" {
  description = "Nameservers for development subdomain delegation"
  type        = list(string)
  default = [
    "ns-9012.awsdns-56.com",
    "ns-3456.awsdns-78.co.uk"
  ]
}

# Optional subdomain creation
variable "create_api_subdomain" {
  description = "Whether to create the API subdomain zone in this Terraform"
  type        = bool
  default     = false
}

variable "create_staging_subdomain" {
  description = "Whether to create the staging subdomain zone in this Terraform"
  type        = bool
  default     = false
}

# API subdomain server IPs (used if creating API subdomain)
variable "api_server_ip" {
  description = "IP address of API server"
  type        = string
  default     = "192.0.2.20"
  
  validation {
    condition     = can(cidrhost("${var.api_server_ip}/32", 0))
    error_message = "API server IP must be a valid IPv4 address."
  }
}

variable "api_v1_server_ip" {
  description = "IP address of API v1 server"
  type        = string
  default     = "192.0.2.21"
  
  validation {
    condition     = can(cidrhost("${var.api_v1_server_ip}/32", 0))
    error_message = "API v1 server IP must be a valid IPv4 address."
  }
}

variable "api_v2_server_ip" {
  description = "IP address of API v2 server"
  type        = string
  default     = "192.0.2.22"
  
  validation {
    condition     = can(cidrhost("${var.api_v2_server_ip}/32", 0))
    error_message = "API v2 server IP must be a valid IPv4 address."
  }
}

# Staging subdomain server IPs (used if creating staging subdomain)
variable "staging_server_ip" {
  description = "IP address of staging server"
  type        = string
  default     = "192.0.2.30"
  
  validation {
    condition     = can(cidrhost("${var.staging_server_ip}/32", 0))
    error_message = "Staging server IP must be a valid IPv4 address."
  }
}

variable "staging_api_server_ip" {
  description = "IP address of staging API server"
  type        = string
  default     = "192.0.2.31"
  
  validation {
    condition     = can(cidrhost("${var.staging_api_server_ip}/32", 0))
    error_message = "Staging API server IP must be a valid IPv4 address."
  }
}

variable "staging_db_server_ip" {
  description = "IP address of staging database server"
  type        = string
  default     = "192.0.2.32"
  
  validation {
    condition     = can(cidrhost("${var.staging_db_server_ip}/32", 0))
    error_message = "Staging database server IP must be a valid IPv4 address."
  }
}
