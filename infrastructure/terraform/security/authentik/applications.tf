
locals {
  oauth_apps = [
    "grafana",
    "spring-dev"
  ]
}

# Step 1: Retrieve secrets from 1Password
module "onepassword_application" {
  for_each = toset(local.oauth_apps)
  source   = "github.com/dmfrey/terraform-1password-item"
  vault    = "homelab5767"
  item     = each.key
}

# Step 2: Parse the secrets using regex to extract client_id and client_secret
locals {
  applications = {
    grafana = {
      client_id     = module.onepassword_application["grafana"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["grafana"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "monitoring"
      icon_url      = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/grafana.png"
      redirect_uri  = "https://grafana.${var.cluster_domain}/login/generic_oauth"
      launch_url    = "https://grafana.${var.cluster_domain}/login/generic_oauth"
    },
    spring-dev = {
      client_id     = module.onepassword_application["spring-dev"].fields["AUTHENTIK_CLIENT_ID"]
      client_secret = module.onepassword_application["spring-dev"].fields["AUTHENTIK_CLIENT_SECRET"]
      group         = "monitoring"
      icon_url      = "https://raw.githubusercontent.com/dmfrey/home-gitops/main/docs/src/assets/icons/spring-boot.png"
      redirect_uri  = "https://spring-dev-gateway.${var.cluster_domain}/login/oauth2/code/sso"
      launch_url    = "https://spring-dev-gateway.${var.cluster_domain}/"
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
  property_mappings     = data.authentik_property_mapping_provider_scope.oauth2.ids
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
#     authentik_host_browser : "https://auth.${var.cluster_domain}"
#     object_naming_template : "ak-outpost-%(name)s"
#     kubernetes_replicas : 2
#     kubernetes_namespace : "security"
#     kubernetes_ingress_annotations : {
#       "cert-manager.io/cluster-issuer" : "letsencrypt-prod",
#       "nginx.ingress.kubernetes.io/cors-allow-credentials": "true",
#       "nginx.ingress.kubernetes.io/cors-allow-origin": "https://${var.cluster_domain}",
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
