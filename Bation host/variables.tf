#vpc variables

variable "vpc_cid" {
    default = "192.168.0.0/16"
}

variable "public_subnet_cid" {
    default = "192.168.1.0/24"
}

variable "private_subnet_cid" {
    default = "192.168.2.0/24"
}

variable "region" {
    default = "us-east-1"
}

# bastion ec2 instance variables

variable "ec2_ami" {
    default = "ami-0953476d60561c955" # Amazon Linux 2 AMI
}

variable "ec2_instance_type" {
    default = "t2.micro"
}

variable "key_name" {
    default = "aws-key"
}

variable "allowed_ssh_ip" {
    default = "your ip"
  
}