## Authorization stages
resource "authentik_stage_identification" "authentication-identification" {
  name                      = "authentication-identification"
  user_fields               = ["username", "email"]
  case_insensitive_matching = true
  show_source_labels        = true
  show_matched_user         = false
  password_stage            = authentik_stage_password.authentication-password.id
  recovery_flow             = authentik_flow.recovery.uuid
  sources                   = [authentik_source_plex.plex.uuid]
  # Enables passkey autofill (conditional UI) on the login form — browser
  # shows available passkeys before the user types anything.
  webauthn_stage            = authentik_stage_authenticator_validate.authentication-mfa-validation.id
}

## WebAuthn / Passkey setup stage
resource "authentik_stage_authenticator_webauthn" "webauthn-setup" {
  name                     = "webauthn-setup"
  friendly_name            = "Passkey or Security Key"
  user_verification        = "preferred"
  resident_key_requirement = "preferred"
  configure_flow           = authentik_flow.webauthn-setup.uuid
}

## TOTP authenticator setup stage
resource "authentik_stage_authenticator_totp" "totp-setup" {
  name          = "totp-setup"
  friendly_name = "Authenticator App"
  digits        = "6"
  configure_flow = authentik_flow.totp-setup.uuid
}

resource "authentik_stage_password" "authentication-password" {
  name                          = "authentication-password"
  backends                      = ["authentik.core.auth.InbuiltBackend"]
  failed_attempts_before_cancel = 3
}

resource "authentik_stage_authenticator_validate" "authentication-mfa-validation" {
  name                  = "authentication-mfa-validation"
  device_classes        = ["static", "totp", "webauthn"]
  not_configured_action = "skip"
}

resource "authentik_stage_user_login" "authentication-login" {
  name = "authentication-login"
}

## Invalidation stages
resource "authentik_stage_user_logout" "invalidation-logout" {
  name = "invalidation-logout"
}

## Recovery stages
resource "authentik_stage_identification" "recovery-identification" {
  name                      = "recovery-identification"
  user_fields               = ["username", "email"]
  case_insensitive_matching = false
  show_source_labels        = false
  show_matched_user         = false
}

resource "authentik_stage_email" "recovery-email" {
  name                     = "recovery-email"
  activate_user_on_success = true
  use_global_settings      = true
  template                 = "email/password_reset.html"
  subject                  = "Password recovery"
}

resource "authentik_stage_prompt" "password-change-prompt" {
  name = "password-change-prompt"
  fields = [
    resource.authentik_stage_prompt_field.password.id,
    resource.authentik_stage_prompt_field.password-repeat.id
  ]
  validation_policies = [
    resource.authentik_policy_password.password-complexity.id
  ]
}

resource "authentik_stage_user_write" "password-change-write" {
  name                     = "password-change-write"
  create_users_as_inactive = false
}

## Invitation stages
resource "authentik_stage_invitation" "enrollment-invitation" {
  name                             = "enrollment-invitation"
  continue_flow_without_invitation = false
}

resource "authentik_stage_prompt" "source-enrollment-prompt" {
  name = "source-enrollment-prompt"
  fields = [
    resource.authentik_stage_prompt_field.username.id,
    resource.authentik_stage_prompt_field.name.id,
    resource.authentik_stage_prompt_field.email.id,
    resource.authentik_stage_prompt_field.password.id,
    resource.authentik_stage_prompt_field.password-repeat.id
  ]
  validation_policies = [
    resource.authentik_policy_password.password-complexity.id
  ]
}

resource "authentik_stage_user_write" "enrollment-user-write" {
  name                     = "enrollment-user-write"
  create_users_as_inactive = false
  create_users_group       = authentik_group.default["users"].id
}

resource "authentik_stage_user_login" "source-enrollment-login" {
  name             = "source-enrollment-login"
  session_duration = "seconds=0"
}

## User settings stages
resource "authentik_stage_prompt" "user-settings" {
  name = "user-settings"
  fields = [
    resource.authentik_stage_prompt_field.username.id,
    resource.authentik_stage_prompt_field.name.id,
    resource.authentik_stage_prompt_field.email.id,
    resource.authentik_stage_prompt_field.locale.id
  ]

  validation_policies = [
    resource.authentik_policy_expression.user-settings-authorization.id
  ]

}

resource "authentik_stage_user_write" "user-settings-write" {
  name                     = "user-settings-write"
  create_users_as_inactive = false
}
