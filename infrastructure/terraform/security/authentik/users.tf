
resource "authentik_user" "users" {
  for_each       = var.users
  username       = each.key
  name           = each.value["name"]
  email          = each.value["email"]
  password       = each.value["password"]
  groups_by_name = each.value["groups"]
  # groups         = [
  #   for desired_group in each.value["groups"] :
  #   data.authentik_group.lookup_by_name[desired_group].id
  # ]

  depends_on = [
    authentik_group.developers,
    authentik_group.infrastructure,
    authentik_group.grafana_admin,
    authentik_group.monitoring,
    authentik_group.users,
    authentik_group.downloads,
    authentik_group.home
  ]
}

data "authentik_user" "akadmin" {
  username = "akadmin"
}

# output "var_users" {
#   value = var.users
# }
