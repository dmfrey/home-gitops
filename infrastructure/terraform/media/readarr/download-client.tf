resource "readarr_download_client_qbittorrent" "rdt-client" {
  name                       = "rdt-client"
  enable                     = true
  priortity                  = 25
  host                       = "rdt-client.download.svc.cluster.local"
  port                       = 6500
  book_category              = "book"
  remove_completed_downloads = true
  first_and_last             = true
  tags                       = ["book"]
}

resource "readarr_download_client_sabnzbd" "sabnzbd" {
  name                       = "sabnzbd"
  enable                     = true
  priority                   = 1
  host                       = "sabnzbd.download.svc.cluster.local"
  port                       = 8080
  url_base                   = "/sabnzbd/"
  api_key                    = var.SABNZBD_API_KEY
  book_category              = "book"
  tags                       = ["book"]
}

resource "readarr_remote_path_mapping" "sabnzbd" {
  host        = readarr_download_client_sabnzbd.sabnzbd.host
  remote_path = "/data/downloads/nzb/complete/"
  local_path  = "/media/downloads/nzb/complete/"
}