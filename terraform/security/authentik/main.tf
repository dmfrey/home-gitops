terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2023.10.0"
    }
  }

  cloud {
    organization = "homelab5767"
    workspaces {
      name = "authentik-provisioner"
    }
  }
}
