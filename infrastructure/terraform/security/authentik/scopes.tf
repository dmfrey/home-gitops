## OAuth scopes
data "authentik_property_mapping_provider_scope" "oauth2" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
    "goauthentik.io/providers/oauth2/scope-offline_access"
  ]
}

resource "authentik_property_mapping_provider_scope" "groups" {
  name       = "OAuth2 Groups Claim"
  scope_name = "profile"
  expression = <<-EOT
    return {
      "groups": [group.name for group in user.ak_groups.all()],
    }
  EOT
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
