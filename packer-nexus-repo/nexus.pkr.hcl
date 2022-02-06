locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "region" {}
variable "ami_regions" {}
variable "instance_type" {}
variable "tags" {}

source "amazon-ebs" "nexus-oss" {
  ami_name      = "nexus-oss"
  instance_type = var.instance_type
  region        = var.region
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
  sources = ["source.amazon-ebs.nexus-oss"]

  provisioner "file" {
    source      = "./nexus.rc"
    destination = "/tmp/nexus.rc"
  }

  provisioner "file" {
    source      = "./repository.json"
    destination = "/tmp/repository.json"
  }

  provisioner "shell" {
    script          = "./setup.sh"
    execute_command = "sudo -E -S sh {{ .Path }}"
  }
}