resource "aws_vpc" "vpc" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-igw"
  }
}

resource "aws_subnet" "subnet_services" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.3.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-central-1b"

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-services"
  }
}

resource "aws_subnet" "subnet_clients" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.3.32.0/19"
  map_public_ip_on_launch = false
  availability_zone       = "eu-central-1c"

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-clients"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-rt"
  }
}

resource "aws_route_table_association" "rta_subnet_services" {
  subnet_id      = aws_subnet.subnet_services.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "rta_subnet_clients" {
  subnet_id      = aws_subnet.subnet_clients.id
  route_table_id = aws_route_table.route_table.id
}

# Services security group

resource "aws_security_group" "sg_services" {
  name   = "${var.environment_name}-services"
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-services"
  }
}

resource "aws_security_group_rule" "sg_services_ingress_self" {
  description       = "Local traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.sg_services.id
}

resource "aws_security_group_rule" "sg_services_ingress_clients" {
  description       = "Local VPC traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sg_services.id
  source_security_group_id = aws_security_group.sg_clients.id
}

resource "aws_security_group_rule" "sg_services_egress_all" {
  description       = "Outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_services.id
}

resource "aws_security_group_rule" "sg_services_ingress_toscalicense_server" {
  description       = "Tosca license server"
  type              = "ingress"
  from_port         = 7070
  to_port           = 7070
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_services.id
}

# Clients security group

resource "aws_security_group" "sg_clients" {
  name   = "${var.environment_name}-clients"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-clients"
  }
}

# Security group

resource "aws_security_group_rule" "sg_clients_ingress_self" {
  description       = "Local traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.sg_clients.id
}

resource "aws_security_group_rule" "sg_clients_ingress_services" {
  description       = "Local VPC traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sg_clients.id
  source_security_group_id = aws_security_group.sg_services.id
}

resource "aws_security_group_rule" "sg_clients_egress_all" {
  description       = "Outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_clients.id
}

resource "aws_security_group_rule" "sg_clients_ingress_toscalicense_server" {
  description       = "Tosca license server"
  type              = "ingress"
  from_port         = 7070
  to_port           = 7070
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_clients.id
}