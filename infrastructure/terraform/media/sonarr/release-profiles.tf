resource "sonarr_release_profile" "block_dangerous_extensions" {
  # Added 2026-08-10 after TorrentDownload (Prowlarr) served two 0-byte fake
  # torrents disguised as real releases, with the torrent's own advertised
  # name ending in .scr (a Windows executable extension) - e.g. "...WEB
  # h264-ETHEL.scr". Sonarr's own safety check already refuses to import
  # anything with no eligible video files, so nothing reached the library,
  # but this rejects the release at grab-decision time instead, before any
  # download happens - protects against this pattern from any indexer, not
  # just the one that triggered it.
  enabled    = true
  name       = "Block dangerous file extensions (malware-bait releases)"
  ignored    = ["\\.scr$", "\\.exe$", "\\.lnk$", "\\.bat$", "\\.cmd$", "\\.vbs$", "\\.msi$", "\\.jar$", "\\.url$", "\\.scf$", "\\.pif$"]
  indexer_id = 0 # all indexers

  lifecycle {
    ignore_changes = all
  }
}
