terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.6.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "2.1.2"
    }

  }

}

provider "onepassword" {
  url                   = var.service_account_json != null ? "http://nas.internal:8080" : null
  token                 = var.service_account_json
  service_account_token = var.onepassword_sa_token
}

module "onepassword_authentik" {
  source = "github.com/dmfrey/terraform-1password-item"
  vault  = "Kubernetes"
  item   = "authentik"
}

locals {
  authentik_plex_client_id    = module.onepassword_authentik.fields["AUTHENTIK_PLEX_CLIENT_ID"]
  authentik_plex_token        = module.onepassword_authentik.fields["AUTHENTIK_PLEX_TOKEN"]
}

provider "authentik" {
  url   = "https://auth.${var.cluster_domain}"
  token = module.onepassword_authentik.fields["AUTHENTIK_TOKEN"]
}
