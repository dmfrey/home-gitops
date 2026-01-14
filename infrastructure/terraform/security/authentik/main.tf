terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.12.0"
    }

    onepassword = {
      source  = "1password/onepassword"
      version = "3.0.2" # "2.2.1"
    }

  }

}

provider "onepassword" {
  # connect_url           = var.service_account_json != null ? "http://onepassword.external-secrets.svc.cluster.local" : null
  # connect_token         = var.service_account_json
  # service_account_token = var.onepassword_sa_token
  connect_url   = var.OP_CONNECT_HOST
  connect_token = var.OP_CONNECT_TOKEN
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
  url   = "https://auth.${var.CLUSTER_DOMAIN}"
  token = module.onepassword_authentik.fields["AUTHENTIK_TOKEN"]
}

