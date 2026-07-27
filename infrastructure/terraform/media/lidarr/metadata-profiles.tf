resource "lidarr_metadata_profile" "standard" {
  name = "Standard"

  primary_album_types   = [0] # Album
  secondary_album_types = [0, 1] # Studio, Compilation
  release_statuses      = [0] # Official

  lifecycle {
    ignore_changes = all
  }
}

resource "lidarr_metadata_profile" "standard_with_compilations" {
  name = "Standard + Compilations"

  primary_album_types   = [0] # Album
  secondary_album_types = [0, 1, 2] # Studio, Compilation, Soundtrack
  release_statuses      = [0] # Official
}
