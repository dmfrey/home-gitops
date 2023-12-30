resource "sonarr_download_client_qbittorrent" "rdt-client" {
  name                       = "rdt-client"
  enable                     = true
  host                       = "rdt-client.download.svc.cluster.local"
  port                       = 6500
  tv_category                = "series"
  remove_completed_downloads = true
}

