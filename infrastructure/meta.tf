terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "avolent-terraform-state"
    key    = "sustenance-tfstate"
    region = "ap-southeast-2"
  }
}