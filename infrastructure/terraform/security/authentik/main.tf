terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2024.10.0"
    }

    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.11.0"
    }

  }

}

provider "bitwarden" {
  access_token = var.bw_access_token
  experimental {
    embedded_client = true
  }
}

data "bitwarden_secret" "authentik" {
  key = "authentik"
}

locals {
  raw_data                    = jsondecode(data.bitwarden_secret.authentik.value)
  authentik_token             = local.raw_data["AUTHENTIK_TOKEN"]
  authentik_plex_client_id    = local.raw_data["AUTHENTIK_PLEX_CLIENT_ID"]
  authentik_plex_token        = local.raw_data["AUTHENTIK_PLEX_TOKEN"]
}

provider "authentik" {
  url   = "https://auth.${var.cluster_domain}"
  token = local.authentik_token
}
