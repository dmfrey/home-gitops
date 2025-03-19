

# # Step 1: Retrieve secrets from 1Password
# module "onepassword_users" {
#   source   = "github.com/dmfrey/terraform-1password-item"
#   vault    = "homelab5767"
#   item     = "users"
# }

# locals {
#   users = {
#     dmfrey = {
#       name = module.onepassword_users.fields["USERS_DMFREY_NAME"]
#       email = module.onepassword_users.fields["USERS_DMFREY_EMAIL"]
#       password = module.onepassword_users.fields["USERS_DMFREY_PASSWORD"]
#       groups = [
#         data.authentik_group.akadmins.id,
#         data.authentik_group.ai.id,
#         data.authentik_group.developers.id,
#         data.authentik_group.downloads.id,
#         data.authentik_group.games.id,
#         data.authentik_group.home.id,
#         data.authentik_group.infrastructure.id,
#         data.authentik_group.media.id,
#         data.authentik_group.monitoring.id,
#         data.authentik_group.grafana_admin.id
#       ]
#     },
#     sdfrey = {
#       name = module.onepassword_users.fields["USERS_SDFREY_NAME"]
#       email = module.onepassword_users.fields["USERS_SDFREY_EMAIL"]
#       password = module.onepassword_users.fields["USERS_SDFREY_PASSWORD"]
#       groups = [
#         data.authentik_group.ai.id,
#         data.authentik_group.downloads.id,
#         data.authentik_group.games.id,
#         data.authentik_group.home.id,
#         data.authentik_group.media.id,
#       ]
#     },
#     cgfrey = {
#       name = module.onepassword_users.fields["USERS_CGFREY_NAME"]
#       email = module.onepassword_users.fields["USERS_CGFREY_EMAIL"]
#       password = module.onepassword_users.fields["USERS_CGFREY_PASSWORD"]
#       groups = [
#         data.authentik_group.ai.id,
#         data.authentik_group.downloads.id,
#         data.authentik_group.games.id,
#         data.authentik_group.home.id,
#         data.authentik_group.media.id,
#       ]
#     },
#     mkfrey = {
#       name = module.onepassword_users.fields["USERS_MKFREY_NAME"]
#       email = module.onepassword_users.fields["USERS_MKFREY_EMAIL"]
#       password = module.onepassword_users.fields["USERS_MKFREY_PASSWORD"]
#       groups = [
#         data.authentik_group.ai.id,
#         data.authentik_group.downloads.id,
#         data.authentik_group.games.id,
#         data.authentik_group.home.id,
#         data.authentik_group.media.id,
#       ]
#     }
#   }
# }

# resource "authentik_user" "users" {
#   for_each       = local.users
#   username       = each.key
#   name           = each.value["name"]
#   email          = each.value["email"]
#   password       = each.value["password"]
#   groups         = each.value["groups"]
#   #   for desired_group in each.value["groups"] :
#   #   data.authentik_group.lookup_by_name[desired_group].id
#   # ]

#   # depends_on = [
#   #   authentik_group.developers,
#   #   authentik_group.infrastructure,
#   #   authentik_group.grafana_admin,
#   #   authentik_group.monitoring,
#   #   authentik_group.users,
#   #   authentik_group.downloads,
#   #   authentik_group.home
#   # ]
# }

# data "authentik_group" "akadmins" {
#   name = "authentik Admins"
# }

# data "authentik_group" "ai" {
#   name = "AI"
# }

# data "authentik_group" "developers" {
#   name = "Developers"
# }

# data "authentik_group" "downloads" {
#   name = "Downloads"
# }

# data "authentik_group" "games" {
#   name = "Games"
# }

# data "authentik_group" "home" {
#   name = "Home"
# }

# data "authentik_group" "infrastructure" {
#   name = "Infrastructure"
# }

# data "authentik_group" "media" {
#   name = "Media"
# }

# data "authentik_group" "monitoring" {
#   name = "Monitoring"
# }

# data "authentik_group" "grafana_admin" {
#   name = "Grafana Admins"
# }

# # output "var_users" {
# #   value = var.users
# # }
