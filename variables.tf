variable "vpc-cidr" {
  default     = "10.10.10.0/24"
  description = "VPC CIDR Block"
  type        = string
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_classiclink" {
  description = "Should be true to enable ClassicLink for the VPC. Only valid in regions and accounts that support EC2 Classic."
  type        = bool
  default     = false
}

variable "public-subnet-1-cidr" {
  default     = "10.10.10.0/26"
  description = "Public Subnet 1 CIDR Block"
  type        = string
}

variable "public-subnet-2-cidr" {
  default     = "10.10.10.128/26"
  description = "Public Subnet 2 CIDR Block"
  type        = string
}

variable "private-subnet-1-cidr" {
  default     = "10.10.10.192/26"
  description = "Private Subnet 1 CIDR Block"
  type        = string
}

variable "ssh-location" {
  default     = "0.0.0.0/0"
  description = "IP address that can SSH into the EC2 Instance"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = string
  default     = "Vpc-custom-demo"
}

variable "user_names" {
  description = "IAM usernames"
  type        = list(any)
  default     = ["user1", "user2", "user3"]
} 