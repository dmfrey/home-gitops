terraform {
  required_providers {
    sonarr = {
      source  = "devopsarr/sonarr"
      version = "3.1.0"
    }
  }

  cloud {
    organization = "davishaus"
    workspaces {
      name = "sonarr-provisioner"
    }
  }
}
