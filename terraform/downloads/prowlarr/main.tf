terraform {
  required_providers {
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "2.1.0"
    }
  }

  cloud {
    organization = "homelab5767"
    workspaces {
      name = "prowlarr-provisioner"
    }
  }
}
