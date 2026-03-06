resource "lidarr_custom_format" "disc_image" {
  name                              = "Disc Image"
  include_custom_format_when_renaming = false

  specifications = [
    {
      name           = "Release Title"
      implementation = "ReleaseTitleSpecification"
      negate         = false
      required       = false
      value          = "(?i)\\bimage\\b"
    }
  ]
}
