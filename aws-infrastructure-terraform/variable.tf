variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "name_prefix" {
  type    = string
  default = "pac_jenkins"
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "public_subnets_count" {
  type    = number
  default = 2
}

variable "private_subnets_count" {
  type    = number
  default = 2
}

variable "availability_zones" {
  type    = list(any)
  default = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = "jenkins-key"
}

variable "bastion_sg_name" {
  type    = string
  default = "pac-jenkins-bastion-sg"
}


variable "jenkins-master_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "jenkins-master_sg_name" {
  type    = string
  default = "pac-jenkins-master-sg"
}

variable "bastion_allowed_cidr" {}
variable "master_allowed_cidr" {}
variable "ssl_arn" {}
variable "domain_name" {}
variable "hosted_zone_id" {}
variable "public_key_path" {}

variable "worker_instance_type" {
  type    = string
  default = "t3.medium"
}