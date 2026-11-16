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

resource "lidarr_metadata_profile" "standard_with_live" {
  name = "Standard + Live"

  primary_album_types   = [0] # Album
  secondary_album_types = [0, 6] # Studio, Live
  release_statuses      = [0] # Official
}

# Added 2026-11-16: every profile above allows only the "Album" primary type, so
# Lidarr hides Singles and EPs for every artist (Eddie Vedder's "Save It for
# Later" cover is a MusicBrainz Single and never showed up). Opt-in per artist:
# assign this profile to the artists whose Singles/EPs you want, rather than
# widening the shared ones. Same secondary types as "Standard + Compilations".
resource "lidarr_metadata_profile" "standard_with_eps_singles" {
  name = "Standard + EPs + Singles"

  primary_album_types   = [0, 1, 2] # Album, EP, Single
  secondary_album_types = [0, 1, 2] # Studio, Compilation, Soundtrack
  release_statuses      = [0] # Official
}
