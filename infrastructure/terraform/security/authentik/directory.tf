
data "authentik_group" "admins" {
  name = "authentik Admins"
}

resource "authentik_group" "developers" {
  name         = "Developers"
  is_superuser = false
}

resource "authentik_group" "infrastructure" {
  name         = "Infrastructure"
  is_superuser = false
}

resource "authentik_group" "grafana_admin" {
  name         = "Grafana Admins"
  is_superuser = false
}

resource "authentik_group" "monitoring" {
  name         = "Monitoring"
  is_superuser = false
  parent       = resource.authentik_group.grafana_admin.id
}

resource "authentik_group" "users" {
  name         = "Users"
  is_superuser = false
}

resource "authentik_group" "downloads" {
  name         = "Downloads"
  is_superuser = false
  parent       = resource.authentik_group.users.id
}

resource "authentik_group" "home" {
  name         = "Home"
  is_superuser = false
  parent       = resource.authentik_group.users.id
}

data "authentik_groups" "all" {

}

output all{
  value = data.authentik_groups.all
  description = "The list of registered authentik groups"
}

output all_groups{
  value = data.authentik_groups.all.groups
  description = "The registered authentik groups"
}

data "authentik_group" "lookup_by_application" {
  for_each = local.applications
  name     = each.value.group
}

data "authentik_group" "lookup_by_name" {
  for_each = {
    for group in data.authentik_groups.all.groups:
      group.name => group
  }
  name = each.value.name
}

output monitoring{
  value = data.authentik_group.lookup_by_name("Monitoring")
  description = "Lookup the 'Monitoring' group"
}

resource "authentik_policy_binding" "application_policy_binding" {
  for_each = local.applications

  target = authentik_application.application[each.key].uuid
  group  = data.authentik_group.lookup_by_application[each.key].id
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
