data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    bucket = var.dns_remote_state_bucket
    key    = var.dns_remote_state_key
    region = "eu-west-1"
  }

}

data "terraform_remote_state" "certificates" {
  backend = "s3"

  config = {
    bucket = var.certificates_remote_state_bucket
    key    = var.certificates_remote_state_key
    region = "eu-west-1"
  }

}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state_bucket
    key    = var.vpc_remote_state_key
    region = "eu-west-1"
  }

}

data "template_file" "user_data" {

  template = file("${path.module}/user-data.sh")

  vars = {
    app_env = var.environment

  }

}

resource "aws_lb" "web" {

  name               = "${var.cluster_name}-web-${var.environment}"
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

}

# Default listener for http redirects to port https

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.web.arn
  port              = var.http_alb_port
  protocol          = "HTTP"

  default_action {

    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

  }

}

resource "aws_lb_listener" "https" {

  load_balancer_arn = aws_lb.web.arn
  port              = var.https_alb_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.terraform_remote_state.certificates.outputs.webserver_alb_cert_arn

  default_action {

    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page Not Found"
      status_code  = 404

    }

  }

}


resource "aws_lb_listener_rule" "asg_https" {

  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {

    field  = "path-pattern"
    values = ["*"]

  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn

  }

}

resource "aws_lb_target_group" "asg" {

  name     = "${var.cluster_name}-web-${var.environment}"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

}




resource "aws_launch_configuration" "web" {

  image_id                    = var.web_ami_id
  instance_type               = var.web_instance_type
  security_groups             = [aws_security_group.instance.id]
  associate_public_ip_address = false

  user_data = data.template_file.user_data.rendered

  lifecycle {

    create_before_destroy = true

  }
}

resource "aws_autoscaling_group" "web" {

  launch_configuration = aws_launch_configuration.web.name
  vpc_zone_identifier  = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"

  min_size = var.web_asg_min
  max_size = var.web_asg_max

  tag {
    key                 = "Name"
    value               = "web-asg-${var.environment}"
    propagate_at_launch = true
  }

}

resource "aws_security_group" "instance" {

  name   = "${var.cluster_name}-instance-${var.environment}"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id


}

resource "aws_security_group_rule" "allow_instance_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port       = var.server_port
  to_port         = var.server_port
  protocol        = "tcp"
  source_security_group_id = aws_security_group.alb.id

}

resource "aws_security_group_rule" "allow_instance_outbound" {
  type = "egress"
  security_group_id = aws_security_group.instance.id

    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]

}



resource "aws_security_group" "alb" {

  name   = "${var.cluster_name}-alb-${var.environment}"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "allow_alb_inbound_http" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = var.http_alb_port
  to_port     = var.http_alb_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_security_group_rule" "allow_alb_inbound_https" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = var.https_alb_port
  to_port     = var.https_alb_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}



resource "aws_security_group_rule" "allow_alb_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]

}


resource "aws_route53_record" "www" {
  count = var.environment == "prod" ? 1 : 0

  zone_id = data.terraform_remote_state.dns.outputs.hosted_zone_id
  name    = "www.rgrhodesdev.co.uk"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.web.dns_name]
}

resource "aws_route53_record" "lower_envs" {
  count = var.environment != "prod" ? 1 : 0

  zone_id = data.terraform_remote_state.dns.outputs.hosted_zone_id
  name    = "${var.environment}.rgrhodesdev.co.uk"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.web.dns_name]
}




