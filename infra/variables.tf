variable "auth0_domain" {
  description = "Domain of Auth0 tenant"
  type        = string
}

variable "google_client_id" {
  description = "Client ID of Google OAuth Client"
  type        = string
}

variable "google_client_secret" {
  description = "Secret for OAuth client in GCP"
  sensitive   = true
  type        = string
}