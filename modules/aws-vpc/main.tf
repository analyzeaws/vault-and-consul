provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  required_version = ">= 0.9.3"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "${cidrsubnet(var.cidr_block, 0, 0)}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-internet-gateway"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "public_routetable" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags {
    Name        = "${var.environment}-public-routetable"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(var.cidr_block, 8, count.index)}"
  availability_zone       = "${element(var.availability_zones[var.aws_region], count.index)}"
  map_public_ip_on_launch = "${var.public_subnet_map_public_ip_on_launch}"
  count                   = "${length(var.availability_zones[var.aws_region])}"

  tags {
    Name        = "${var.environment}-${element(var.availability_zones[var.aws_region], count.index)}-public"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "public_routing_table" {
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_routetable.id}"
  count          = "${length(var.availability_zones[var.aws_region])}"
}

resource "aws_route_table" "private_routetable" {
  count  = "${var.create_private_subnets ? 1 : 0}"
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }

  tags {
    Name        = "${var.environment}-private-routetable"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(var.cidr_block, 8, length(var.availability_zones[var.aws_region]) + count.index)}"
  availability_zone       = "${element(var.availability_zones[var.aws_region], count.index)}"
  map_public_ip_on_launch = false
  count                   = "${var.create_private_subnets ? length(var.availability_zones[var.aws_region]) : 0}"

  tags {
    Name        = "${var.environment}-${element(var.availability_zones[var.aws_region], count.index)}-private"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "private_routing_table" {
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private_routetable.id}"
  count          = "${var.create_private_subnets ? length(var.availability_zones[var.aws_region]) : 0}"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  count         = "${var.create_private_subnets ? 1 : 0}"
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_subnet.0.id}"
}

resource "aws_route53_zone" "local" {
  count   = "${var.create_private_hosted_zone ? 1 : 0}"
  name    = "${var.environment}.local"
  comment = "${var.environment} - route53 - local hosted zone"

  tags {
    Name        = "${var.environment}-route53-private-hosted-zone"
    Environment = "${var.environment}"
  }

  vpc_id = "${aws_vpc.vpc.id}"
}
