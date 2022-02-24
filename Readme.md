Terraform modules to provision an EC2 instance that is running Apache. 

Not intended for production use, just showcasing.

## Usage

```hcl
terraform {
  
}

provider "aws" {
  region = "us-east-1"
}

module "apache" {
  source          = ".//terraform-aws-apache-example"
  vpc_id          = "vpc-00000000"
  my_ip_with_cidr = "<own_ip>/32"
  public_key      = "ssh-rsa AAAAAAAA....."
  instance_type   = "t2.micro"
  server_name     = "Apache Example Server"

}

output "public_ip" {
  value = module.apache.public_ip
}
```# terraform-vpc
