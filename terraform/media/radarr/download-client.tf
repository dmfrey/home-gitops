resource "radarr_download_client_qbittorrent" "rdt-client" {
  name                       = "rdt-client"
  enable                     = true
  host                       = "rdt-client.download.svc.cluster.local"
  port                       = 6500
  movie_category             = "movies"
  remove_completed_downloads = true
}

resource "radarr_remote_path_mapping" "downloads-path" {
  host        = radarr_download_client_qbittorrent.rdt-client.host
  remote_path = "/data/downloads/torrents/"
  local_path  = "/media/downloads/torrents/"
}
