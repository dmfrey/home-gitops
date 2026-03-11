
locals {
  applications = {
    affine = {
      client_id     = var.AFFINE_CLIENT_ID
      client_secret = var.AFFINE_CLIENT_SECRET
      group         = "home"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/affine.svg"
      redirect_uri  = "https://affine.${var.CLUSTER_DOMAIN}/oauth/callback"
      launch_url    = "https://affine.${var.CLUSTER_DOMAIN}/"
    },
    gatus = {
      client_id     = var.GATUS_CLIENT_ID
      client_secret = var.GATUS_CLIENT_SECRET
      group         = "monitoring"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/gatus.svg"
      redirect_uri  = "https://status.${var.CLUSTER_DOMAIN}/authorization-code/callback"
      launch_url    = "https://status.${var.CLUSTER_DOMAIN}/"
    },
    grafana = {
      client_id     = var.GRAFANA_CLIENT_ID
      client_secret = var.GRAFANA_CLIENT_SECRET
      group         = "monitoring"
      icon_url      = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/grafana.png"
      redirect_uri  = "https://grafana.${var.CLUSTER_DOMAIN}/login/generic_oauth"
      launch_url    = "https://grafana.${var.CLUSTER_DOMAIN}/login/generic_oauth"
    },
    jellyfin = {
      client_id     = var.JELLYFIN_CLIENT_ID
      client_secret = var.JELLYFIN_CLIENT_SECRET
      group         = "media"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/jellyfin.png"
      redirect_uri  = "https://jellyfin.${var.CLUSTER_DOMAIN}/sso/OID/redirect/Authentik"
      launch_url    = "https://jellyfin.${var.CLUSTER_DOMAIN}/"
    },
    linkwarden = {
      client_id     = var.LINKWARDEN_CLIENT_ID
      client_secret = var.LINKWARDEN_CLIENT_SECRET
      group         = "home"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/linkwarden.png"
      redirect_uri  = "https://bookmarks.${var.CLUSTER_DOMAIN}/api/v1/auth/callback/authentik"
      launch_url    = "https://bookmarks.${var.CLUSTER_DOMAIN}/"
    },
    openweb = {
      client_id     = var.OPENWEB_CLIENT_ID
      client_secret = var.OPENWEB_CLIENT_SECRET
      group         = "ai"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/openweb-ui.png"
      redirect_uri  = "https://openweb.${var.CLUSTER_DOMAIN}/oauth/oidc/callback"
      launch_url    = "https://openweb.${var.CLUSTER_DOMAIN}/"
    },
    pinepods = {
      client_id     = var.PINEPODS_CLIENT_ID
      client_secret = var.PINEPODS_CLIENT_SECRET
      group         = "media"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/pinepods.png"
      redirect_uri  = "https://podcasts.${var.CLUSTER_DOMAIN}/api/auth/callback"
      launch_url    = "https://podcasts.${var.CLUSTER_DOMAIN}/"
    },
    romm = {
      client_id     = var.ROMM_CLIENT_ID
      client_secret = var.ROMM_CLIENT_SECRET
      group         = "games"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/romm.png"
      redirect_uri  = "https://romm.${var.CLUSTER_DOMAIN}/api/oauth/openid"
      launch_url    = "https://romm.${var.CLUSTER_DOMAIN}/"
    },
    spring-dev = {
      client_id     = var.SPRING_DEV_CLIENT_ID
      client_secret = var.SPRING_DEV_CLIENT_SECRET
      group         = "developers"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/spring-boot.png"
      redirect_uri  = "https://spring-dev-gateway.${var.CLUSTER_DOMAIN}/login/oauth2/code/sso"
      launch_url    = "https://spring-dev-gateway.${var.CLUSTER_DOMAIN}/"
    }
  }

  proxy_applications = {
    excalidraw = {
      group         = "home"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/excalidraw.png"
      external_host = "https://excalidraw.${var.CLUSTER_DOMAIN}"
      launch_url    = "https://excalidraw.${var.CLUSTER_DOMAIN}/"
    }
  }
}

resource "authentik_provider_oauth2" "oauth2" {
  for_each              = local.applications
  name                  = each.key
  client_id             = each.value.client_id
  client_secret         = each.value.client_secret
  authorization_flow    = authentik_flow.provider-authorization-implicit-consent.uuid
  authentication_flow   = authentik_flow.authentication.uuid
  invalidation_flow     = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.oauth2.ids,
    [authentik_property_mapping_provider_scope.email_verified.id],
  )
  access_token_validity = "hours=4"
  signing_key           = data.authentik_certificate_key_pair.generated.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = each.value.redirect_uri,
    }
  ]
}

resource "authentik_application" "application" {
  for_each           = local.applications
  name               = title(each.key)
  slug               = each.key
  protocol_provider  = authentik_provider_oauth2.oauth2[each.key].id
  group              = authentik_group.default[each.value.group].name
  open_in_new_tab    = true
  meta_icon          = each.value.icon_url
  meta_launch_url    = each.value.launch_url
  policy_engine_mode = "all"
}

resource "authentik_provider_proxy" "proxy" {
  for_each              = local.proxy_applications
  name                  = each.key
  external_host         = each.value.external_host
  authorization_flow    = authentik_flow.provider-authorization-implicit-consent.uuid
  authentication_flow   = authentik_flow.authentication.uuid
  invalidation_flow     = data.authentik_flow.default-provider-invalidation-flow.id
  mode                  = "forward_single"
  access_token_validity = "hours=4"
}

resource "authentik_application" "proxy_application" {
  for_each           = local.proxy_applications
  name               = title(each.key)
  slug               = each.key
  protocol_provider  = authentik_provider_proxy.proxy[each.key].id
  group              = authentik_group.default[each.value.group].name
  open_in_new_tab    = true
  meta_icon          = each.value.icon_url
  meta_launch_url    = each.value.launch_url
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "proxy_application_policy_binding" {
  for_each = local.proxy_applications

  target = authentik_application.proxy_application[each.key].uuid
  group  = authentik_group.default[each.value.group].id
  order  = 0
}
