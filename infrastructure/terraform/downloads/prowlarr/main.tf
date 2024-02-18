terraform {
  required_version = ">= 1.3.9"
  required_providers {
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "2.3.0"
    }
  }
}
