output "webserver_alb_cert_arn" {

  value       = aws_acm_certificate.webserver_alb_cert.arn
  description = "Certificate Arn"

}
