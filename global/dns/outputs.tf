output "hosted_zone_id" {

  value       = aws_route53_zone.public.zone_id
  description = "The hosted zone id"

}

output name_servers {

  value       = aws_route53_zone.public.*.name_servers
  description = "Name Servers associated with the hosted zone"

}