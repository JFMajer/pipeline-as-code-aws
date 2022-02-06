region = "eu-north-1"

ami_regions = ["eu-north-1"]

instance_type = "t3.micro"

tags = {
  "Name"        = "Nexus Repository OSS"
  "Environment" = "Production"
  "OS_Version"  = "Amazon Linux 2"
  "Release"     = "Latest"
  "Created-by"  = "Packer"
}

private_key_path = "~/.ssh/id_rsa"