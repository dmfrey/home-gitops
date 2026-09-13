variable "SONARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "PUSHOVER_USER_KEY" {
  type      = string
  sensitive = true
}

variable "ALERTMANAGER_PUSHOVER_TOKEN" {
  type      = string
  sensitive = true
}


variable "sonarr_url" {
  type    = string
  default = "http://sonarr.media.svc.cluster.local:8989"
}
