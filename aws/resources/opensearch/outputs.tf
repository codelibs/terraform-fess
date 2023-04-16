output "domain_id" {
  value = aws_opensearch_domain.search_domain.domain_id
}

output "domain_name" {
  value = aws_opensearch_domain.search_domain.domain_name
}

output "domain_arn" {
  value = aws_opensearch_domain.search_domain.arn
}

output "endpoint" {
  value = aws_opensearch_domain.search_domain.endpoint
}

output "dashboard_endpoint" {
  value = aws_opensearch_domain.search_domain.dashboard_endpoint
}

output "master_user_password" {
  value = random_password.master_user_password.result
  sensitive = true
}
