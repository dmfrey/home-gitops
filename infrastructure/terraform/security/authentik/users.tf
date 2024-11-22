
data "bitwarden_secret" "users" {
  key = "users"
}

locals {
  bw_users_secret             = jsondecode(data.bitwarden_secret.users.value)
  dmfrey_name                 = local.bw_users_secret["USERS_DMFREY_NAME"]
  dmfrey_email                = local.bw_users_secret["USERS_DMFREY_EMAIL"]
  dmfrey_password             = local.bw_users_secret["USERS_DMFREY_PASSWORD"]
  sdfrey_name                 = local.bw_users_secret["USERS_SDFREY_NAME"]
  sdfrey_email                = local.bw_users_secret["USERS_SDFREY_EMAIL"]
  sdfrey_password             = local.bw_users_secret["USERS_SDFREY_PASSWORD"]
  cgfrey_name                 = local.bw_users_secret["USERS_CGFREY_NAME"]
  cgfrey_email                = local.bw_users_secret["USERS_CGFREY_EMAIL"]
  cgfrey_password             = local.bw_users_secret["USERS_CGFREY_PASSWORD"]
  mkfrey_name                 = local.bw_users_secret["USERS_MKFREY_NAME"]
  mkfrey_email                = local.bw_users_secret["USERS_MKFREY_EMAIL"]
  mkfrey_password             = local.bw_users_secret["USERS_MKFREY_PASSWORD"]
}

locals {
  users = {
    dmfrey = {
      name = local.dmfrey_name
      email = local.dmfrey_email
      password = local.dmfrey_password
      groups = [
        authentik_group.admins.name,
        authentik_group.developers.name,
        authentik_group.infrastructure.name,
        authentik_group.monitoring.name,
        authentik_group.downloads.name,
        authentik_group.home.name
      ]
    },
    sdfrey = {
      name = local.sdfrey_name
      email = local.sdfrey_email
      password = local.sdfrey_password
      groups = []
      #   data.authentik_group.downloads.id,
      #   data.authentik_group.home.id
      # ]
    },
    cgfrey = {
      name = local.cgfrey_name
      email = local.cgfrey_email
      password = local.cgfrey_password
      groups = []
      #   data.authentik_group.downloads.id,
      #   data.authentik_group.home.id
      # ]
    },
    mkfrey = {
      name = local.mkfrey_name
      email = local.mkfrey_email
      password = local.mkfrey_password
      groups = []
      #   data.authentik_group.downloads.id,
      #   data.authentik_group.home.id
      # ]
    }
  }
}

resource "authentik_user" "users" {
  for_each       = local.users
  username       = each.key
  name           = each.value["name"]
  email          = each.value["email"]
  password       = each.value["password"]
  groups         = [
    for desired_group in each.value["groups"] :
    data.authentik_group.lookup_by_name[desired_group].id
  ]
}

output "var_users" {
  value = local.users
}
