terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.84.0"
    }
  }
}

provider "google" {}

resource "google_project_service" "kms_api" {
  ## Enabling GCP KMS API
  project            = var.project
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_kms_key_ring" "my_key_ring" {
  # Create the key ring on GCP
  project  = var.project
  name     = "homelab5767-keyring"
  location = "global"
  depends_on = [
  google_project_service.kms_api]
}

resource "google_kms_crypto_key" "my_crypto_key" {
  # Add a new create to the key ring
  name     = "sops"
  key_ring = google_kms_key_ring.my_key_ring.id
}

variable "project" {
  description = "The GCP project"
  type        = string
  default     = "homelab5767"
}
