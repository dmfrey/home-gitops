terraform {
  required_providers {
    sonarr = {
      source  = "devopsarr/sonarr"
      version = "3.1.1"
    }
  }

  cloud {
    organization = "homelab5767"
    workspaces {
      name = "sonarr-provisioner"
    }
  }
}
