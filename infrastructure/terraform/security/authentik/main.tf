terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.2.0"
    }
  }

}

locals {
  authentik_plex_client_id = var.AUTHENTIK_PLEX_CLIENT_ID
  authentik_plex_token     = var.AUTHENTIK_PLEX_TOKEN
}

provider "authentik" {
  url   = "https://auth.${var.CLUSTER_DOMAIN}"
  token = var.AUTHENTIK_TOKEN
}
