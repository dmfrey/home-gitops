resource "lidarr_download_client_qbittorrent" "qbittorrent" {
  name                       = "qBittorrent"
  enable                     = true
  priority                   = 1
  host                       = "qbittorrent.download.svc.cluster.local"
  port                       = 80
  music_category             = "music"
  remove_completed_downloads = true
}

resource "lidarr_remote_path_mapping" "qbittorrent" {
  host        = lidarr_download_client_qbittorrent.qbittorrent.host
  remote_path = "/media/downloads/qbittorrent/downloads/"
  local_path  = "/media/downloads/qbittorrent/downloads/"
}

resource "lidarr_download_client_nzbget" "nzbget" {
  enable         = true
  priority       = 1
  name           = "NZBGet"
  host           = "nzbget.download.svc.cluster.local"
  port           = 80
  music_category = "Music"
}

resource "lidarr_remote_path_mapping" "nzbget" {
  host        = lidarr_download_client_nzbget.nzbget.host
  remote_path = "/media/downloads/nzbget/completed/Music/"
  local_path  = "/media/downloads/nzbget/completed/Music/"
}
