resource "readarr_download_client_qbittorrent" "rdt-client" {
  name                       = "rdt-client"
  enable                     = true
  priority                   = 25
  host                       = "rdt-client.download.svc.cluster.local"
  port                       = 6500
  book_category              = "book"
  remove_completed_downloads = true
  first_and_last             = true
  tags                       = [1]
}

# resource "readarr_download_client_qbittorrent" "rdt-client" {
#   host        = readarr_download_client_qbittorrent.rdt-client.host
#   remote_path = "/media/downloads/torrents/book/"
#   local_path  = "/media/downloads/torrents/book/"
# }

resource "readarr_download_client_sabnzbd" "sabnzbd" {
  name                       = "sabnzbd"
  enable                     = true
  priority                   = 1
  host                       = "sabnzbd.download.svc.cluster.local"
  port                       = 8080
  url_base                   = "/sabnzbd/"
  api_key                    = var.SABNZBD_API_KEY
  book_category              = "book"
  tags                       = [1]
}

resource "readarr_remote_path_mapping" "sabnzbd" {
  host        = readarr_download_client_sabnzbd.sabnzbd.host
  remote_path = "/media/downloads/nzb/complete/"
  local_path  = "/media/downloads/nzb/complete/"
}