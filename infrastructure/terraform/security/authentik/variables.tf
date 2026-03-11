
variable "CLUSTER_DOMAIN" {
  type        = string
  description = "Domain for Authentik"
}

variable "AUTHENTIK_TOKEN" {
  type      = string
  sensitive = true
}

variable "AUTHENTIK_PLEX_CLIENT_ID" {
  type = string
}

variable "AUTHENTIK_PLEX_TOKEN" {
  type      = string
  sensitive = true
}

# OAuth application credentials
variable "AFFINE_CLIENT_ID" { type = string }
variable "AFFINE_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "GATUS_CLIENT_ID" { type = string }
variable "GATUS_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "GRAFANA_CLIENT_ID" { type = string }
variable "GRAFANA_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "BLINKO_CLIENT_ID" { type = string }
variable "BLINKO_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "JELLYFIN_CLIENT_ID" { type = string }
variable "JELLYFIN_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "LINKWARDEN_CLIENT_ID" { type = string }
variable "LINKWARDEN_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "OPENWEB_CLIENT_ID" { type = string }
variable "OPENWEB_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "PINEPODS_CLIENT_ID" { type = string }
variable "PINEPODS_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "ROMM_CLIENT_ID" { type = string }
variable "ROMM_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "SPRING_DEV_CLIENT_ID" { type = string }
variable "SPRING_DEV_CLIENT_SECRET" {
  type      = string
  sensitive = true
}
variable "EXCALIDRAW_CLIENT_ID" { type = string }
variable "EXCALIDRAW_CLIENT_SECRET" {
  type      = string
  sensitive = true
}

# User credentials
variable "USERS_DMFREY_NAME" { type = string }
variable "USERS_DMFREY_EMAIL" { type = string }
variable "USERS_DMFREY_PASSWORD" {
  type      = string
  sensitive = true
}
variable "USERS_SDFREY_NAME" { type = string }
variable "USERS_SDFREY_EMAIL" { type = string }
variable "USERS_SDFREY_PASSWORD" {
  type      = string
  sensitive = true
}
variable "USERS_CGFREY_NAME" { type = string }
variable "USERS_CGFREY_EMAIL" { type = string }
variable "USERS_CGFREY_PASSWORD" {
  type      = string
  sensitive = true
}
variable "USERS_MKFREY_NAME" { type = string }
variable "USERS_MKFREY_EMAIL" { type = string }
variable "USERS_MKFREY_PASSWORD" {
  type      = string
  sensitive = true
}
variable "USERS_ADFREY_NAME" { type = string }
variable "USERS_ADFREY_EMAIL" { type = string }
variable "USERS_ADFREY_PASSWORD" {
  type      = string
  sensitive = true
}
