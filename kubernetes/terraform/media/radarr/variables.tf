variable "RADARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "radarr_url" {
  type    = string
  default = "http://radarr.media.svc.cluster.local:7878"
}


