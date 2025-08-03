resource "auth0_resource_server" "auth0_api" {
  name                 = "Distributed Auth API"
  identifier           = aws_apigatewayv2_stage.v1_stage.invoke_url
  allow_offline_access = true
}

resource "auth0_client" "auth0_client" {
  name        = "Distributed Auth Client"
  description = "Client for test app with authentication on multiple services"
  app_type = "spa"

  allowed_clients = ["http://localhost:5173"]
  callbacks       = ["http://localhost:5173/home"]

  grant_types = [
    "authorization_code",
    "implicit",
    "refresh_token"
  ]

  jwt_configuration {
    lifetime_in_seconds = 300
    secret_encoded      = true
    alg                 = "RS256"
  }
}

resource "auth0_connection" "google_connection" {
  name     = "google-connection"
  strategy = "google-oauth2"

  options {
    client_id                = google_iam_oauth_client_credential.credential.oauth_client_credential_id
    client_secret            = google_iam_oauth_client_credential.credential.client_secret
    allowed_audiences        = ["http://localhost:5173", aws_apigatewayv2_stage.v1_stage.invoke_url]
    scopes                   = ["email", "profile", "gmail"]
    set_user_root_attributes = "on_each_login"
  }
}

# resource "auth0_connection" "github_connection" {

# }

output "auth0_client_id" {
  value = auth0_client.auth0_client.client_id
}

