
resource "authentik_user" "dmfrey" {
  username = "dmfrey"
}

resource "authentik_token" "homepage" {
  identifier  = "homepage-token"
  user        = authentik_user.dmfrey.id
  description = "Homepage access token"
  expiring    = false
}