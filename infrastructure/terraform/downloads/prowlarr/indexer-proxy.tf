resource "prowlarr_indexer_proxy_flaresolverr" "flaresolverr" {
  # Added 2026-08-10: Uindex and BT.etree (torrent_uindex/torrent_btetree
  # in indexers.tf) had been failing for 2+ months (Uindex since
  # 2026-05-29, BT.etree since 2026-08-04) - confirmed via direct indexer
  # test to be blocked by Cloudflare's anti-bot protection on the tracker
  # sites themselves ("Unable to access uindex.org, blocked by CloudFlare
  # Protection"), not a transient outage. Prowlarr's scraper has no JS
  # engine so this can't self-resolve on its own.
  #
  # FlareSolverr (kubernetes/apps/download/flaresolverr) solves the
  # challenge with a real headless browser, routed through the VPN VLAN
  # (192.168.90.0/24, WireGuard gateway) rather than the cluster's normal
  # egress path - confirmed via direct test that this gets both indexers
  # past Cloudflare's IP-reputation blocking ("Challenge not detected!"
  # for Uindex, "Challenge solved!" for BT.etree, both HTTP 200 with real
  # page content).
  #
  # Only applies to indexers tagged prowlarr_tag.flaresolverr - see
  # torrent_uindex/torrent_btetree in indexers.tf.
  name            = "FlareSolverr"
  host            = "http://flaresolverr.download.svc.cluster.local:8191/"
  request_timeout = 60
  tags            = [prowlarr_tag.flaresolverr.id]

  lifecycle {
    ignore_changes = all
  }
}
