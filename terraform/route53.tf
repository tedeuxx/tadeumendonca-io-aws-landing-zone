# Route53 DNS records for frontend applications and API endpoints
# Creates alias records pointing to CloudFront distributions and API Gateway

############################
# FRONTEND DNS RECORDS
############################

# Route53 A records for frontend applications (alias to CloudFront)
resource "aws_route53_record" "frontend_apps" {
  for_each = var.create_cloudfront_distributions ? local.app_env_combinations : {}

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.fqdn
  type    = "A"

  alias {
    name                   = module.cloudfront[each.key].cloudfront_distribution_domain_name
    zone_id                = module.cloudfront[each.key].cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

############################
# API DNS RECORDS
############################

# Route53 A records for API Gateway custom domains
resource "aws_route53_record" "api_domains" {
  for_each = toset(var.workload_environments)

  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.api_domain_names[each.value]
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.main[each.value].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main[each.value].regional_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_api_gateway_domain_name.main]
}