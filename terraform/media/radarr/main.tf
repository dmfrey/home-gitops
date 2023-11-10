terraform {
  required_providers {
    radarr = {
      source  = "devopsarr/radarr"
      version = "2.1.0"
    }
  }

  cloud {
    organization = "homelab5767"
    workspaces {
      name = "radarr-provisioner"
    }
  }
}
