resource "lidarr_quality_profile" "lossless" {
  name            = "Lossless"
  upgrade_allowed = false
  cutoff          = 1005

  quality_groups = [
    {
      id   = 1005
      name = "Lossless"
      qualities = [
        { id = 6,  name = "FLAC" },
        { id = 7,  name = "ALAC" },
        { id = 35, name = "APE" },
        { id = 36, name = "WavPack" },
        { id = 21, name = "FLAC 24bit" },
        { id = 37, name = "ALAC 24bit" },
      ]
    },
  ]

  lifecycle {
    ignore_changes = [quality_groups, format_items]
  }
}

resource "lidarr_quality_profile" "standard" {
  name            = "Standard"
  upgrade_allowed = false
  cutoff          = 1002

  quality_groups = [
    {
      id   = 1002
      name = "Low Quality Lossy"
      qualities = [
        { id = 1,  name = "MP3-192" },
        { id = 18, name = "OGG Vorbis Q6" },
        { id = 9,  name = "AAC-192" },
        { id = 20, name = "WMA" },
        { id = 34, name = "MP3-224" },
      ]
    },
    {
      id   = 1003
      name = "Mid Quality Lossy"
      qualities = [
        { id = 17, name = "OGG Vorbis Q7" },
        { id = 8,  name = "MP3-VBR-V2" },
        { id = 3,  name = "MP3-256" },
        { id = 16, name = "OGG Vorbis Q8" },
        { id = 10, name = "AAC-256" },
      ]
    },
    {
      id   = 1004
      name = "High Quality Lossy"
      qualities = [
        { id = 2,  name = "MP3-VBR-V0" },
        { id = 12, name = "AAC-VBR" },
        { id = 4,  name = "MP3-320" },
        { id = 15, name = "OGG Vorbis Q9" },
        { id = 11, name = "AAC-320" },
        { id = 14, name = "OGG Vorbis Q10" },
      ]
    },
  ]

  lifecycle {
    ignore_changes = [quality_groups, format_items]
  }
}
