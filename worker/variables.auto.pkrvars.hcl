region = "eu-north-1"

ami_regions = ["eu-north-1"]

instance_type = "t3.micro"

tags = {
  "Name"        = "Jenkins Server Worker"
  "Environment" = "Production"
  "OS_Version"  = "Amazon Linux 2"
  "Release"     = "Latest"
  "Created-by"  = "Packer"
}

source_ami = "ami-067a92fcca2611950"