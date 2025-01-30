terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.12.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "2.1.2"
    }

  }

}

provider "onepassword" {
  url                   = var.service_account_json != null ? "http://onepassword-connect.external-secrets.svc.cluster.local" : null
  token                 = var.service_account_json
  service_account_token = var.onepassword_sa_token
}

module "onepassword_authentik" {
  source = "github.com/dmfrey/terraform-1password-item"
  vault  = "homelab5767"
  item   = "authentik"
}

locals {
  authentik_token             = local.raw_data["AUTHENTIK_TOKEN"]
  authentik_plex_client_id    = local.raw_data["AUTHENTIK_PLEX_CLIENT_ID"]
  authentik_plex_token        = local.raw_data["AUTHENTIK_PLEX_TOKEN"]
}

provider "authentik" {
  url   = "https://auth.${var.cluster_domain}"
  token = module.onepassword_authentik.fields["AUTHENTIK_TOKEN"]
}
