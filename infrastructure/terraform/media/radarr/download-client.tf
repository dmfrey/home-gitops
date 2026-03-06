resource "radarr_download_client_qbittorrent" "qbittorrent" {
  name                       = "qBittorrent"
  enable                     = true
  host                       = "qbittorrent.download.svc.cluster.local"
  port                       = 80
  movie_category             = "movie"
  remove_completed_downloads = true
  remove_failed_downloads    = true
}

resource "radarr_download_client_nzbget" "nzbget" {
  enable                     = true
  priority                   = 1
  name                       = "NZBGet"
  host                       = "nzbget.download.svc.cluster.local"
  port                       = 80
  movie_category             = "Movies"
  remove_completed_downloads = true
  remove_failed_downloads    = true
}
