
locals {
  authentik_groups = {
    ai             = { name = "AI" }
    developers     = { name = "Developers" }
    downloads      = { name = "Downloads" }
    games          = { name = "Games" }
    home           = { name = "Home" }
    infrastructure = { name = "Infrastructure" }
    monitoring     = { name = "Monitoring" }
    media          = { name = "Media" }
    users          = { name = "Users" }
  }
}

data "authentik_group" "admins" {
  name = "authentik Admins"
}

resource "authentik_group" "grafana_admin" {
  name         = "Grafana Admins"
  is_superuser = false
}

resource "authentik_group" "default" {
  for_each     = local.authentik_groups
  name         = each.value.name
  is_superuser = false
}

resource "authentik_policy_binding" "application_policy_binding" {
  for_each = local.applications

  target = authentik_application.application[each.key].uuid
  group  = authentik_group.default[each.value.group].id
  order  = 0
}

##Oauth
resource "authentik_source_plex" "plex" {
  name                = "Plex"
  slug                = "plex"
  client_id           = local.authentik_plex_client_id
  plex_token          = local.authentik_plex_token
  authentication_flow  = data.authentik_flow.default-source-authentication.id
  enrollment_flow      = authentik_flow.enrollment-invitation.uuid
  allow_friends       = true
  allowed_servers = [
    local.authentik_plex_client_id
  ]
}
