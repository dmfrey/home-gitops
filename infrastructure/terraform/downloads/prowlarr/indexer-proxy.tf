resource "prowlarr_tag" "flaresolverr" {
  label = "flaresolverr"
}

resource "prowlarr_indexer_proxy_flaresolverr" "flaresolverr" {
  host            = "http://flaresolverr.download.svc.cluster.local:8191"
  name            = "Flaresolverr"
  request_timeout = 60
  tags            = [prowlarr_tag.flaresolverr.id]
}
