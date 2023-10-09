data "authentik_certificate_key_pair" "default-certificate" {
  name = "authentik Self-signed Certificate"
}

data "authentik_scope_mapping" "oauth2-scopes" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

