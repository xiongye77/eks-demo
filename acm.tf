data "aws_route53_zone" "public" {
  name         = var.demo_dns_zone
  private_zone = false
  provider     = aws.account_route53
}


resource "aws_acm_certificate" "myapp_alb" {
  #provider          = "aws.acm_provider"
  domain_name       = "${var.demo_dns_name}.${data.aws_route53_zone.public.name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}



# This is a DNS record for the ACM certificate validation to prove we own the domain
#
# This example, we make an assumption that the certificate is for a single domain name so can just use the first value of the
# domain_validation_options.  It allows the terraform to apply without having to be targeted.
# This is somewhat less complex than the example at https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
# - that above example, won't apply without targeting

resource "aws_route53_record" "cert_validation_alb" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.myapp_alb.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.myapp_alb.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.myapp_alb.domain_validation_options)[0].resource_record_type
  zone_id  = data.aws_route53_zone.public.id
  ttl      = 60
  provider = aws.account_route53
}
