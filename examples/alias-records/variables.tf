variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "domain_name" {
  description = "Domain name for the DNS zone"
  type        = string
  default     = "example.com"
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format (e.g., example.com)."
  }
}

variable "load_balancer_name" {
  description = "Name of the Application Load Balancer (optional)"
  type        = string
  default     = null
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (optional)"
  type        = string
  default     = null
}

variable "api_gateway_domain" {
  description = "API Gateway custom domain name (optional)"
  type        = string
  default     = null
}

variable "api_gateway_zone_id" {
  description = "API Gateway hosted zone ID (optional)"
  type        = string
  default     = null
}

variable "legacy_server_ip" {
  description = "IP address of legacy server"
  type        = string
  default     = "192.0.2.100"
  
  validation {
    condition     = can(cidrhost("${var.legacy_server_ip}/32", 0))
    error_message = "Legacy server IP must be a valid IPv4 address."
  }
}
