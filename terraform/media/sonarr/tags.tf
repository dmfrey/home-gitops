resource "sonarr_tag" "series" {
  label = "series"
}

resource "sonarr_auto_tag" "series" {
  name                      = "Series"
  remove_tags_automatically = true
  tags                      = [sonarr_tag.series.id]

  specifications = [
    {
      name           = "folder"
      implementation = "RootFolderSpecification"
      negate         = false
      required       = false
      value          = "/media/library/tv_shows"
    }
  ]
}
