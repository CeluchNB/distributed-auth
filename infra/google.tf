resource "google_iam_oauth_client" "client" {
  oauth_client_id       = "distributed-auth-google-client"
  display_name          = "Distributed Auth Google Client"
  location              = "global"
  allowed_redirect_uris = ["https://${local.auth0_domain}/login/callback", "http://localhost:5173"]
  allowed_scopes        = ["https://www.googleapis.com/auth/cloud-platform", "openid"]
  allowed_grant_types   = ["AUTHORIZATION_CODE_GRANT"]
  client_type = "CONFIDENTIAL_CLIENT"
  disabled = true
}

resource "google_iam_oauth_client_credential" "credential" {
  oauthclient                = google_iam_oauth_client.client.oauth_client_id
  location                   = google_iam_oauth_client.client.location
  oauth_client_credential_id = "google-client-id"
  disabled = true

}