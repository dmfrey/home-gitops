resource "sonarr_release_profile" "block_dangerous_extensions" {
  # Added 2026-08-10 after TorrentDownload (Prowlarr) served two 0-byte fake
  # torrents disguised as real releases, with the torrent's own advertised
  # name ending in .scr (a Windows executable extension) - e.g. "...WEB
  # h264-ETHEL.scr". Sonarr's own safety check already refuses to import
  # anything with no eligible video files, so nothing reached the library,
  # but this rejects the release at grab-decision time instead, before any
  # download happens - protects against this pattern from any indexer, not
  # just the one that triggered it.
  #
  # Fixed 2026-10-14: the terms were bare strings like "\\.scr$", and Sonarr
  # treats a bare term as a plain substring, so they never matched anything. A
  # regex has to be wrapped in /.../ (and ends in /i to be case-insensitive).
  # This only sees the title the indexer advertises. Releases whose ".exe" name
  # appears only after the torrent is added in qBittorrent (five from
  # TorrentDownload on 2026-10-13) can't be caught here.
  enabled    = true
  name       = "Block dangerous file extensions (malware-bait releases)"
  ignored    = ["/\\.(scr|exe|lnk|bat|cmd|vbs|msi|jar|url|scf|pif)$/i"]
  indexer_id = 0 # all indexers

  lifecycle {
    ignore_changes = all
  }
}

resource "sonarr_release_profile" "block_audio_description" {
  # Added 2026-10-14 after Sonarr kept an HDTV capture of CIA S02E02 whose only
  # audio track was the audio-description mix (it can't be switched off), and
  # an "...with Audio Description..." AMZN WEB-DL sat at an equal Custom Format
  # score in the same search. Sonarr can't see an AD track in a file's media
  # info, so this rejects releases that are *labelled* AD at grab-decision time.
  # Unlabelled releases still get through.
  #
  # Term syntax matters here: a bare term is a case-insensitive substring match,
  # but a regex must be wrapped in /.../ and is case-SENSITIVE unless it ends in
  # /i. The AD and DVS tags are matched case-sensitively on purpose so a title
  # word like "Ad" or "Dvs" is not rejected. Verified against the live search
  # for CIA S02E02: rejected both "with Audio Description" releases and none of
  # the other 84.
  enabled = true
  name    = "Block audio-description releases"
  ignored = [
    "/audio[ ._-]?descri/i",
    "/descriptive[ ._-]?(video|audio)/i",
    "/\\bAD\\b/",
    "/\\bDVS\\b/",
  ]
  indexer_id = 0 # all indexers

  lifecycle {
    ignore_changes = all
  }
}
