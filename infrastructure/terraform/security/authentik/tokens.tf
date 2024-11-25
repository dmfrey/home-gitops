
resource "authentik_token" "homepage" {
  identifier = "homepage"
  user      = data.authentik_user.akadmin.id
  expiring  = false
  intent    = "api"
}
