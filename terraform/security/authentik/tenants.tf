data "authentik_tenant" "authentik-default" {
  domain = "authentik-default"
}

resource "authentik_tenant" "homelab5767" {
  domain              = var.external_domain
  default             = false
  branding_title      = "homelab5767"
  flow_authentication = authentik_flow.homelab5767-authentication.uuid
  flow_invalidation   = data.authentik_flow.default-invalidation-flow.id
  flow_user_settings  = data.authentik_flow.default-user-settings-flow.id
  branding_logo       = "/media/branding/homelab5767-logo.svg"
  branding_favicon    = "/media/branding/homelab5767-favicon.png"
}
