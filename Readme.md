Terraform to provision an EC2 instance that is running NGINX. 

Not intended for production use, just showcasing.

## Usage

```hcl
# Create VPC
# terraform aws create vpc
terraform {

} 
locals {
  ssh_user           = "ubuntu"
  subnet_id_public_1 = aws_subnet.public-subnet-1.id
  subnet_id_public_2 = aws_subnet.public-subnet-2.id
  subnet_id_private  = aws_subnet.private-subnet-1.id
  key_name           = "devops"
  private_key_path   = "~/../../*.pem"
}

resource "aws_key_pair" "devops" {
  key_name   = "devops"
  public_key = "ssh-rsa AAAAA...."
}

# Create a VPC
resource "aws_vpc" "vpc_demo" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  enable_classiclink   = var.enable_classiclink

  tags = {
    Name = var.tags
  }
}

data "template_file" "user_data" {
  template = file("./userdata.yaml")
}

data "template_file" "private_key" {
  template = file("./userdata.yaml")
}

# Create Internet Gateway and Attach it to VPC
# terraform aws create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_demo.id

  tags = {
    Name = "Internet-Gateway-demo"
  }
}

# Create Public Subnet 1
# terraform aws create subnet
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.vpc_demo.id
  cidr_block              = var.public-subnet-1-cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "NAT-Gateway-EIP"
  }
}

# Single EIP associated with an instance
resource "aws_eip" "lb" {
  instance = aws_instance.nginx_public_1.id
  vpc      = true
}

# Create Public Subnet 2
# terraform aws create subnet
resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.vpc_demo.id
  cidr_block              = var.public-subnet-2-cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-2"
  }
}

# Public NAT
resource "aws_nat_gateway" "public_1" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public-subnet-1.id

  tags = {
    Name = "gw-NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# Create Route Table and Add Public Route
# terraform aws create route table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc_demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# Associate Public Subnet 1 to "Public Route Table"
# terraform aws associate subnet with route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

# Associate Public Subnet 2 to "Public Route Table"
# terraform aws associate subnet with route table
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}

# Create Private Subnet 1
# terraform aws create subnet
resource "aws_subnet" "private-subnet-1" {
  vpc_id                  = aws_vpc.vpc_demo.id
  cidr_block              = var.private-subnet-1-cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_instance" "nginx_public_1" {
  ami                         = "ami-04505e74c0741db8d"
  subnet_id                   = aws_subnet.public-subnet-1.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.devops.key_name
  vpc_security_group_ids      = [aws_security_group.nginx.id]
  user_data                   = <<EOT
#cloud-config
# update apt on boot
package_update: true
# install nginx
packages:
- nginx
write_files:
- content: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Welcome, NGINX</title>
      <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
      <style>
        html, body {
          background: #fff;
          height: 100%;
          width: 100%;
          padding: 0;
          margin: 0;
          display: flex;
          justify-content: center;
          align-items: center;
          flex-flow: column;
        }
        img { width: 250px; }
        svg { padding: 0 40px; }
        p {
          color: #309ec7;
          font-family: 'Courier New', Courier, monospace;
          text-align: center;
          padding: 10px 30px;
        }
      </style>
    </head>
    <body>
      <img src="https://parispeaceforum.org/wp-content/uploads/2021/10/NET-ZERO-SPACE-INITIATIVE-1.png">
      <h1>Hello World!</h1>
      <h3>This request was proxied from <strong>Amazon Web Services using Terraform<strong></h3>
    </body>
    </html>
  path: /usr/share/app/index.html
  permissions: '0644'
runcmd:
- cp /usr/share/app/index.html /var/www/html/index.html
EOT

  tags = {
    Name = "Nginx-01-public"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Public 1 EC2 Connected!!!'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.nginx_public_1.public_ip
      private_key = file("./devops_dec.pem")
    }
  }
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> private_ips.txt"
  }
}

resource "aws_instance" "nginx_public_2" {
  ami                         = "ami-04505e74c0741db8d"
  subnet_id                   = aws_subnet.public-subnet-2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.devops.key_name
  vpc_security_group_ids      = [aws_security_group.ssh-security-group.id]
  user_data                   = <<EOT
#cloud-config
# update apt on boot
package_update: true
# install nginx
packages:
- nginx
write_files:
- content: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Welcome, NGINX</title>
      <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
      <style>
        html, body {
          background: #fff;
          height: 100%;
          width: 100%;
          padding: 0;
          margin: 0;
          display: flex;
          justify-content: center;
          align-items: center;
          flex-flow: column;
        }
        img { width: 250px; }
        svg { padding: 0 40px; }
        p {
          color: #309ec7;
          font-family: 'Courier New', Courier, monospace;
          text-align: center;
          padding: 10px 30px;
        }
      </style>
    </head>
    <body>
      <img src="https://parispeaceforum.org/wp-content/uploads/2021/10/NET-ZERO-SPACE-INITIATIVE-1.png">
      <h1>Hello World!</h1>
      <h3>This request was proxied from <strong>Amazon Web Services using Terraform<strong></h3>
    </body>
    </html>
  path: /usr/share/app/index.html
  permissions: '0644'
runcmd:
- cp /usr/share/app/index.html /var/www/html/index.html
EOT

  tags = {
    Name = "Nginx-02-public"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Public 2 ec2 Connected!!!'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.nginx_public_2.public_ip
      private_key = file("./devops_dec.pem")
    }
  }
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> private_ips.txt"
  }
}

resource "aws_instance" "nginx_private" {
  ami                         = "ami-04505e74c0741db8d"
  subnet_id                   = local.subnet_id_private
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = aws_key_pair.devops.key_name
  vpc_security_group_ids      = [aws_security_group.nginx.id]
  user_data                   = data.template_file.user_data.rendered

  tags = {
    Name = "NGINX-ec2-Private"
  }
}
output "public_ip_1" {
  value = aws_instance.nginx_public_1.public_ip
}
output "public_ip_2" {
  value = aws_instance.nginx_public_2.public_ip
}
output "private_ip" {
  value = aws_instance.nginx_private.private_ip
}
output "print_the_names" {
  value = [for name in var.user_names : name]
}
```