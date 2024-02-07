resource "radarr_tag" "movie" {
  label = "movie"
}

resource "radarr_auto_tag" "movie" {
  name                      = "Movie"
  remove_tags_automatically = true
  tags                      = [radarr_tag.movie.id]

  specifications = [
    {
      name           = "folder"
      implementation = "RootFolderSpecification"
      negate         = false
      required       = false
      value          = "/media/library/movies"
    }
  ]
}
