
resource "authentik_token" "homepage" {
  identifier = "homepage"
  user      = authentik_user.dmfrey.id
  expiring  = false
  intent    = api

  depends_on = [
    authentik_user.dmfrey
  ]
}
