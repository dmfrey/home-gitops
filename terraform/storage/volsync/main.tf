terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.8.4"
    }
  }
  cloud {
    organization = "homelab5767"
    workspaces {
      name = "volsync-provisioner"
    }
  }
}
