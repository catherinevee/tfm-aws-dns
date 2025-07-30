# AWS DNS Terraform Module Variables

# General Configuration
variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid DNS domain name."
  }
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Whether to destroy all records in the zone when destroying the zone"
  type        = bool
  default     = false
}

# Public Zone Configuration
variable "public_zone_enabled" {
  description = "Whether to create a public hosted zone"
  type        = bool
  default     = true
}

variable "public_zone_comment" {
  description = "A comment for the public hosted zone"
  type        = string
  default     = "Managed by Terraform"
}

variable "public_zone_tags" {
  description = "Additional tags for the public hosted zone"
  type        = map(string)
  default     = {}
}

variable "delegation_set_id" {
  description = "The ID of the reusable delegation set whose NS records you want to assign to the hosted zone"
  type        = string
  default     = null
}

variable "public_zone_vpc_associations" {
  description = "VPC associations for the public zone (for private queries to public zone)"
  type = list(object({
    vpc_id     = string
    vpc_region = string
  }))
  default = []
}

# Private Zone Configuration
variable "private_zone_enabled" {
  description = "Whether to create a private hosted zone"
  type        = bool
  default     = false
}

variable "private_domain_name" {
  description = "The domain name for the private hosted zone (defaults to domain_name if not specified)"
  type        = string
  default     = null
}

variable "private_zone_comment" {
  description = "A comment for the private hosted zone"
  type        = string
  default     = "Private zone managed by Terraform"
}

variable "private_zone_tags" {
  description = "Additional tags for the private hosted zone"
  type        = map(string)
  default     = {}
}

# VPC Configuration for Private Zone
variable "vpc_id" {
  description = "The VPC ID to associate with the private hosted zone"
  type        = string
  default     = null
}

variable "vpc_ids" {
  description = "List of VPC IDs to associate with the private hosted zone"
  type        = list(string)
  default     = []
}

variable "vpc_region" {
  description = "The VPC region for VPC associations"
  type        = string
  default     = null
}

variable "vpc_associations" {
  description = "List of VPC associations for the private hosted zone"
  type = list(object({
    vpc_id     = string
    vpc_region = string
  }))
  default = []
}

variable "additional_vpc_associations" {
  description = "Additional VPC associations to be created separately"
  type = list(object({
    vpc_id     = string
    vpc_region = string
  }))
  default = []
}

# DNS Records Configuration
variable "public_records" {
  description = "DNS records for the public hosted zone"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
    weighted_routing_policy = optional(object({
      weight = number
    }))
    latency_routing_policy = optional(object({
      region = string
    }))
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    failover_routing_policy = optional(object({
      type = string
    }))
    set_identifier  = optional(string)
    health_check_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in var.public_records : contains([
        "A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SPF", "SRV", "TXT"
      ], record.type)
    ])
    error_message = "Record type must be one of: A, AAAA, CNAME, MX, NS, PTR, SOA, SPF, SRV, TXT."
  }
}

variable "private_records" {
  description = "DNS records for the private hosted zone"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in var.private_records : contains([
        "A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SPF", "SRV", "TXT"
      ], record.type)
    ])
    error_message = "Record type must be one of: A, AAAA, CNAME, MX, NS, PTR, SOA, SPF, SRV, TXT."
  }
}

# Route 53 Resolver Configuration (Hybrid DNS)
variable "resolver_inbound_enabled" {
  description = "Whether to create an inbound Route 53 resolver endpoint"
  type        = bool
  default     = false
}

variable "resolver_outbound_enabled" {
  description = "Whether to create an outbound Route 53 resolver endpoint"
  type        = bool
  default     = false
}

variable "resolver_inbound_name" {
  description = "Name for the inbound resolver endpoint"
  type        = string
  default     = "inbound-resolver"
}

variable "resolver_outbound_name" {
  description = "Name for the outbound resolver endpoint"
  type        = string
  default     = "outbound-resolver"
}

variable "resolver_security_group_ids" {
  description = "Security group IDs for the resolver endpoints"
  type        = list(string)
  default     = []
}

variable "resolver_tags" {
  description = "Additional tags for resolver resources"
  type        = map(string)
  default     = {}
}

variable "resolver_inbound_ip_addresses" {
  description = "IP addresses for the inbound resolver endpoint"
  type = list(object({
    subnet_id = string
    ip        = optional(string)
  }))
  default = []
}

variable "resolver_outbound_ip_addresses" {
  description = "IP addresses for the outbound resolver endpoint"
  type = list(object({
    subnet_id = string
    ip        = optional(string)
  }))
  default = []
}

# Resolver Rules Configuration
variable "resolver_rules" {
  description = "Route 53 resolver rules for forwarding DNS queries"
  type = map(object({
    domain_name = string
    name        = string
    rule_type   = string
    target_ips = optional(list(object({
      ip   = string
      port = optional(number, 53)
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in var.resolver_rules : contains(["FORWARD", "SYSTEM", "RECURSIVE"], rule.rule_type)
    ])
    error_message = "Rule type must be one of: FORWARD, SYSTEM, RECURSIVE."
  }
}

variable "resolver_rule_associations" {
  description = "Associations between resolver rules and VPCs"
  type = map(object({
    rule_key = string
    vpc_id   = string
  }))
  default = {}
}

# Health Checks Configuration
variable "health_checks" {
  description = "Route 53 health checks"
  type = map(object({
    fqdn                            = string
    port                            = optional(number, 80)
    type                            = optional(string, "HTTP")
    resource_path                   = optional(string, "/")
    failure_threshold               = optional(number, 3)
    request_interval                = optional(number, 30)
    cloudwatch_logs_region          = optional(string)
    cloudwatch_logs_log_group_name  = optional(string)
    insufficient_data_health_status = optional(string, "Failure")
    invert_healthcheck              = optional(bool, false)
    measure_latency                 = optional(bool, false)
    enable_sni                      = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for hc in var.health_checks : contains([
        "HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH", "TCP", "CALCULATED", "CLOUDWATCH_METRIC"
      ], hc.type)
    ])
    error_message = "Health check type must be one of: HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC."
  }
}

variable "health_check_tags" {
  description = "Additional tags for health check resources"
  type        = map(string)
  default     = {}
}
