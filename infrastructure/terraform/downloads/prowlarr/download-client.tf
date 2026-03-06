resource "prowlarr_download_client_nzbget" "nzbget" {
  enable   = true
  priority = 1
  name     = "NZBGet"
  host     = "nzbget.download.svc.cluster.local"
  port     = 80
  category = "misc"
}