# Data
data "aws_route53_zone" "hosted_zone" {
  name = "${var.root_domain}."
}

data "aws_s3_bucket" "sustenance_app" {
  bucket = "${var.project_name}-app"
}

data "aws_iam_role" "eb_service_role" {
  name = "aws-elasticbeanstalk-service-role"
}

# App Files to be stored in S3 bucket
resource "aws_s3_object" "object" {
  bucket = data.aws_s3_bucket.sustenance_app.bucket
  key    = "beanstalk/app-${var.commit_id}.zip"
  source = "../app.zip"
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.project_name
  description = "${var.project_name} on the web"

  appversion_lifecycle {
    service_role          = data.aws_iam_role.eb_service_role.arn
    max_count             = 1
    delete_source_from_s3 = true
  }
}

# Elastic Beanstalk App Version
resource "aws_elastic_beanstalk_application_version" "version" {
  bucket       = aws_s3_object.object.bucket
  key          = aws_s3_object.object.id
  application  = aws_elastic_beanstalk_application.app.name
  name         = var.commit_id
  description  = var.commit_description
  force_delete = "true"
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "${var.project_name}-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Python 3.8"
  description         = "${var.project_name} environment"
  version_label       = aws_elastic_beanstalk_application_version.version.name

  ## Environment Settings
  # Environment
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # Loadbalancer listeners
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "false"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = aws_acm_certificate.https_certificate.arn
  }

  # Logs
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "7"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "HealthStreamingEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "DeleteOnTerminate"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "RetentionInDays"
    value     = "7"
  }

  # Autoscaling
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  # VPC
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  # Instances
  setting {
    namespace = "aws:ec2:instances"
    name      = "EnableSpot"
    value     = "true"
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t3a.nano,t3.nano"
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "SpotMaxPrice"
    value     = "0.0066"
  }

  # Updating
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Sun:23:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ServiceRoleForManagedUpdates"
    value     = "AWSServiceRoleForElasticBeanstalkManagedUpdates"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  # Cognito Environment Variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_USER_POOL_ID"
    value     = aws_cognito_user_pool.user_pool.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_APP_CLIENT_ID"
    value     = aws_cognito_user_pool_client.app_client.id
  }

  # setting {
  #   namespace = "aws:elasticbeanstalk:application:environment"
  #   name      = "COGNITO_IDENTITY_POOL_ID"
  #   value     = aws_cognito_identity_pool.identity_pool.id
  # }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_REGION"
    value     = var.aws_region
  }
}

# Domain Settings
resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = "${var.sub_domain}.avolent.cloud"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_elastic_beanstalk_environment.env.endpoint_url
  ]
}

resource "aws_route53_record" "www_record" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = "www.${var.sub_domain}.avolent.cloud"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_elastic_beanstalk_environment.env.endpoint_url
  ]
}

# HTTPS Setup
resource "aws_acm_certificate" "https_certificate" {
  domain_name       = var.root_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.root_domain}",
    "${var.sub_domain}.${var.root_domain}",
    "www.${var.sub_domain}.${var.root_domain}"
  ]

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_route53_record" "validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.https_certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = dvo.domain_name == var.root_domain ? data.aws_route53_zone.hosted_zone.zone_id : data.aws_route53_zone.hosted_zone.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.https_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_records : record.fqdn]
}

# Cognito
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.project_name}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_domain" "app_domain" {
  domain       = var.project_name
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_pool_client" "app_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  allowed_oauth_flows_user_pool_client = "true"
  generate_secret                      = "true"
  callback_urls                        = ["https://${var.sub_domain}.${var.root_domain}/login/callback"]
  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_scopes                 = ["openid"]
  supported_identity_providers         = ["COGNITO"]
}

# resource "aws_cognito_identity_pool" "identity_pool" {
#   identity_pool_name = "${var.project_name}-identity-pool"

#   cognito_identity_providers {
#     provider_name = "cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
#     client_id     = aws_cognito_user_pool_client.app_client.id
#   }
#   Define roles for authenticated and unauthenticated users
#   roles {
#     authenticated = "arn:aws:iam::123456789012:role/my-authenticated-role"
#     unauthenticated = "arn:aws:iam::123456789012:role/my-unauthenticated-role"
#   }
# }
