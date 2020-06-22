variable "server_port" {
  description = "Web Server Port"
  type        = number
}

variable "http_alb_port" {
  description = "HTTP ALB Port"
  type        = number
}

variable "https_alb_port" {
  description = "HTTPS ALB Port"
  type        = number
}

variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "dns_remote_state_bucket" {
  description = "The name of the S3 bucket for the certificates remote state"
  type        = string
}

variable "dns_remote_state_key" {
  description = "The path for the certificates remote state in S3"
  type        = string
}

variable "certificates_remote_state_bucket" {
  description = "The name of the S3 bucket for the certificates remote state"
  type        = string
}

variable "certificates_remote_state_key" {
  description = "The path for the certificates remote state in S3"
  type        = string
}

variable "vpc_remote_state_bucket" {
  description = "The name of the S3 bucket for the vpc remote state"
  type        = string
}

variable "vpc_remote_state_key" {
  description = "The path for the vpc remote state in S3"
  type        = string
}

variable "environment" {
  description = "Environment Type"
  type        = string
}

variable "web_ami_id" {
  description = "AMI ID"
  type        = string

}

variable "web_instance_type" {
  description = "Instance Type"
  type        = string
}

variable "web_asg_min" {
  description = "Minimum Number of Web Instances"
  type        = number
}

variable "web_asg_max" {
  description = "Maximum Number of Web Instances"
  type        = number
}