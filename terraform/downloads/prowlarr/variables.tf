variable "PROWLARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "LIDARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "READARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "RADARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "SONARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "prowlarr_url" {
  type    = string
  default = "http://prowlarr.download.svc.cluster.local:9696"
}

variable "lidarr_url" {
  type    = string
  default = "http://lidarr.media.svc.cluster.local:8686"
}

variable "readarr_url" {
  type    = string
  default = "http://readarr.media.svc.cluster.local:8787"
}

variable "radarr_url" {
  type    = string
  default = "http://radarr.media.svc.cluster.local:7878"
}

variable "sonarr_url" {
  type    = string
  default = "http://sonarr.media.svc.cluster.local:8989"
}
