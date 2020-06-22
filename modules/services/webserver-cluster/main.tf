# Webcluster Module deploys the following infrastructure:
# Application Load Balancer, listeners (HTTP/HTTPS) and rules
# Listener Target Group
# Auto Scaling Group with associated Launch Configuration
# Instance and ALB security group rules
# Environment Route53 record

# Reference Route53 outputs from dns module state

data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    bucket = var.dns_remote_state_bucket
    key    = var.dns_remote_state_key
    region = "eu-west-1"
  }

}

#  Reference Certifcate Manager outputs from certificates module state

data "terraform_remote_state" "certificates" {
  backend = "s3"

  config = {
    bucket = var.certificates_remote_state_bucket
    key    = var.certificates_remote_state_key
    region = "eu-west-1"
  }

}

#  Reference VPC outputs from vpc module state

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state_bucket
    key    = var.vpc_remote_state_key
    region = "eu-west-1"
  }

}

# Define Template file for instance userdata

data "template_file" "user_data" {

  template = file("${path.module}/user-data.sh")

  vars = {
    app_env = var.environment

  }

}

# Deploy AWS ALB to public subnets to allow external access

resource "aws_lb" "web" {

  name               = "${var.cluster_name}-web-${var.environment}"
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

}

# Default listener for http. Default rule to direct all traffic to https.

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

# Listener for https to support SSL offload on the ALB. Certificate Arn reference from global/certificates state

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

# https listener rule to forward to webserver target group

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

# Target group for webserver instances. Instances are scaled in/out of target group viz ASG.
# Traffic will be forwarded to the instances on port 80.

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


# AWS Launch Configuration for webserver auto scaling group.
# user data defined in template file user-data.sh

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

# AWS autoscaling group for web servers
# Instances will be scaled into the ALB defined above.
# Instances will be scaled across into private subnets across all eu-west-1 AZs
# Health check configured as ELB. This will mean if an instance fails the target group health check
# It will be terminated and replaced

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

# Define Security Groups and Rules


# Webserver instance Security Group

resource "aws_security_group" "instance" {

  name   = "${var.cluster_name}-instance-${var.environment}"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id


}

# Webserver instance rule. Allow inbound access on port 80 from the ALB security group

resource "aws_security_group_rule" "allow_instance_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port                = var.server_port
  to_port                  = var.server_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id

}

# Webserver instance rule. Allow outbound - All

resource "aws_security_group_rule" "allow_instance_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]

}

# ALB instance Security Group

resource "aws_security_group" "alb" {

  name   = "${var.cluster_name}-alb-${var.environment}"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

# ALB rule. Allow inbound on port 80.

resource "aws_security_group_rule" "allow_alb_inbound_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = var.http_alb_port
  to_port     = var.http_alb_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

# ALB rule. Allow inbound on port 443.

resource "aws_security_group_rule" "allow_alb_inbound_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = var.https_alb_port
  to_port     = var.https_alb_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

# ALB rule. Allow outbound - All

resource "aws_security_group_rule" "allow_alb_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]

}

# The DNS records created depend on the environment being deployed.
# If the environment variable = prod then the following record is created.

resource "aws_route53_record" "www" {
  count = var.environment == "prod" ? 1 : 0

  zone_id = data.terraform_remote_state.dns.outputs.hosted_zone_id
  name    = "www.rgrhodesdev.co.uk"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.web.dns_name]
}

# If the environment variable != prod then the following record is created.
# The subdoamin will depend on the environment begin created.
# For example environment = stage will create the following record.
# stage.rgrhodesdev.co.uk

resource "aws_route53_record" "lower_envs" {
  count = var.environment != "prod" ? 1 : 0

  zone_id = data.terraform_remote_state.dns.outputs.hosted_zone_id
  name    = "${var.environment}.rgrhodesdev.co.uk"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.web.dns_name]
}




