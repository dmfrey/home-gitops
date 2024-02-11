resource "readarr_media_management" "settings" {
  unmonitor_previous_books                    = true
  hardlinks_copy                              = true
  create_empty_author_folders                 = false
  delete_empty_folders                        = false
  download_propers_and_repacks                = "preferAndUpgrade"
  skip_free_space_check                       = false
  minimum_free_space                          = 100
  set_permissions                             = true
  chmod_folder                                = "775"
  chown_group                                 = "1568"
  import_extra_files                          = true
  file_date                                   = "none"
  recycle_bin_cleanup_days                    = 7
  recycle_bin                                 = "/media/trash"
  rescan_after_refresh                        = "always"
}

resource "readarr_naming" "naming" {
  rename_books               = true
  replace_illegal_characters = true
  colon_replacement_format   = 0
  author_folder_format       = "{Author Name}"
  standard_book_format       = "{Book Title}/{Author Name} - {Book Title}{ (PartNumber)}"
}

resource "readarr_root_folder" "books" {
  name                        = "Books"
  path                        = "/media/books"
  default_metadata_profile_id = 1
  default_quality_profile_id  = 1
  default_monitor_option      = "all"
  is_calibre_library          = false
  output_profile              = "default"
}
