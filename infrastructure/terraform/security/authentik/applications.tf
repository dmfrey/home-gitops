
locals {
  oauth_apps = [
    "affine",
    "gatus",
    "grafana",
    "blinko",
    "jellyfin",
    "linkwarden",
    "openweb",
    "pinepods",
    "romm",
    "spring-dev"
  ]
}

# Step 1: Retrieve secrets from 1Password
module "onepassword_application" {
  for_each = toset(local.oauth_apps)
  source   = "github.com/dmfrey/terraform-1password-item"
  vault    = "Kubernetes"
  item     = each.key
}

# Step 2: Parse the secrets using regex to extract client_id and client_secret
locals {
  applications = {
    affine = {
      client_id     = module.onepassword_application["affine"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["affine"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "home"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/affine.svg"
      redirect_uri  = "https://affine.${var.CLUSTER_DOMAIN}/oauth/callback"
      launch_url    = "https://affine.${var.CLUSTER_DOMAIN}/"
    },
    gatus = {
      client_id     = module.onepassword_application["gatus"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["gatus"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "monitoring"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/gatus.svg"
      redirect_uri  = "https://status.${var.CLUSTER_DOMAIN}/authorization-code/callback"
      launch_url    = "https://status.${var.CLUSTER_DOMAIN}/"
    },
    grafana = {
      client_id     = module.onepassword_application["grafana"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["grafana"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "monitoring"
      icon_url      = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/grafana.png"
      redirect_uri  = "https://grafana.${var.CLUSTER_DOMAIN}/login/generic_oauth"
      launch_url    = "https://grafana.${var.CLUSTER_DOMAIN}/login/generic_oauth"
    },
    blinko = {
      client_id     = module.onepassword_application["blinko"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["blinko"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "home"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/blinko.png"
      redirect_uri  = "https://notes.${var.CLUSTER_DOMAIN}/api/auth/callback/blinko"
      launch_url    = "https://notes.${var.CLUSTER_DOMAIN}/"
    },
    jellyfin = {
      client_id     = module.onepassword_application["jellyfin"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["jellyfin"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "media"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/jellyfin.png"
      redirect_uri  = "https://jellyfin.${var.CLUSTER_DOMAIN}/sso/OID/redirect/Authentik"
      launch_url    = "https://jellyfin.${var.CLUSTER_DOMAIN}/"
    },
    linkwarden = {
      client_id     = module.onepassword_application["linkwarden"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["linkwarden"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "home"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/linkwarden.png"
      redirect_uri  = "https://bookmarks.${var.CLUSTER_DOMAIN}/api/v1/auth/callback/authentik"
      launch_url    = "https://bookmarks.${var.CLUSTER_DOMAIN}/"
    },
    openweb = {
      client_id     = module.onepassword_application["openweb"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["openweb"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "ai"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/openweb-ui.png"
      redirect_uri  = "https://openweb.${var.CLUSTER_DOMAIN}/oauth/oidc/callback"
      launch_url    = "https://openweb.${var.CLUSTER_DOMAIN}/"
    },
    pinepods = {
      client_id     = module.onepassword_application["pinepods"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["pinepods"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "media"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/pinepods.png"
      redirect_uri  = "https://podcasts.${var.CLUSTER_DOMAIN}/api/auth/callback"
      launch_url    = "https://podcasts.${var.CLUSTER_DOMAIN}/"
    },
    romm = {
      client_id     = module.onepassword_application["romm"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["romm"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "games"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/romm.png"
      redirect_uri  = "https://romm.${var.CLUSTER_DOMAIN}/api/oauth/openid"
      launch_url    = "https://romm.${var.CLUSTER_DOMAIN}/"
    },
    spring-dev = {
      client_id     = module.onepassword_application["spring-dev"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["spring-dev"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "developers"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/spring-boot.png"
      redirect_uri  = "https://spring-dev-gateway.${var.CLUSTER_DOMAIN}/login/oauth2/code/sso"
      launch_url    = "https://spring-dev-gateway.${var.CLUSTER_DOMAIN}/"
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

# resource "authentik_provider_proxy" "proxy_providers" {
#   for_each              = var.proxy_applications
#   name                  = each.key
#   mode                  = "forward_single"
#   access_token_validity = "hours=1"
#   external_host         = each.value.url
#   skip_path_regex       = each.value.skip_path_regex
#   authorization_flow     = authentik_flow.provider-authorization-implicit-consent.uuid
#   authentication_flow    = authentik_flow.authentication.uuid
#   invalidation_flow      = data.authentik_flow.default-provider-invalidation-flow.id
# }

# resource "authentik_application" "proxy_apps" {
#   for_each          = authentik_provider_proxy.proxy_providers
#   name              = each.value.name
#   slug              = replace(replace(lower(each.value.name), " ", "-"), "[^a-z0-9-]", "")
#   group             = var.proxy_applications[each.key].group
#   open_in_new_tab   = true
#   meta_launch_url   = each.value.external_host
#   protocol_provider = each.value.id
# }

# resource "authentik_outpost" "outpost" {
#   name               = "homelab5767 Outpost"
#   service_connection = authentik_service_connection_kubernetes.local.id
#   protocol_providers = [for proxy in authentik_provider_proxy.proxy_providers : proxy.id]
#   config = jsonencode({
#     log_level : "debug"
#     authentik_host : "http://authentik-server.security.svc.cluster.local:80"
#     authentik_host_insecure : false
#     authentik_host_browser : "https://auth.${var.CLUSTER_DOMAIN}"
#     object_naming_template : "ak-outpost-%(name)s"
#     kubernetes_replicas : 2
#     kubernetes_namespace : "security"
#     kubernetes_ingress_annotations : {
#       "cert-manager.io/cluster-issuer" : "letsencrypt-production",
#       "nginx.ingress.kubernetes.io/cors-allow-credentials": "true",
#       "nginx.ingress.kubernetes.io/cors-allow-origin": "https://${var.CLUSTER_DOMAIN}",
#       "nginx.ingress.kubernetes.io/cors-allow-methods": "PUT, GET, POST, OPTIONS, DELETE, PATCH",
#       "nginx.ingress.kubernetes.io/enable-cors": "true"
#     }
#     kubernetes_ingress_secret_name : "authentik-outpost-tls"
#     kubernetes_service_type : "ClusterIP"
#     kubernetes_disabled_components : [
#       "traefik middleware"
#     ]
#     kubernetes_ingress_class_name : "external"
#   })
# }
