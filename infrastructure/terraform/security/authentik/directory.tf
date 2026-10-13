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
