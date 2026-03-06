resource "sonarr_download_client_qbittorrent" "qbittorrent" {
  name                       = "qBittorrent"
  enable                     = true
  host                       = "qbittorrent.download.svc.cluster.local"
  port                       = 80
  tv_category                = "series"
  remove_completed_downloads = true
  remove_failed_downloads    = true
}

resource "sonarr_download_client_nzbget" "nzbget" {
  enable                     = true
  priority                   = 1
  name                       = "NZBGet"
  host                       = "nzbget.download.svc.cluster.local"
  port                       = 80
  tv_category                = "Series"
  remove_completed_downloads = true
  remove_failed_downloads    = true
}
