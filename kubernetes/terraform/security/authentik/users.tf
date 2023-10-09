resource "authentik_user" "users" {
  for_each = var.users
  name     = each.value.name
  username = each.key
  email    = each.value.email
  groups = [
    for desired_groups in each.value.groups :
    authentik_group.groups[
      lookup({
        for group_key, group_val in var.groups :
        group_key => group_key
      }, desired_groups, null)
    ].id
    if contains(keys(var.groups), desired_groups)
  ]
  depends_on = [authentik_group.groups]
}
