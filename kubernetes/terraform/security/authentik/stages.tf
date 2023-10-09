resource "authentik_stage_identification" "davishaus-identity-stage" {
  name = "davishaus-identification"
  user_fields = [
    "username",
    "email"
  ]
  sources        = [authentik_source_plex.plex.uuid]
  password_stage = data.authentik_stage.password-stage.id
}

data "authentik_stage" "password-stage" {
  name = "default-authentication-password"
}

data "authentik_stage" "mfa-validation-stage" {
  name = "default-authentication-mfa-validation"
}

data "authentik_stage" "user-login-stage" {
  name = "default-authentication-login"
}
