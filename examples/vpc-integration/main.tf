# VPC Integration Example
# This example demonstrates DNS integration with VPC resources including EC2 instances

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

# Create VPC for DNS integration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    Purpose     = "DNS integration example"
  }
}

# Create subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "public"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
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

# Security groups
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-db-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
  }
}

# EC2 instances
resource "aws_instance" "web" {
  count = var.web_instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.web_instance_type
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name

  user_data = base64encode(templatefile("${path.module}/web_user_data.sh", {
    instance_name = "web-${count.index + 1}"
    domain_name   = var.private_domain_name
  }))

  tags = {
    Name        = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
    Role        = "web"
  }
}

resource "aws_instance" "database" {
  count = var.db_instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.db_instance_type
  subnet_id              = aws_subnet.private[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name               = var.key_name

  user_data = base64encode(templatefile("${path.module}/db_user_data.sh", {
    instance_name = "db-${count.index + 1}"
    domain_name   = var.private_domain_name
  }))

  tags = {
    Name        = "${var.environment}-db-${count.index + 1}"
    Environment = var.environment
    Role        = "database"
  }
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${var.environment}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "${var.environment}-web-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name        = "${var.environment}-web-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count = length(aws_instance.web)

  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# DNS Configuration
module "vpc_dns" {
  source = "../../"

  # Public zone for external access
  domain_name         = var.public_domain_name
  public_zone_enabled = true

  # Public records pointing to ALB
  public_alias_records = {
    root = {
      name                   = ""
      type                   = "A"
      alias_name             = aws_lb.web.dns_name
      alias_zone_id          = aws_lb.web.zone_id
      evaluate_target_health = true
    }

    www = {
      name                   = "www"
      type                   = "A"
      alias_name             = aws_lb.web.dns_name
      alias_zone_id          = aws_lb.web.zone_id
      evaluate_target_health = true
    }
  }

  # Private zone for internal communication
  private_zone_enabled = true
  private_domain_name  = var.private_domain_name

  private_zone_vpc_associations = [
    {
      vpc_id  = aws_vpc.main.id
      comment = "Main VPC association"
    }
  ]

  # Private records for internal services
  private_records = {
    # Web servers
    web_1 = length(aws_instance.web) > 0 ? {
      name    = "web-1"
      type    = "A"
      ttl     = 300
      records = [aws_instance.web[0].private_ip]
    } : null

    web_2 = length(aws_instance.web) > 1 ? {
      name    = "web-2"
      type    = "A"
      ttl     = 300
      records = [aws_instance.web[1].private_ip]
    } : null

    # Database servers
    db_primary = length(aws_instance.database) > 0 ? {
      name    = "db-primary"
      type    = "A"
      ttl     = 300
      records = [aws_instance.database[0].private_ip]
    } : null

    db_replica = length(aws_instance.database) > 1 ? {
      name    = "db-replica"
      type    = "A"
      ttl     = 300
      records = [aws_instance.database[1].private_ip]
    } : null

    # Service aliases
    database = length(aws_instance.database) > 0 ? {
      name    = "database"
      type    = "CNAME"
      ttl     = 300
      records = ["db-primary.${var.private_domain_name}"]
    } : null

    # Load balancer internal
    lb_internal = {
      name    = "lb-internal"
      type    = "A"
      ttl     = 300
      records = [aws_lb.web.dns_name]
    }
  }

  # Tags
  tags = {
    Name        = "VPC DNS Integration"
    Environment = var.environment
    VPC         = aws_vpc.main.id
  }
}
