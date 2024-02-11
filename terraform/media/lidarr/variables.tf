variable "LIDARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "SABNZBD_API_KEY" {
  type      = string
  sensitive = true
}

variable "lidarr_url" {
  type    = string
  default = "http://lidarr.media.svc.cluster.local:8686"
}


