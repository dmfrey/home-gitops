resource "radarr_custom_format" "block_dangerous_extensions" {
  # Added 2026-08-10, the Radarr counterpart to Sonarr's
  # sonarr_release_profile.block_dangerous_extensions (see that resource's
  # comment for the incident this guards against - a fake 0-byte torrent
  # from Prowlarr's TorrentDownload indexer, disguised as a real release
  # with the torrent's own advertised name ending in .scr). Radarr has no
  # Release Profile concept (the devopsarr/radarr provider has no
  # release_profile resource), so this uses Radarr's own idiomatic
  # mechanism instead: a Custom Format matched against the release title,
  # given a large negative score in every quality profile's format_items
  # (see quality-profiles.tf) so it's rejected outright rather than merely
  # deprioritized.
  name                                 = "Block dangerous file extensions (malware-bait releases)"
  include_custom_format_when_renaming = false

  specifications = [
    {
      name           = "Dangerous extension"
      implementation = "ReleaseTitleSpecification"
      negate         = false
      required       = false
      value          = "\\.(scr|exe|lnk|bat|cmd|vbs|msi|jar|url|scf|pif)$"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}
