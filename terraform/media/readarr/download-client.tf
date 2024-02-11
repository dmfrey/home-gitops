resource "readarr_download_client_qbittorrent" "rdt-client" {
  name                       = "rdt-client"
  enable                     = true
  host                       = "rdt-client.download.svc.cluster.local"
  port                       = 6500
  book_category             = "book"
  remove_completed_downloads = true
}

resource "readarr_download_client_sabnzbd" "sabnzbd" {
  enable   = true
  priority = 1
  name     = "sabnzbd"
  host     = "sabnzbd.download.svc.cluster.local"
  url_base = "/sabnzbd/"
  port     = 8080
  api_key  = var.SABNZBD_API_KEY
  book_category = "book"
}

resource "readarr_remote_path_mapping" "sabnzbd" {
  host        = readarr_download_client_sabnzbd.sabnzbd.host
  remote_path = "/data/downloads/nzb/complete/"
  local_path  = "/media/downloads/nzb/complete/"
}