variable "READARR_API_KEY" {
  type      = string
  sensitive = true
}

variable "SABNZBD_API_KEY" {
  type      = string
  sensitive = true
}

variable "readarr_url" {
  type    = string
  default = "http://readarr.media.svc.cluster.local:7878"
}


