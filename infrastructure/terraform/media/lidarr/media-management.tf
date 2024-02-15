resource "lidarr_media_management" "settings" {
  unmonitor_previous_tracks                   = true
  hardlinks_copy                              = true
  create_empty_folders                        = false
  delete_empty_folders                        = false
  watch_library_for_changes                   = true
  import_extra_files                          = true
  set_permissions                             = false
  chmod_folder                                = "775"
  chown_group                                 = "1568"
  skip_free_space_check                       = false
  minimum_free_space                          = 100
  download_propers_repacks                    = "preferAndUpgrade"
  allow_fingerprinting                        = "never"
  extra_file_extensions                       = "info"
  file_date                                   = "none"
  recycle_bin_days                            = 7
  recycle_bin_path                            = "/media/trash"
  rescan_after_refresh                        = "always"
}

resource "lidarr_naming" "naming" {
  rename_tracks              = true
  replace_illegal_characters = true
  standard_track_format      = "{Album Title} ({Release Year})/{Artist Name} - {Album Title} - {track:00} - {Track Title}"
  multi_disc_track_format    = "{Album Title} ({Release Year})/{Medium Format} {medium:00}/{Artist Name} - {Album Title} - {track:00} - {Track Title}"
  artist_folder_format       = "{Artist Name}"
}

resource "lidarr_root_folder" "music" {
  name                    = "Music"
  quality_profile_id      = 1
  metadata_profile_id     = 1
  monitor_option          = "future"
  new_item_monitor_option = "all"
  path                    = "/media/music/flac"
  tags                    = [lidarr_tag.music.id]
}

resource "lidarr_root_folder" "purchased_music" {
  name                    = "Purchased Music"
  quality_profile_id      = 1
  metadata_profile_id     = 1
  monitor_option          = "future"
  new_item_monitor_option = "all"
  path                    = "/media/music/Google Music"
  tags                    = [lidarr_tag.music.id]
}
