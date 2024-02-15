resource "authentik_source_plex" "plex" {
  name                = "Plex"
  slug                = "plex"
  client_id           = var.AUTHENTIK_PLEX_CLIENT_ID
  plex_token          = var.AUTHENTIK_PLEX_TOKEN
  authentication_flow = data.authentik_flow.default-source-authentication.id
  enrollment_flow     = data.authentik_flow.default-enrollment-flow.id
  allow_friends       = false
  allowed_servers = [
    var.PLEX_SERVER_ID
  ]
}
