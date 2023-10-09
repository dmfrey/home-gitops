resource "sonarr_media_management" "settings" {
  unmonitor_previous_episodes = false
  hardlinks_copy              = true
  create_empty_folders        = false
  delete_empty_folders        = false
  enable_media_info           = true
  import_extra_files          = true
  set_permissions             = false
  skip_free_space_check       = false
  minimum_free_space          = 100
  recycle_bin_days            = 7
  chmod_folder                = "755"
  chown_group                 = "kah"
  download_propers_repacks    = "doNotPrefer"
  episode_title_required      = "always"
  extra_file_extensions       = "srt"
  file_date                   = "none"
  recycle_bin_path            = "/media/library/trash"
  rescan_after_refresh        = "always"
}

resource "sonarr_naming" "naming" {
  rename_episodes            = true
  replace_illegal_characters = true
  multi_episode_style        = 5
  colon_replacement_format   = 4
  daily_episode_format       = "{Series TitleYear} - {Air-Date} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}"
  anime_episode_format       = "{Series TitleYear} - S{season:00}E{episode:00} - {absolute:000} - {Episode CleanTitle} [{Preferred Words }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{Mediainfo AudioCodec} { Mediainfo AudioChannels}]{MediaInfo AudioLanguages}{-Release Group}"
  series_folder_format       = "{Series TitleYear} {imdb-{ImdbId}}"
  season_folder_format       = "Season {season:00}"
  specials_folder_format     = "Specials"
  standard_episode_format    = "{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}"
}

resource "sonarr_root_folder" "series" {
  path = "/media/library/series"
}

resource "sonarr_root_folder" "anime" {
  path = "/media/library/anime"
}
