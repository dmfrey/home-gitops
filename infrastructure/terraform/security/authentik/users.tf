resource "authentik_user" "users" {
  for_each       = var.users
  name           = each.value.name
  username       = each.key
  email          = each.value.email
  groups_by_name = each.value.groups
  is_superuser   = each.value.is_superuser
}
