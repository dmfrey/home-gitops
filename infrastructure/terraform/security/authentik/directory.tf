module "onepassword_users" {
  source   = "github.com/dmfrey/terraform-1password-item"
  vault    = "Kubernetes"
  item     = "users"
}

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

data "authentik_group" "grafana_admin" {
  name = "Grafana Admins"
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

resource "authentik_user" "Dan" {
  username = "dmfrey"
  name     = module.onepassword_users.fields["USERS_DMFREY_NAME"]
  email    = module.onepassword_users.fields["USERS_DMFREY_EMAIL"]
  password = module.onepassword_users.fields["USERS_DMFREY_PASSWORD"]
  groups = concat(
    [data.authentik_group.admins.id],
    [data.authentik_group.grafana_admin.id],
    values(authentik_group.default)[*].id
  )
}

resource "authentik_user" "Steph" {
  username = "sdfrey"
  name     = module.onepassword_users.fields["USERS_SDFREY_NAME"]
  email    = module.onepassword_users.fields["USERS_SDFREY_EMAIL"]
  password = module.onepassword_users.fields["USERS_SDFREY_PASSWORD"]
  groups = concat(
    values(authentik_group.default)[*].id
  )
}

resource "authentik_user" "Camdyn" {
  username = "cgfrey"
  name     = module.onepassword_users.fields["USERS_CGFREY_NAME"]
  email    = module.onepassword_users.fields["USERS_CGFREY_EMAIL"]
  password = module.onepassword_users.fields["USERS_CGFREY_PASSWORD"]
  groups = concat(
    values(authentik_group.default)[*].id
  )
}

resource "authentik_user" "Molly" {
  username = "mkfrey"
  name     = module.onepassword_users.fields["USERS_MKFREY_NAME"]
  email    = module.onepassword_users.fields["USERS_MKFREY_EMAIL"]
  password = module.onepassword_users.fields["USERS_MKFREY_PASSWORD"]
  groups = concat(
    values(authentik_group.default)[*].id
  )
}

# resource "authentik_user" "Tony" {
#   username = "adfrey"
#   name     = module.onepassword_users.fields["USERS_ADFREY_NAME"]
#   email    = module.onepassword_users.fields["USERS_ADFREY_EMAIL"]
#   password = module.onepassword_users.fields["USERS_ADFREY_PASSWORD"]
#   groups = concat(
#     values(authentik_group.default)[*].id
#   )
# }
