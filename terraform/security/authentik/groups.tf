data "authentik_group" "authentik-admins" {
  name = "authentik Admins"
}

resource "authentik_group" "groups" {
  for_each = var.groups
  name     = each.value.name
  # parent       = authentik_group.groups[each.value.parent].id
  is_superuser = each.value.superuser
}
