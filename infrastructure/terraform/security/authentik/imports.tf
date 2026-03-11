## Policies
import {
  to = authentik_policy_password.password-complexity
  id = "a6e0aa18-a10f-4ab5-a257-5d368ce9200c"
}

import {
  to = authentik_policy_expression.user-settings-authorization
  id = "e58fe041-c274-49c9-9441-6da2468f7233"
}

## Scope mappings
import {
  to = authentik_property_mapping_provider_scope.email_verified
  id = "f5ec1825-a323-437d-b40a-32f755a752f1"
}

import {
  to = authentik_property_mapping_provider_scope.groups
  id = "f4fe3b05-b374-47a3-9ca7-76d243a01303"
}

## Groups
import {
  to = authentik_group.grafana_admin
  id = "ab3db119-b574-4273-b08f-49a2b9ca6926"
}

import {
  to = authentik_group.default["ai"]
  id = "74d1f55e-9431-4708-8d0c-207f88079e75"
}

import {
  to = authentik_group.default["developers"]
  id = "5cc26951-4abc-4feb-bb52-508824e51290"
}

import {
  to = authentik_group.default["downloads"]
  id = "688abfc6-1f2b-4439-a8a0-747b36115dc3"
}

import {
  to = authentik_group.default["games"]
  id = "71a3cb71-af91-4ed5-af15-a4aef04999c7"
}

import {
  to = authentik_group.default["home"]
  id = "b81a4914-3d84-4276-ae76-25ec03fc5ee5"
}

import {
  to = authentik_group.default["infrastructure"]
  id = "fdd34249-3f1d-431e-b31e-07657d04abe1"
}

import {
  to = authentik_group.default["monitoring"]
  id = "b02b5459-80c0-4a32-a8e7-05977bd4bd5a"
}

import {
  to = authentik_group.default["media"]
  id = "9bfacb7e-7001-40a5-a003-94bea3ed6547"
}

import {
  to = authentik_group.default["users"]
  id = "6bcb1baa-b756-4136-8606-aaf0e1b1b1c7"
}

## Plex source
import {
  to = authentik_source_plex.plex
  id = "plex"
}

## Users
import {
  to = authentik_user.Dan
  id = "8"
}

import {
  to = authentik_user.Steph
  id = "9"
}

import {
  to = authentik_user.Camdyn
  id = "7"
}

import {
  to = authentik_user.Molly
  id = "10"
}

import {
  to = authentik_user.Tony
  id = "40"
}

## Prompt fields
import {
  to = authentik_stage_prompt_field.username
  id = "b0fbff42-55cd-45fc-ad23-922b59a67dbb"
}

import {
  to = authentik_stage_prompt_field.name
  id = "635b44f1-d0a1-4efa-80e0-dff3f0c69d41"
}

import {
  to = authentik_stage_prompt_field.email
  id = "31e0c74d-b3b0-407b-aaa7-d463ba584e86"
}

import {
  to = authentik_stage_prompt_field.locale
  id = "188c936e-9972-45f7-a7fc-edba940dd90b"
}

import {
  to = authentik_stage_prompt_field.password
  id = "b7be3c4c-6d25-41dc-8bee-140519a65f31"
}

import {
  to = authentik_stage_prompt_field.password-repeat
  id = "ebff97df-566a-43b5-98b7-033cca448113"
}

## Stages
import {
  to = authentik_stage_identification.authentication-identification
  id = "bb15a6d8-3c16-4a60-afae-abace35dabe7"
}

import {
  to = authentik_stage_password.authentication-password
  id = "162321aa-1a04-4e49-9b9f-174bd1f75a73"
}

import {
  to = authentik_stage_authenticator_validate.authentication-mfa-validation
  id = "bf6949ad-2528-47de-8ea8-75e36e53ce0d"
}

import {
  to = authentik_stage_user_login.authentication-login
  id = "33aa9c49-0eea-4e09-9b73-0baee3ffc3cc"
}

import {
  to = authentik_stage_user_logout.invalidation-logout
  id = "2b860ced-0274-451e-826f-6a6c0f060130"
}

import {
  to = authentik_stage_identification.recovery-identification
  id = "dfb9fc4f-79d2-4728-b4e2-57982394250f"
}

import {
  to = authentik_stage_email.recovery-email
  id = "2525878a-61a3-403b-b067-288f96085f57"
}

import {
  to = authentik_stage_prompt.password-change-prompt
  id = "dddd3b63-461d-44a7-9cd7-525113810076"
}

import {
  to = authentik_stage_user_write.password-change-write
  id = "3acd9ae1-be07-422e-af0a-f14e2e4540d1"
}

import {
  to = authentik_stage_invitation.enrollment-invitation
  id = "00154496-1762-4f58-995b-bd3b83db52d3"
}

import {
  to = authentik_stage_prompt.source-enrollment-prompt
  id = "3f432e3c-e37f-4815-9a24-fe377610bbf8"
}

import {
  to = authentik_stage_user_write.enrollment-user-write
  id = "48cc088b-5626-4f2f-b11c-dfcf0c2f5857"
}

import {
  to = authentik_stage_user_login.source-enrollment-login
  id = "18ff32ed-a68a-4325-b59e-ba6ed64b421d"
}

import {
  to = authentik_stage_prompt.user-settings
  id = "45031a78-68ed-46c7-9662-53036100e9fe"
}

import {
  to = authentik_stage_user_write.user-settings-write
  id = "6d14c88e-b58d-4030-85cf-e336c7a75de6"
}

## Flows
import {
  to = authentik_flow.authentication
  id = "authentication-flow"
}

import {
  to = authentik_flow.invalidation
  id = "invalidation-flow"
}

import {
  to = authentik_flow.recovery
  id = "password-recovery"
}

import {
  to = authentik_flow.enrollment-invitation
  id = "enrollmment-invitation"
}

import {
  to = authentik_flow.user-settings
  id = "user-settings-flow"
}

import {
  to = authentik_flow.provider-authorization-implicit-consent
  id = "provider-authorization-implicit-consent"
}

## Flow stage bindings
import {
  to = authentik_flow_stage_binding.authentication-flow-binding-00
  id = "22395d8c-4e4e-43bd-90ba-44cffacba308"
}

import {
  to = authentik_flow_stage_binding.authentication-flow-binding-10
  id = "0355ebbd-cd47-4801-95b0-259dae0f3a2b"
}

import {
  to = authentik_flow_stage_binding.authentication-flow-binding-100
  id = "a7b41cb4-1f00-4486-af6f-1f60968411c6"
}

import {
  to = authentik_flow_stage_binding.invalidation-flow-binding-00
  id = "8fc3dce8-01f5-40b2-84b7-5c3a99df6ed0"
}

import {
  to = authentik_flow_stage_binding.recovery-flow-binding-00
  id = "84b3211e-43f0-4b6e-9eee-dac1256680e8"
}

import {
  to = authentik_flow_stage_binding.recovery-flow-binding-10
  id = "b9aa73ac-e203-434c-94fa-60aa1b5ec322"
}

import {
  to = authentik_flow_stage_binding.recovery-flow-binding-20
  id = "9ec06743-a1ea-438a-a2d5-9d3ea2269590"
}

import {
  to = authentik_flow_stage_binding.recovery-flow-binding-30
  id = "9becf46f-3e3c-4538-a33e-bee824bec6d2"
}

import {
  to = authentik_flow_stage_binding.enrollment-invitation-flow-binding-00
  id = "d4b09a85-cc38-4639-bb42-1ff82768b741"
}

import {
  to = authentik_flow_stage_binding.enrollment-invitation-flow-binding-10
  id = "289abaaf-12c8-4f27-a3f7-d346bee089ef"
}

import {
  to = authentik_flow_stage_binding.enrollment-invitation-flow-binding-20
  id = "81ad5e7b-f833-4c49-bc30-1f771ee24e9b"
}

import {
  to = authentik_flow_stage_binding.enrollment-invitation-flow-binding-30
  id = "b4607d77-19ee-4ebe-94c8-701f6665cc93"
}

import {
  to = authentik_flow_stage_binding.user-settings-flow-binding-20
  id = "5c6b494c-9a16-4eff-b128-f54e0207b0ca"
}

import {
  to = authentik_flow_stage_binding.user-settings-flow-binding-100
  id = "1daeb6f3-e410-4975-91b7-63d76f04e4fa"
}

## Service connection
import {
  to = authentik_service_connection_kubernetes.local
  id = "83c19dd6-c14b-43d9-af67-13c00ca10751"
}

## Outpost
import {
  to = authentik_outpost.embedded
  id = "8d29fcf4-adfd-4f58-9938-e71db7874211"
}

## Token
import {
  to = authentik_token.homepage
  id = "homepage-token"
}

## OAuth2 providers
import {
  to = authentik_provider_oauth2.oauth2["affine"]
  id = "34"
}

import {
  to = authentik_provider_oauth2.oauth2["gatus"]
  id = "5"
}

import {
  to = authentik_provider_oauth2.oauth2["grafana"]
  id = "8"
}

import {
  to = authentik_provider_oauth2.oauth2["jellyfin"]
  id = "7"
}

import {
  to = authentik_provider_oauth2.oauth2["linkwarden"]
  id = "9"
}

import {
  to = authentik_provider_oauth2.oauth2["openweb"]
  id = "1"
}

import {
  to = authentik_provider_oauth2.oauth2["pinepods"]
  id = "6"
}

import {
  to = authentik_provider_oauth2.oauth2["romm"]
  id = "4"
}

import {
  to = authentik_provider_oauth2.oauth2["spring-dev"]
  id = "2"
}

## Applications
import {
  to = authentik_application.application["affine"]
  id = "affine"
}

import {
  to = authentik_application.application["gatus"]
  id = "gatus"
}

import {
  to = authentik_application.application["grafana"]
  id = "grafana"
}

import {
  to = authentik_application.application["jellyfin"]
  id = "jellyfin"
}

import {
  to = authentik_application.application["linkwarden"]
  id = "linkwarden"
}

import {
  to = authentik_application.application["openweb"]
  id = "openweb"
}

import {
  to = authentik_application.application["pinepods"]
  id = "pinepods"
}

import {
  to = authentik_application.application["romm"]
  id = "romm"
}

import {
  to = authentik_application.application["spring-dev"]
  id = "spring-dev"
}

## Brand
import {
  to = authentik_brand.home
  id = "500e88d0-a9c1-44c7-80a6-f19ac4ac08ef"
}

## Application policy bindings
import {
  to = authentik_policy_binding.application_policy_binding["affine"]
  id = "10b136e7-1474-4ae6-99fe-587978b078bd"
}

import {
  to = authentik_policy_binding.application_policy_binding["gatus"]
  id = "42c24e40-eb0c-488a-8a5f-88be9bdc60fd"
}

import {
  to = authentik_policy_binding.application_policy_binding["grafana"]
  id = "dfc702bc-458e-4939-b929-f1f311906fe0"
}

import {
  to = authentik_policy_binding.application_policy_binding["jellyfin"]
  id = "c65e319a-10bf-4745-9aad-e55d85b2e16d"
}

import {
  to = authentik_policy_binding.application_policy_binding["linkwarden"]
  id = "f13c2891-ef6f-42c8-8127-51c6c5a8d772"
}

import {
  to = authentik_policy_binding.application_policy_binding["openweb"]
  id = "8bff6422-fc17-4eb1-8e78-485ff1c2cf4a"
}

import {
  to = authentik_policy_binding.application_policy_binding["pinepods"]
  id = "dabd8209-46df-487d-8671-74d2edd3cd00"
}

import {
  to = authentik_policy_binding.application_policy_binding["romm"]
  id = "68b72c03-2120-4046-8675-4eb9cd8c147c"
}

import {
  to = authentik_policy_binding.application_policy_binding["spring-dev"]
  id = "8e70794e-e4b6-4eb6-bd84-c72403f0a3be"
}
