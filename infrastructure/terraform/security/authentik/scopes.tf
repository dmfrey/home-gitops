## OAuth scopes
data "authentik_property_mapping_provider_scope" "oauth2" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
    "goauthentik.io/providers/oauth2/scope-offline_access"
  ]
}


resource "authentik_property_mapping_provider_scope" "email_verified" {
  name       = "Email Verified Scope"
  scope_name = "email"
  expression = <<-EOT
    return {
      "email": user.email,
      "email_verified": True,
    }
  EOT
}

resource "authentik_property_mapping_provider_scope" "immich_role" {
  name       = "Immich Role Scope"
  scope_name = "immich_role"
  description = "Maps Immich Admins group membership to the immich_role claim Immich reads on account creation"
  expression = <<-EOT
    return {
      "immich_role": "admin" if user.groups.filter(name="Immich Admins").exists() else "user",
    }
  EOT
}
