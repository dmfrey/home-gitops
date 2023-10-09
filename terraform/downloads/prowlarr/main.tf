terraform {
  required_providers {
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "2.0.0"
    }
  }

  cloud {
    organization = "davishaus"
    workspaces {
      name = "prowlarr-provisioner"
    }
  }
}
