#!/bin/bash
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "<h2>Hello and Welcome to my Web Front End</h2><p>Environment: ${app_env}</p>" > /var/www/html/index.html

