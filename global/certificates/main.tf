provider "aws" {
    region = "eu-west-1"
}

terraform {
    backend "s3" {
        bucket = "customer-terraform-state-file"
        key = "global/certificates/terraform.tfstate"
        region = "eu-west-1"

        dynamodb_table = "customer-terraform-locks"
        encrypt = true

    }

}

data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    bucket = "customer-terraform-state-file"
    key = "global/dns/terraform.tfstate"
    region = "eu-west-1"
  }

}


resource "aws_acm_certificate" "webserver_alb_cert" {
  domain_name       = "*.rgrhodesdev.co.uk"
  subject_alternative_names = ["rgrhodesdev.co.uk"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "webserver_alb_cert_validation" {
  name    = aws_acm_certificate.webserver_alb_cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.webserver_alb_cert.domain_validation_options.0.resource_record_type
  zone_id = data.terraform_remote_state.dns.outputs.hosted_zone_id
  records = [aws_acm_certificate.webserver_alb_cert.domain_validation_options.0.resource_record_value]
  ttl     = 300
}
