locals {
  env_name         = var.env_name
  app_name         = var.app_name
  tag_name         = "${var.env_name}-${var.app_name}"
  domain_name      = "${var.env_name}-${var.app_name}"
  master_user_name = var.opensearch.master_user_name
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_caller_identity" "current" {}

resource "random_password" "master_user_password" {
  length           = 16
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "!@#%&"
}

resource "aws_security_group" "sg" {
  name   = "${local.domain_name}-sg"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block,
    ]
  }
}

resource "aws_iam_service_linked_role" "svc_role" {
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "audit_logs" {
  name = "/aws/opensearch/${local.domain_name}/audit-logs"
}

resource "aws_cloudwatch_log_group" "index_slow_logs" {
  name = "/aws/opensearch/${local.domain_name}/index-slow-logs"
}

resource "aws_cloudwatch_log_group" "search_slow_logs" {
  name = "/aws/opensearch/${local.domain_name}/search-slow-logs"
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/aws/opensearch/${local.domain_name}/app-logs"
}

resource "aws_cloudwatch_log_resource_policy" "logs_policy" {
  policy_name = "${local.env_name}-${local.app_name}-logs-policy"

  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.audit_logs.arn}:*",
        "${aws_cloudwatch_log_group.index_slow_logs.arn}:*",
        "${aws_cloudwatch_log_group.search_slow_logs.arn}:*",
        "${aws_cloudwatch_log_group.app_logs.arn}:*"
      ]
    }
  ]
}
CONFIG
}

resource "aws_opensearch_domain" "search_domain" {
  domain_name    = local.domain_name
  engine_version = var.opensearch.engine_version

  cluster_config {
    instance_type          = var.opensearch.instance_type
    instance_count         = var.opensearch.instance_count
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = length(data.aws_subnets.subnets.ids)
    }
  }

  vpc_options {
    subnet_ids         = data.aws_subnets.subnets.ids
    security_group_ids = [aws_security_group.sg.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch.volume_size
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${var.aws.region}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}/*"
        }
    ]
}
CONFIG

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.audit_logs.arn
    log_type                 = "AUDIT_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.index_slow_logs.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.search_slow_logs.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.app_logs.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = local.master_user_name
      master_user_password = random_password.master_user_password.result
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Domain = local.domain_name
  }

  depends_on = [aws_iam_service_linked_role.svc_role]
}
