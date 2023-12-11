resource "prowlarr_download_client_qbittorrent" "rdt-client" {
  name     = "rdt-client"
  enable   = true
  host     = "rdt-client.download.svc.cluster.local"
  port     = 6500
  category = "misc"
}
