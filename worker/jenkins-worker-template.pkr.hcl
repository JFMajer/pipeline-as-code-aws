locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "region" {}
variable "ami_regions" {}
variable "instance_type" {}
variable "tags" {}
variable "source_ami" {}
//variable "aws_profile" {}

source "amazon-ebs" "amazon-linux-ami" {
  ami_name      = "jenkins-worker-${local.timestamp}"
  instance_type = var.instance_type
  region        = var.region
  ami_regions   = var.ami_regions
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-kernel-5.10-hvm-2.0.*.0-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"]
    most_recent = true
  }
  ssh_username = "ec2-user"
  tags         = var.tags
}

build {
  sources = ["source.amazon-ebs.amazon-linux-ami"]

  provisioner "shell" {
    script          = "./setup.sh"
    execute_command = "sudo -E -S sh {{ .Path }}"
  }
}