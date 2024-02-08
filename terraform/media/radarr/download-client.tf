resource "radarr_download_client_qbittorrent" "rdt-client" {
  name                       = "rdt-client"
  enable                     = true
  host                       = "rdt-client.download.svc.cluster.local"
  port                       = 6500
  movie_category             = "movies"
  remove_completed_downloads = true
}

resource "radarr_download_client_sabnzbd" "sabnzbd" {
  enable   = true
  priority = 1
  name     = "sabnzbd"
  host     = "sabnzbd.download.svc.cluster.local"
  url_base = "/sabnzbd/"
  port     = 8080
  api_key  = var.SABNZBD_API_KEY
  movie_category = "movie"
}

resource "radarr_remote_path_mapping" "sabnzbd" {
  host        = radarr_download_client_sabnzbd.sabnzbd.host
  remote_path = "/data/downloads/nzb/complete"
  local_path  = "/media/downloads/nzb/complete"
}