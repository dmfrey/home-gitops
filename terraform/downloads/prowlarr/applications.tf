resource "prowlarr_application_lidarr" "lidarr" {
  name            = "Lidarr"
  sync_level      = "fullSync"
  base_url        = var.lidarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.LIDARR_API_KEY
}

resource "prowlarr_application_readarr" "readarr" {
  name            = "Readarr"
  sync_level      = "fullSync"
  base_url        = var.readarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.READARR_API_KEY
}

resource "prowlarr_application_radarr" "radarr" {
  name            = "Radarr"
  sync_level      = "fullSync"
  base_url        = var.radarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.RADARR_API_KEY
}

resource "prowlarr_application_sonarr" "sonarr" {
  name            = "Sonarr"
  sync_level      = "fullSync"
  base_url        = var.sonarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.SONARR_API_KEY
}

