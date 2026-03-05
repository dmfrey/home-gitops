resource "sonarr_download_client_qbittorrent" "qbittorrent" {
  name                       = "qBittorrent"
  enable                     = true
  host                       = "qbittorrent.download.svc.cluster.local"
  port                       = 80
  tv_category                = "series"
  remove_completed_downloads = true
}

resource "sonarr_remote_path_mapping" "qbittorrent" {
  host        = sonarr_download_client_qbittorrent.qbittorrent.host
  remote_path = "/media/downloads/qbittorrent/"
  local_path  = "/media/downloads/qbittorrent/"
}

resource "sonarr_download_client_nzbget" "nzbget" {
  enable      = true
  priority    = 1
  name        = "NZBGet"
  host        = "nzbget.download.svc.cluster.local"
  port        = 80
  tv_category = "Series"
}

resource "sonarr_remote_path_mapping" "nzbget" {
  host        = sonarr_download_client_nzbget.nzbget.host
  remote_path = "/media/downloads/nzbget/completed/Series/"
  local_path  = "/media/downloads/nzbget/completed/Series/"
}
