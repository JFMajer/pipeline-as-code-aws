region = "eu-north-1"

ami_regions = ["eu-north-1"]

instance_type = "t3.micro"

tags = {
  "Name"        = "Jenkins Server Master"
  "Environment" = "Production"
  "OS_Version"  = "Amazon Linux 2"
  "Release"     = "Latest"
  "Created-by"  = "Packer"
}

private_key_path = "/home/kuba/.ssh/id_rsa"
