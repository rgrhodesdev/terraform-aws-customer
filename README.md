# terraform-aws-customer

Autoscaled Webserver deployment to support simple front end on Apache web server.

Consists of reusable Terraform modules to deploy VPC and Services creating seperate environments
e.g. Prod, Stage in the same AWS account.

Global modules used to configure terraform backend state storage in S3, create Route53 hosted zone and create SSL certifciate for ASG ALB.


