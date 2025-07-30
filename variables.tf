variable "aws_region" {
  default = "ap-south-2"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  default = "ap-south-2a"
}

variable "ami_id" {
  default = "ami-01c837d5176a7605d"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = "jenkins"
}
variable "private_key_path" {
  description = "Path to the private key for SSH connection"
  type        = string
  default     = "/home/ec2-user/terraform/terraform-jenkins-aws-ci/terraform-server.pem"
}

