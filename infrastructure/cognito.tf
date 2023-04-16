# Cognito
resource "aws_cognito_user_pool" "user_pool" {
  name                     = "${var.project_name}-user-pool"
  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "app_client" {
  name            = "${var.project_name}-client"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = true

  explicit_auth_flows = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name = "${var.project_name}-identity-pool"

  cognito_identity_providers {
    provider_name = "cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
    client_id     = aws_cognito_user_pool_client.app_client.id
  }
}

# resource "aws_cognito_identity_pool_roles_attachment" "main" {
#   identity_pool_id = aws_cognito_identity_pool.identity_pool.id

#   role_mapping {
#     identity_provider         = "graph.facebook.com"
#     type                      = "Rules"

#     mapping_rule {
#       claim      = "isAdmin"
#       match_type = "Equals"
#       role_arn   = aws_iam_role.authenticated.arn
#       value      = "paid"
#     }
#   }

#   roles = {
#     "authenticated" = aws_iam_role.authenticated.arn
#   }
# }