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

variable "web_server_ip" {
  description = "IP address of the web server"
  type        = string
  default     = "192.0.2.1"
  
  validation {
    condition     = can(cidrhost("${var.web_server_ip}/32", 0))
    error_message = "Web server IP must be a valid IPv4 address."
  }
}

variable "api_server_ip" {
  description = "IP address of the API server"
  type        = string
  default     = "192.0.2.2"
  
  validation {
    condition     = can(cidrhost("${var.api_server_ip}/32", 0))
    error_message = "API server IP must be a valid IPv4 address."
  }
}

variable "mail_server_ip" {
  description = "IP address of the primary mail server"
  type        = string
  default     = "192.0.2.10"
  
  validation {
    condition     = can(cidrhost("${var.mail_server_ip}/32", 0))
    error_message = "Mail server IP must be a valid IPv4 address."
  }
}

variable "mail_server_backup_ip" {
  description = "IP address of the backup mail server"
  type        = string
  default     = "192.0.2.11"
  
  validation {
    condition     = can(cidrhost("${var.mail_server_backup_ip}/32", 0))
    error_message = "Backup mail server IP must be a valid IPv4 address."
  }
}
