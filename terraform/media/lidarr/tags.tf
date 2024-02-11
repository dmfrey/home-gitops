resource "lidarr_tag" "music" {
  label = "music"
}

resource "lidarr_auto_tag" "music" {
  name                      = "Music"
  remove_tags_automatically = true
  tags                      = [lidarr_tag.music.id]

  specifications = [
    {
      name           = "flac folder"
      implementation = "RootFolderSpecification"
      negate         = false
      required       = false
      value          = "/media/music/flac"
    },
    {
      name           = "purchases folder"
      implementation = "RootFolderSpecification"
      negate         = false
      required       = false
      value          = "/media/music/Google Music"
    }
  ]
}
