# Data
data "aws_route53_zone" "hosted_zone" {
  name = "${var.root_domain}."
}

# Domain Settings
resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = "${var.sub_domain}.avolent.cloud"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_elastic_beanstalk_environment.env.endpoint_url
  ]
}

resource "aws_route53_record" "www_record" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = "www.${var.sub_domain}.avolent.cloud"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_elastic_beanstalk_environment.env.endpoint_url
  ]
}

# HTTPS Setup
resource "aws_acm_certificate" "https_certificate" {
  domain_name       = var.root_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.root_domain}",
    "${var.sub_domain}.${var.root_domain}",
    "www.${var.sub_domain}.${var.root_domain}"
  ]

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_route53_record" "validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.https_certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = dvo.domain_name == var.root_domain ? data.aws_route53_zone.hosted_zone.zone_id : data.aws_route53_zone.hosted_zone.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.https_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_records : record.fqdn]
}