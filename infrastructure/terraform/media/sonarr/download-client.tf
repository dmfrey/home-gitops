resource "sonarr_download_client_qbittorrent" "rdt-client" {
  name                       = "rdt-client"
  enable                     = true
  host                       = "rdt-client.download.svc.cluster.local"
  port                       = 6500
  tv_category                = "series"
  remove_completed_downloads = true
}

resource "sonarr_remote_path_mapping" "rdt-client" {
  host        = sonarr_download_client_qbittorrent.rdt-client.host
  remote_path = "/media/downloads/torrents/series/"
  local_path  = "/media/downloads/torrents/series/"
}

resource "sonarr_download_client_sabnzbd" "sabnzbd" {
  enable   = true
  priority = 1
  name     = "sabnzbd"
  host     = "sabnzbd.download.svc.cluster.local"
  url_base = "/sabnzbd/"
  port     = 8080
  api_key  = var.SABNZBD_API_KEY
  tv_category = "series"
}

resource "sonarr_remote_path_mapping" "sabnzbd" {
  host        = sonarr_download_client_sabnzbd.sabnzbd.host
  remote_path = "/media/downloads/nzb/complete/"
  local_path  = "/media/downloads/nzb/complete/"
}