resource "radarr_media_management" "settings" {
  auto_unmonitor_previously_downloaded_movies = false
  copy_using_hardlinks                        = true
  create_empty_movie_folders                  = false
  delete_empty_folders                        = false
  auto_rename_folders                         = true
  download_propers_and_repacks                = "doNotPrefer"
  skip_free_space_check_when_importing        = false
  minimum_free_space_when_importing           = 100
  set_permissions_linux                       = false
  chmod_folder                                = "755"
  chown_group                                 = "kah"
  paths_default_static                        = false
  enable_media_info                           = true
  import_extra_files                          = true
  extra_file_extensions                       = "srt"
  file_date                                   = "none"
  recycle_bin_cleanup_days                    = 7
  recycle_bin                                 = "/media/library/trash"
  rescan_after_refresh                        = "always"
}

resource "radarr_naming" "naming" {
  include_quality            = false
  rename_movies              = true
  replace_illegal_characters = false
  replace_spaces             = false
  colon_replacement_format   = "dash"
  standard_movie_format      = "{Movie CleanTitle} {(Release Year)} {imdb-{ImdbId}} {edition-{Edition Tags}} {[Custom Formats]}{[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels}]{MediaInfo AudioLanguages}[{MediaInfo VideoBitDepth}bit][{Mediainfo VideoCodec}]{-Release Group}"
  movie_folder_format        = "{Movie CleanTitle} ({Release Year})"
}

resource "radarr_root_folder" "series" {
  path = "/media/library/movies"
}
