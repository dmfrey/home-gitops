resource "sonarr_quality_profile" "hd_1080p" {
  name                = "HD-1080p"
  upgrade_allowed     = true
  cutoff              = 7 # Bluray-1080p (Sonarr has no Remux-1080p)
  min_format_score    = 0
  cutoff_format_score = 10000

  quality_groups = [
    {
      qualities = [{ id = 9, name = "HDTV-1080p" }]
    },
    {
      id   = 1002
      name = "WEB 1080p"
      qualities = [
        { id = 15, name = "WEBRip-1080p" },
        { id = 3, name = "WEBDL-1080p" },
      ]
    },
    {
      qualities = [{ id = 7, name = "Bluray-1080p" }]
    },
  ]
}

resource "sonarr_quality_profile" "ultra_hd_2160p" {
  name                = "Ultra-HD-2160p"
  upgrade_allowed     = true
  cutoff              = 19 # Bluray-2160p (Sonarr has no Remux-2160p)
  min_format_score    = 0
  cutoff_format_score = 10000

  quality_groups = [
    {
      qualities = [{ id = 16, name = "HDTV-2160p" }]
    },
    {
      id   = 1003
      name = "WEB 2160p"
      qualities = [
        { id = 17, name = "WEBRip-2160p" },
        { id = 18, name = "WEBDL-2160p" },
      ]
    },
    {
      qualities = [{ id = 19, name = "Bluray-2160p" }]
    },
  ]

  lifecycle {
    ignore_changes = all
  }
}
