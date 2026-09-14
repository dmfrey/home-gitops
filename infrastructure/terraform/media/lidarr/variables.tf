variable "LIDARR_API_KEY" {
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

variable "lidarr_url" {
  type    = string
  default = "http://lidarr.media.svc.cluster.local:8686"
}


