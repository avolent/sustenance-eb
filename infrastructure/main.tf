# App S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "sustenance-app"
}

# App Files to be stored in S3 bucket
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "beanstalk/app-${var.commit_id}.zip"
  source = "../app.zip"
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = "sustenance"
  description = "Sustenance on the web"
}

# Elastic Beanstalk App Version
resource "aws_elastic_beanstalk_application_version" "version" {
  bucket      = aws_s3_bucket.bucket.id
  key         = aws_s3_object.object.id
  application = aws_elastic_beanstalk_application.app.name
  name        = var.commit_id

  lifecycle {
    prevent_destroy = true
  }
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "sustenance-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Python 3.8"
  description         = "Sustenance Enviroment"
  version_label       = aws_elastic_beanstalk_application_version.version.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }
}