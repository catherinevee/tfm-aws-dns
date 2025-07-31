# ==============================================================================
# COMPREHENSIVE DNS EXAMPLE VARIABLES
# ==============================================================================
# Variables for demonstrating maximum customizability of the DNS module

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format: us-west-2, eu-west-1, etc."
  }
}

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "dns-comprehensive-demo"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "demo"
  validation {
    condition     = contains(["dev", "staging", "prod", "demo"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, demo."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# ==============================================================================
# DOMAIN CONFIGURATION
# ==============================================================================

variable "domain_name" {
  description = "Primary domain name for the hosted zones"
  type        = string
  default     = "example.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

variable "private_domain_name" {
  description = "Private domain name (optional, defaults to domain_name)"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow destruction of hosted zones with existing records"
  type        = bool
  default     = false
}

# ==============================================================================
# ZONE CONFIGURATION
# ==============================================================================

variable "enable_public_zone" {
  description = "Enable creation of public hosted zone"
  type        = bool
  default     = true
}

variable "enable_private_zone" {
  description = "Enable creation of private hosted zone"
  type        = bool
  default     = true
}

variable "delegation_set_id" {
  description = "Reusable delegation set ID for consistent name servers"
  type        = string
  default     = null
}

variable "public_zone_vpc_associations" {
  description = "VPC associations for public zone (split-horizon DNS)"
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = []
}

variable "additional_vpc_associations" {
  description = "Additional VPC associations for private zone"
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = []
}

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================

variable "vpc_name" {
  description = "Name of the VPC to use for private zone and resolver endpoints"
  type        = string
  default     = "main-vpc"
}

# ==============================================================================
# DNS RECORDS CONFIGURATION
# ==============================================================================

variable "web_server_ips" {
  description = "IP addresses for web servers"
  type        = list(string)
  default     = ["203.0.113.1", "203.0.113.2"]
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for apex alias"
  type        = string
  default     = "d123456789.cloudfront.net"
}

variable "cloudfront_zone_id" {
  description = "CloudFront hosted zone ID"
  type        = string
  default     = "Z2FDTNDATAQYW2"  # CloudFront zone ID
}

variable "api_primary_ip" {
  description = "Primary API server IP address"
  type        = string
  default     = "203.0.113.10"
}

variable "api_secondary_ip" {
  description = "Secondary API server IP address"
  type        = string
  default     = "203.0.113.11"
}

variable "api_primary_health_check_id" {
  description = "Health check ID for primary API server"
  type        = string
  default     = null
}

variable "api_secondary_health_check_id" {
  description = "Health check ID for secondary API server"
  type        = string
  default     = null
}

variable "app_us_east_ip" {
  description = "Application server IP in US East"
  type        = string
  default     = "203.0.113.20"
}

variable "app_eu_west_ip" {
  description = "Application server IP in EU West"
  type        = string
  default     = "203.0.113.21"
}

variable "service_primary_ip" {
  description = "Primary service IP address"
  type        = string
  default     = "203.0.113.30"
}

variable "service_secondary_ip" {
  description = "Secondary service IP address"
  type        = string
  default     = "203.0.113.31"
}

variable "service_primary_health_check_id" {
  description = "Health check ID for primary service"
  type        = string
  default     = null
}

variable "lb_server1_ip" {
  description = "Load balancer server 1 IP address"
  type        = string
  default     = "203.0.113.40"
}

variable "lb_server2_ip" {
  description = "Load balancer server 2 IP address"
  type        = string
  default     = "203.0.113.41"
}

variable "lb_server1_health_check_id" {
  description = "Health check ID for load balancer server 1"
  type        = string
  default     = null
}

variable "lb_server2_health_check_id" {
  description = "Health check ID for load balancer server 2"
  type        = string
  default     = null
}

variable "google_verification_code" {
  description = "Google site verification code"
  type        = string
  default     = "example-verification-code"
}

# ==============================================================================
# PRIVATE ZONE RECORDS CONFIGURATION
# ==============================================================================

variable "internal_api_ips" {
  description = "Internal API server IP addresses"
  type        = list(string)
  default     = ["10.0.1.10", "10.0.1.11"]
}

variable "database_endpoint" {
  description = "Database endpoint hostname"
  type        = string
  default     = "db-cluster.cluster-xyz.us-west-2.rds.amazonaws.com"
}

variable "internal_lb_dns_name" {
  description = "Internal load balancer DNS name"
  type        = string
  default     = "internal-lb-123456789.us-west-2.elb.amazonaws.com"
}

variable "internal_lb_zone_id" {
  description = "Internal load balancer hosted zone ID"
  type        = string
  default     = "Z1D633PJN98FT9"  # US West 2 ELB zone ID
}

# ==============================================================================
# RESOLVER ENDPOINTS CONFIGURATION
# ==============================================================================

variable "enable_resolver_endpoints" {
  description = "Enable Route 53 Resolver endpoints for hybrid DNS"
  type        = bool
  default     = false
}

variable "resolver_inbound_ip_1" {
  description = "IP address for first inbound resolver endpoint"
  type        = string
  default     = "10.0.1.100"
}

variable "resolver_inbound_ip_2" {
  description = "IP address for second inbound resolver endpoint"
  type        = string
  default     = "10.0.2.100"
}

variable "resolver_outbound_ip_1" {
  description = "IP address for first outbound resolver endpoint"
  type        = string
  default     = "10.0.1.101"
}

variable "resolver_outbound_ip_2" {
  description = "IP address for second outbound resolver endpoint"
  type        = string
  default     = "10.0.2.101"
}

variable "onprem_dns_ip_1" {
  description = "On-premises DNS server IP address 1"
  type        = string
  default     = "192.168.1.10"
}

variable "onprem_dns_ip_2" {
  description = "On-premises DNS server IP address 2"
  type        = string
  default     = "192.168.1.11"
}

# ==============================================================================
# HEALTH CHECKS CONFIGURATION
# ==============================================================================

variable "enable_health_checks" {
  description = "Enable Route 53 health checks"
  type        = bool
  default     = false
}
