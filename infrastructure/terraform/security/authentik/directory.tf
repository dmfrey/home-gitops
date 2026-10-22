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

resource "authentik_group" "immich_admin" {
  name         = "Immich Admins"
  is_superuser = false
}

# Project Envoy access: operators use it, admins also manage it. Either group
# grants sign-in (see the envoy bindings below).
resource "authentik_group" "envoy_admins" {
  name         = "envoy.admins"
  is_superuser = false
}

resource "authentik_group" "envoy_operators" {
  name         = "envoy.operators"
  is_superuser = false
}

# Envoy deploy reporting (home-gitops#5605). Envoy accepts POST /api/deploys only
# from a bearer token whose `groups` claim contains envoy.deployers, which it maps
# to ROLE_DEPLOYER: a role that can report a deploy and nothing else. Operators and
# admins are deliberately not in it.
resource "authentik_group" "envoy_deployers" {
  name         = "envoy.deployers"
  is_superuser = false
}

resource "authentik_group" "default" {
  for_each     = local.authentik_groups
  name         = each.value.name
  is_superuser = false
}

resource "authentik_policy_binding" "application_policy_binding" {
  # envoy apps are gated by their own groups instead, see below.
  for_each = { for k, v in local.applications : k => v if !contains(local.envoy_apps, k) }

  target = authentik_application.application[each.key].uuid
  group  = authentik_group.default[each.value.group].id
  order  = 0
}

moved {
  from = authentik_policy_binding.envoy_admins
  to   = authentik_policy_binding.envoy_admins["envoy"]
}

moved {
  from = authentik_policy_binding.envoy_operators
  to   = authentik_policy_binding.envoy_operators["envoy"]
}

resource "authentik_policy_binding" "envoy_admins" {
  for_each = toset(local.envoy_apps)

  target = authentik_application.application[each.key].uuid
  group  = authentik_group.envoy_admins.id
  order  = 0
}

resource "authentik_policy_binding" "envoy_operators" {
  for_each = toset(local.envoy_apps)

  target = authentik_application.application[each.key].uuid
  group  = authentik_group.envoy_operators.id
  order  = 1
}

# As far as I know authentik checks the application's access policy for the user
# behind a client_credentials token too, so the deployers group is bound to the
# application that issues them; if it does not, this binding is harmless.
resource "authentik_policy_binding" "envoy_deployers" {
  target = authentik_application.application["envoy-mcp"].uuid
  group  = authentik_group.envoy_deployers.id
  order  = 2
}

# The identity behind the deploy reporter's token. authentik machine clients do not
# use a client secret: they post grant_type=client_credentials with this username and
# an app password. The app password is created by hand in the authentik UI
# (Directory > Tokens and App passwords, intent "App password", user envoy-deployer,
# no expiry) and stored in 1Password, so the secret is never in Terraform state.
# Request scope=profile: the "Group Membership" scope mapping puts `groups` in the JWT.
resource "authentik_user" "envoy_deployer" {
  username = "envoy-deployer"
  name     = "Envoy deploy reporter"
  type     = "service_account"
  path     = "service-accounts"
  groups   = [authentik_group.envoy_deployers.id]
}

resource "authentik_user" "Dan" {
  username = "dmfrey"
  name     = var.USERS_DMFREY_NAME
  email    = var.USERS_DMFREY_EMAIL
  password = var.USERS_DMFREY_PASSWORD
  groups = concat(
    [data.authentik_group.admins.id],
    [data.authentik_group.grafana_admin.id],
    [authentik_group.immich_admin.id],
    [authentik_group.envoy_admins.id],
    [authentik_group.envoy_operators.id],
    values(authentik_group.default)[*].id
  )
}

resource "authentik_user" "Steph" {
  username = "sdfrey"
  name     = var.USERS_SDFREY_NAME
  email    = var.USERS_SDFREY_EMAIL
  password = var.USERS_SDFREY_PASSWORD
  groups = [
    authentik_group.default["users"].id,
    authentik_group.default["home"].id,
    authentik_group.default["media"].id,
    authentik_group.default["games"].id,
  ]
}

resource "authentik_user" "Camdyn" {
  username = "cgfrey"
  name     = var.USERS_CGFREY_NAME
  email    = var.USERS_CGFREY_EMAIL
  password = var.USERS_CGFREY_PASSWORD
  groups = [
    authentik_group.default["users"].id,
    authentik_group.default["home"].id,
    authentik_group.default["media"].id,
    authentik_group.default["games"].id,
  ]
}

resource "authentik_user" "Molly" {
  username = "mkfrey"
  name     = var.USERS_MKFREY_NAME
  email    = var.USERS_MKFREY_EMAIL
  password = var.USERS_MKFREY_PASSWORD
  groups = [
    authentik_group.default["users"].id,
    authentik_group.default["home"].id,
    authentik_group.default["media"].id,
    authentik_group.default["games"].id,
  ]
}

resource "authentik_user" "Tony" {
  username = "adfrey"
  name     = var.USERS_ADFREY_NAME
  email    = var.USERS_ADFREY_EMAIL
  password = var.USERS_ADFREY_PASSWORD
  groups = [
    authentik_group.default["users"].id,
    authentik_group.default["home"].id,
    authentik_group.default["media"].id,
    authentik_group.default["games"].id,
  ]
}

resource "authentik_user" "Jackie" {
  username = "jlfrey"
  name     = var.USERS_JLFREY_NAME
  email    = var.USERS_JLFREY_EMAIL
  password = var.USERS_JLFREY_PASSWORD
  groups = [
    authentik_group.default["users"].id,
    authentik_group.default["home"].id,
    authentik_group.default["media"].id,
    authentik_group.default["games"].id,
  ]
}
