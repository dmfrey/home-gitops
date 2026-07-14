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
