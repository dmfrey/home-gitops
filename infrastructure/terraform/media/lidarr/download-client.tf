# Lidarr changed protocol values from "torrent"/"usenet" to
# "TorrentDownloadProtocol"/"UsenetDownloadProtocol" in a recent release.
# The devopsarr/lidarr provider v1.13.0 can't parse the new values on READ,
# causing plan to fail. Removed from state (destroy=false) until provider is
# fixed. Track: https://github.com/devopsarr/terraform-provider-lidarr/issues/255
#
# resource "lidarr_download_client_qbittorrent" "qbittorrent" { ... }
# resource "lidarr_download_client_nzbget" "nzbget" { ... }

removed {
  from = lidarr_download_client_qbittorrent.qbittorrent
  lifecycle {
    destroy = false
  }
}

removed {
  from = lidarr_download_client_nzbget.nzbget
  lifecycle {
    destroy = false
  }
}
