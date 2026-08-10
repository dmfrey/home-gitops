resource "lidarr_release_profile" "avoid_variant_editions" {
  enabled    = true
  indexer_id = 0 # all indexers

  # These release variants (vinyl rips, regional/limited/deluxe editions,
  # box sets) routinely have a different tracklist than the canonical
  # release Lidarr matches against, causing "Has missing tracks"/"Worst
  # track match"/"Album match is not close enough" import failures and
  # stalled downloads. Ignoring them makes Lidarr skip these candidates and
  # try the next-best release instead of grabbing something that can't import.
  ignored = [
    "Limited Edition",
    "Japanese Edition",
    "Deluxe Edition",
    "Deluxe Box Set",
    "Box Set",
    "Bonus Tracks",
    "Bonus-DVD",
    "Anniversary Edition",
    "Vinyl",
    "WAVPACK",
    "LP",
    # These two release groups account for ~28% of all historical
    # albumImportIncomplete/downloadFailed events in this library (62 of
    # 225 checked) - almost entirely reissues/remasters/repacks that don't
    # match any cataloged MusicBrainz tracklist cleanly, even when the
    # title carries no other edition keyword (e.g. plain "-CD-FLAC-2011-
    # REETKEVER" with nothing else to filter on).
    "REETKEVER",
    "OBZEN",
  ]
}

resource "lidarr_release_profile" "block_dangerous_extensions" {
  # Added 2026-08-10, the Lidarr counterpart to
  # sonarr_release_profile.block_dangerous_extensions and
  # radarr_custom_format.block_dangerous_extensions (see the Sonarr
  # resource's comment for the incident this guards against - a fake
  # 0-byte torrent from Prowlarr's TorrentDownload indexer, disguised as a
  # real release with the torrent's own advertised name ending in .scr).
  # Prowlarr's app profiles are shared across all synced apps (only one
  # profile, "Standard", used by every indexer), so Lidarr pulls from the
  # exact same indexer pool as Sonarr/Radarr and is exposed to the same
  # risk. Unlike lidarr_release_profile.avoid_variant_editions above, this
  # provider's release_profile resource has no `name` argument (the API
  # doesn't return one either).
  enabled    = true
  indexer_id = 0 # all indexers

  ignored = [
    "\\.scr$",
    "\\.exe$",
    "\\.lnk$",
    "\\.bat$",
    "\\.cmd$",
    "\\.vbs$",
    "\\.msi$",
    "\\.jar$",
    "\\.url$",
    "\\.scf$",
    "\\.pif$",
  ]
}
