variable "SONARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "sonarr_url" {
  type    = string
  default = "http://sonarr.media.svc.cluster.local:8989"
}


