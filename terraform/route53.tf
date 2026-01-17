# Route53 DNS records for frontend applications
# Creates alias records pointing to CloudFront distributions

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