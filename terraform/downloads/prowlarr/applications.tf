resource "prowlarr_application_lidarr" "lidarr" {
  name            = "Lidarr"
  sync_level      = "fullSync"
  base_url        = var.lidarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.LIDARR_API_KEY
  sync_categories = [3000, 3010, 3030, 3040, 3050, 3060]
}

resource "prowlarr_application_readarr" "readarr" {
  name            = "Readarr"
  sync_level      = "fullSync"
  base_url        = var.readarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.READARR_API_KEY
  sync_categories = [3030, 7000, 7010, 7020, 7030, 7040, 7050, 7060]
}

resource "prowlarr_application_radarr" "radarr" {
  name            = "Radarr"
  sync_level      = "fullSync"
  base_url        = var.radarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.RADARR_API_KEY
  sync_categories = [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060, 2070, 2080]
}

resource "prowlarr_application_sonarr" "sonarr" {
  name            = "Sonarr"
  sync_level      = "fullSync"
  base_url        = var.sonarr_url
  prowlarr_url    = var.prowlarr_url
  api_key         = var.SONARR_API_KEY
  sync_categories = [5000, 5010, 5020, 5030, 5040, 5045, 5050]
}

