locals {
  env_name       = var.env_name
  app_name       = var.app_name
  tag_name       = "${var.env_name}-${var.app_name}"
  s3_bucket_name = "${var.env_name}-${var.app_name}-vpc-logs"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc.cidr

  tags = {
    Name = local.tag_name
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws.azs[0]
  cidr_block        = cidrsubnet(var.vpc.cidr, 8, 0)
  tags = {
    Name = "${local.tag_name}-pub1"
    Tier = "Public"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws.azs[1]
  cidr_block        = cidrsubnet(var.vpc.cidr, 8, 1)
  tags = {
    Name = "${local.tag_name}-pub2"
    Tier = "Public"
  }
}

resource "aws_subnet" "public_1d" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws.azs[2]
  cidr_block        = cidrsubnet(var.vpc.cidr, 8, 2)
  tags = {
    Name = "${local.tag_name}-pub3"
    Tier = "Public"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws.azs[0]
  cidr_block        = cidrsubnet(var.vpc.cidr, 8, 3)
  tags = {
    Name = "${local.tag_name}-prv1"
    Tier = "Private"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws.azs[1]
  cidr_block        = cidrsubnet(var.vpc.cidr, 8, 4)
  tags = {
    Name = "${local.tag_name}-prv2"
    Tier = "Private"
  }
}

resource "aws_subnet" "private_1d" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws.azs[2]
  cidr_block        = cidrsubnet(var.vpc.cidr, 8, 5)
  tags = {
    Name = "${local.tag_name}-prv3"
    Tier = "Private"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.tag_name}-ig"
  }
}

resource "aws_eip" "nat_1a" {
  vpc = true
  tags = {
    Name = "${local.tag_name}-nat1"
  }
}

resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_1a.id
  tags = {
    Name = "${local.tag_name}-ng1"
  }
}

resource "aws_eip" "nat_1c" {
  vpc = true
  tags = {
    Name = "${local.tag_name}-nat2"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  subnet_id     = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c.id
  tags = {
    Name = "${local.tag_name}-ng2"
  }
}

resource "aws_eip" "nat_1d" {
  vpc = true
  tags = {
    Name = "${local.tag_name}-nat3"
  }
}

resource "aws_nat_gateway" "nat_1d" {
  subnet_id     = aws_subnet.public_1d.id
  allocation_id = aws_eip.nat_1d.id
  tags = {
    Name = "${local.tag_name}-ng3"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.tag_name}-rt-pub"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_1d.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.tag_name}-rt-prv1"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.tag_name}-rt-prv2"
  }
}

resource "aws_route_table" "private_1d" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.tag_name}-rt-prv3"
  }
}

resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}

resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_1c.id
}

resource "aws_route" "private_1d" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1d.id
  nat_gateway_id         = aws_nat_gateway.nat_1d.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}

resource "aws_route_table_association" "private_1d" {
  subnet_id      = aws_subnet.private_1d.id
  route_table_id = aws_route_table.private_1d.id
}

resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket        = local.s3_bucket_name
  force_destroy = true
  tags = {
    Name = local.tag_name
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_flow_log" "main_log" {
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
  log_format           = "$${version} $${account-id} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${tcp-flags} $${log-status}"

  tags = {
    Name = local.tag_name
  }
}
