resource "b2_bucket" "volsync" {
  bucket_name = var.B2_BUCKET_NAME
  bucket_type = "allPrivate"
}
