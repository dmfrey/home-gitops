resource "authentik_user" "users" {
  for_each       = var.users
  name           = each.value.name
  username       = each.key
  email          = each.value.email
  groups         = [
    for desired_group in each.value.groups :
    data.authentik_group.lookup_by_name[desired_group].id
  ]
}
