resource "radarr_download_client_qbittorrent" "qbittorrent" {
  name                       = "qBittorrent"
  enable                     = true
  host                       = "qbittorrent.download.svc.cluster.local"
  port                       = 80
  movie_category             = "movie"
  remove_completed_downloads = true
}

resource "radarr_remote_path_mapping" "qbittorrent" {
  host        = radarr_download_client_qbittorrent.qbittorrent.host
  remote_path = "/media/downloads/qbittorrent/"
  local_path  = "/media/downloads/qbittorrent/"
}

resource "radarr_download_client_nzbget" "nzbget" {
  enable         = true
  priority       = 1
  name           = "NZBGet"
  host           = "nzbget.download.svc.cluster.local"
  port           = 80
  movie_category = "Movies"
}

resource "radarr_remote_path_mapping" "nzbget" {
  host        = radarr_download_client_nzbget.nzbget.host
  remote_path = "/media/downloads/nzbget/completed/Movies"
  local_path  = "/media/downloads/nzbget/completed/Movies/"
}
