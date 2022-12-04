output "The_route53_alb_dns_name" {
  value       =  "https://${var.demo_dns_name}.${data.aws_route53_zone.public.name}"
  description = "The route53 alb dns name"
}
