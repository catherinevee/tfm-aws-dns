# Multi-VPC DNS Integration Example
# This example demonstrates DNS resolution across multiple VPCs using private zones

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Production VPC
resource "aws_vpc" "production" {
  cidr_block           = var.production_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "production-vpc"
    Environment = "production"
    Purpose     = "Production workloads"
  }
}

# Development VPC
resource "aws_vpc" "development" {
  cidr_block           = var.development_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "development-vpc"
    Environment = "development"
    Purpose     = "Development workloads"
  }
}

# Shared Services VPC
resource "aws_vpc" "shared_services" {
  cidr_block           = var.shared_services_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "shared-services-vpc"
    Environment = "shared"
    Purpose     = "Shared services (DNS, monitoring, etc.)"
  }
}

# VPC Peering Connections
resource "aws_vpc_peering_connection" "prod_to_shared" {
  vpc_id      = aws_vpc.production.id
  peer_vpc_id = aws_vpc.shared_services.id
  auto_accept = true

  tags = {
    Name = "prod-to-shared-peering"
  }
}

resource "aws_vpc_peering_connection" "dev_to_shared" {
  vpc_id      = aws_vpc.development.id
  peer_vpc_id = aws_vpc.shared_services.id
  auto_accept = true

  tags = {
    Name = "dev-to-shared-peering"
  }
}

resource "aws_vpc_peering_connection" "prod_to_dev" {
  count = var.enable_cross_environment_peering ? 1 : 0

  vpc_id      = aws_vpc.production.id
  peer_vpc_id = aws_vpc.development.id
  auto_accept = true

  tags = {
    Name = "prod-to-dev-peering"
  }
}

# Subnets for Production VPC
resource "aws_subnet" "production_private" {
  count = length(var.production_private_cidrs)

  vpc_id            = aws_vpc.production.id
  cidr_block        = var.production_private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "production-private-${count.index + 1}"
    Environment = "production"
    Type        = "private"
  }
}

# Subnets for Development VPC
resource "aws_subnet" "development_private" {
  count = length(var.development_private_cidrs)

  vpc_id            = aws_vpc.development.id
  cidr_block        = var.development_private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "development-private-${count.index + 1}"
    Environment = "development"
    Type        = "private"
  }
}

# Subnets for Shared Services VPC
resource "aws_subnet" "shared_services_private" {
  count = length(var.shared_services_private_cidrs)

  vpc_id            = aws_vpc.shared_services.id
  cidr_block        = var.shared_services_private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "shared-services-private-${count.index + 1}"
    Environment = "shared"
    Type        = "private"
  }
}

# Route Tables for VPC Peering
resource "aws_route_table" "production_private" {
  vpc_id = aws_vpc.production.id

  route {
    cidr_block                = var.shared_services_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_shared.id
  }

  dynamic "route" {
    for_each = var.enable_cross_environment_peering ? [1] : []
    content {
      cidr_block                = var.development_vpc_cidr
      vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_dev[0].id
    }
  }

  tags = {
    Name = "production-private-rt"
  }
}

resource "aws_route_table" "development_private" {
  vpc_id = aws_vpc.development.id

  route {
    cidr_block                = var.shared_services_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.dev_to_shared.id
  }

  dynamic "route" {
    for_each = var.enable_cross_environment_peering ? [1] : []
    content {
      cidr_block                = var.production_vpc_cidr
      vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_dev[0].id
    }
  }

  tags = {
    Name = "development-private-rt"
  }
}

resource "aws_route_table" "shared_services_private" {
  vpc_id = aws_vpc.shared_services.id

  route {
    cidr_block                = var.production_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_shared.id
  }

  route {
    cidr_block                = var.development_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.dev_to_shared.id
  }

  tags = {
    Name = "shared-services-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "production_private" {
  count = length(aws_subnet.production_private)

  subnet_id      = aws_subnet.production_private[count.index].id
  route_table_id = aws_route_table.production_private.id
}

resource "aws_route_table_association" "development_private" {
  count = length(aws_subnet.development_private)

  subnet_id      = aws_subnet.development_private[count.index].id
  route_table_id = aws_route_table.development_private.id
}

resource "aws_route_table_association" "shared_services_private" {
  count = length(aws_subnet.shared_services_private)

  subnet_id      = aws_subnet.shared_services_private[count.index].id
  route_table_id = aws_route_table.shared_services_private.id
}

# Security Groups
resource "aws_security_group" "production_app" {
  name_prefix = "production-app-"
  vpc_id      = aws_vpc.production.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.production_vpc_cidr, var.shared_services_vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.production_vpc_cidr, var.shared_services_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "production-app-sg"
  }
}

resource "aws_security_group" "development_app" {
  name_prefix = "development-app-"
  vpc_id      = aws_vpc.development.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.development_vpc_cidr, var.shared_services_vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.development_vpc_cidr, var.shared_services_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "development-app-sg"
  }
}

resource "aws_security_group" "shared_services" {
  name_prefix = "shared-services-"
  vpc_id      = aws_vpc.shared_services.id

  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "tcp"
    cidr_blocks = [
      var.production_vpc_cidr,
      var.development_vpc_cidr,
      var.shared_services_vpc_cidr
    ]
  }

  ingress {
    from_port = 53
    to_port   = 53
    protocol  = "udp"
    cidr_blocks = [
      var.production_vpc_cidr,
      var.development_vpc_cidr,
      var.shared_services_vpc_cidr
    ]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.shared_services_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "shared-services-sg"
  }
}

# EC2 Instances
resource "aws_instance" "production_app" {
  count = var.production_instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.production_private[count.index % length(aws_subnet.production_private)].id
  vpc_security_group_ids = [aws_security_group.production_app.id]
  key_name               = var.key_name

  user_data = base64encode(templatefile("${path.module}/app_user_data.sh", {
    environment   = "production"
    instance_name = "prod-app-${count.index + 1}"
    domain_name   = var.shared_domain_name
  }))

  tags = {
    Name        = "production-app-${count.index + 1}"
    Environment = "production"
    Role        = "application"
  }
}

resource "aws_instance" "development_app" {
  count = var.development_instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.development_private[count.index % length(aws_subnet.development_private)].id
  vpc_security_group_ids = [aws_security_group.development_app.id]
  key_name               = var.key_name

  user_data = base64encode(templatefile("${path.module}/app_user_data.sh", {
    environment   = "development"
    instance_name = "dev-app-${count.index + 1}"
    domain_name   = var.shared_domain_name
  }))

  tags = {
    Name        = "development-app-${count.index + 1}"
    Environment = "development"
    Role        = "application"
  }
}

resource "aws_instance" "shared_services" {
  count = var.shared_services_instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.shared_services_private[count.index % length(aws_subnet.shared_services_private)].id
  vpc_security_group_ids = [aws_security_group.shared_services.id]
  key_name               = var.key_name

  user_data = base64encode(templatefile("${path.module}/shared_user_data.sh", {
    instance_name = "shared-${count.index + 1}"
    domain_name   = var.shared_domain_name
  }))

  tags = {
    Name        = "shared-services-${count.index + 1}"
    Environment = "shared"
    Role        = "shared-services"
  }
}

# Multi-VPC DNS Configuration
module "multi_vpc_dns" {
  source = "../../"

  # Shared private zone accessible from all VPCs
  private_zone_enabled = true
  private_domain_name  = var.shared_domain_name

  # Associate private zone with all VPCs
  private_zone_vpc_associations = [
    {
      vpc_id  = aws_vpc.production.id
      comment = "Production VPC association"
    },
    {
      vpc_id  = aws_vpc.development.id
      comment = "Development VPC association"
    },
    {
      vpc_id  = aws_vpc.shared_services.id
      comment = "Shared Services VPC association"
    }
  ]

  # DNS records for cross-VPC service discovery
  private_records = {
    # Production services
    prod_app_1 = length(aws_instance.production_app) > 0 ? {
      name    = "prod-app-1"
      type    = "A"
      ttl     = 300
      records = [aws_instance.production_app[0].private_ip]
    } : null

    prod_app_2 = length(aws_instance.production_app) > 1 ? {
      name    = "prod-app-2"
      type    = "A"
      ttl     = 300
      records = [aws_instance.production_app[1].private_ip]
    } : null

    # Development services
    dev_app_1 = length(aws_instance.development_app) > 0 ? {
      name    = "dev-app-1"
      type    = "A"
      ttl     = 300
      records = [aws_instance.development_app[0].private_ip]
    } : null

    dev_app_2 = length(aws_instance.development_app) > 1 ? {
      name    = "dev-app-2"
      type    = "A"
      ttl     = 300
      records = [aws_instance.development_app[1].private_ip]
    } : null

    # Shared services
    shared_dns = length(aws_instance.shared_services) > 0 ? {
      name    = "dns"
      type    = "A"
      ttl     = 300
      records = [aws_instance.shared_services[0].private_ip]
    } : null

    shared_monitoring = length(aws_instance.shared_services) > 1 ? {
      name    = "monitoring"
      type    = "A"
      ttl     = 300
      records = [aws_instance.shared_services[1].private_ip]
    } : null

    # Service aliases and load balancing
    production_cluster = length(aws_instance.production_app) > 0 ? {
      name    = "production"
      type    = "A"
      ttl     = 60
      records = [for instance in aws_instance.production_app : instance.private_ip]
    } : null

    development_cluster = length(aws_instance.development_app) > 0 ? {
      name    = "development"
      type    = "A"
      ttl     = 60
      records = [for instance in aws_instance.development_app : instance.private_ip]
    } : null

    # Cross-environment service discovery
    all_apps = {
      name = "all-apps"
      type = "A"
      ttl  = 60
      records = concat(
        [for instance in aws_instance.production_app : instance.private_ip],
        [for instance in aws_instance.development_app : instance.private_ip]
      )
    }

    # Environment-specific TXT records for service discovery
    prod_config = {
      name    = "_config.production"
      type    = "TXT"
      ttl     = 300
      records = ["env=production", "vpc=${aws_vpc.production.id}", "region=${var.aws_region}"]
    }

    dev_config = {
      name    = "_config.development"
      type    = "TXT"
      ttl     = 300
      records = ["env=development", "vpc=${aws_vpc.development.id}", "region=${var.aws_region}"]
    }

    shared_config = {
      name    = "_config.shared"
      type    = "TXT"
      ttl     = 300
      records = ["env=shared", "vpc=${aws_vpc.shared_services.id}", "region=${var.aws_region}"]
    }
  }

  # Tags
  tags = {
    Name        = "Multi-VPC DNS"
    Purpose     = "Cross-VPC service discovery"
    Environment = "multi-environment"
  }
}
