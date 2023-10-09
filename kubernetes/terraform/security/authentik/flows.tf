resource "authentik_flow" "davishaus-authentication" {
  name               = "DavisHaus Authentication Flow"
  slug               = "davishaus-authentication-flow"
  title              = "Welcome to Davishaus!"
  designation        = "authentication"
  background         = "/static/dist/assets/images/flow_background.jpg"
  compatibility_mode = false
}

locals {
  stage_bindings = {
    0 = authentik_stage_identification.davishaus-identity-stage.id
    1 = data.authentik_stage.password-stage.id
    2 = data.authentik_stage.mfa-validation-stage.id
    3 = data.authentik_stage.user-login-stage.id
  }
}

resource "authentik_flow_stage_binding" "dh-sb-identity" {
  for_each = local.stage_bindings
  target   = authentik_flow.davishaus-authentication.uuid
  stage    = each.value
  order    = each.key
}

data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-source-authentication" {
  slug = "default-source-authentication"
}

data "authentik_flow" "default-enrollment-flow" {
  slug = "default-source-enrollment"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-invalidation-flow"
}

data "authentik_flow" "default-user-settings-flow" {
  slug = "default-user-settings-flow"
}
