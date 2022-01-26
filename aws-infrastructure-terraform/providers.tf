terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "vscode"
}