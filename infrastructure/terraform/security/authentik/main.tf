terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.5.0"
    }
  }

}

locals {
  authentik_plex_client_id = var.AUTHENTIK_PLEX_CLIENT_ID
  authentik_plex_token     = var.AUTHENTIK_PLEX_TOKEN
}

provider "authentik" {
  url   = "http://authentik-server.security.svc.cluster.local"
  token = var.AUTHENTIK_TOKEN
}
