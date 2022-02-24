# Manages a Route53 Hosted Zone
resource "aws_route53_zone" "devops_aws" {
  name = "example-website.in"

  tags = {
    Environment = "dev"
  }
}
# Provides a Route53 record resource
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.devops_aws.zone_id
  name    = "www.example-website.in"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.nat_eip.public_ip]
}

output "name_server" {
  value = aws_route53_zone.devops_aws.name_servers
}