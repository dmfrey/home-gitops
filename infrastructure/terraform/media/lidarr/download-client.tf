resource "lidarr_download_client_qbittorrent" "qbittorrent" {
  name                       = "qBittorrent"
  enable                     = true
  priority                   = 1
  host                       = "qbittorrent.download.svc.cluster.local"
  port                       = 80
  music_category             = "music"
  remove_completed_downloads = true
  remove_failed_downloads    = true
}

resource "lidarr_download_client_nzbget" "nzbget" {
  enable                     = true
  priority                   = 1
  name                       = "NZBGet"
  host                       = "nzbget.download.svc.cluster.local"
  port                       = 80
  music_category             = "Music"
  remove_completed_downloads = true
  remove_failed_downloads    = true
}
