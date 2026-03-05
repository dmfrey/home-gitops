resource "lidarr_metadata_profile" "standard" {
  name = "Standard"

  primary_album_types   = [0] # Album
  secondary_album_types = [0, 1] # Studio, Compilation
  release_statuses      = [0] # Official

  lifecycle {
    ignore_changes = all
  }
}
