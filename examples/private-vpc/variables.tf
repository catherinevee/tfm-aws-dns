# Variables for Private DNS with VPC Example

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "private_domain_name" {
  description = "The domain name for the private hosted zone"
  type        = string
  default     = "internal.example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.private_domain_name))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

variable "vpc_id" {
  description = "The VPC ID to associate with the private hosted zone"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8}([a-f0-9]{9})?$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

variable "additional_vpc_ids" {
  description = "Additional VPC IDs to associate with the private hosted zone"
  type        = list(string)
  default     = null

  validation {
    condition = var.additional_vpc_ids == null ? true : alltrue([
      for vpc_id in var.additional_vpc_ids : can(regex("^vpc-[a-f0-9]{8}([a-f0-9]{9})?$", vpc_id))
    ])
    error_message = "All VPC IDs must be valid AWS VPC identifiers."
  }
}
