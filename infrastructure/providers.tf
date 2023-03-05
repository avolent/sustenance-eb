provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Environment = "Prod"
      Project     = "Sustenance"
    }
  }
}