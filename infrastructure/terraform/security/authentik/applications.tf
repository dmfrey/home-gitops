locals {
  oauth_apps = [
    "grafana",
    "spring-dev"
  ]
}

# Step 1: Retrieve secrets from Bitwarden
data "bitwarden_secret" "application" {
  for_each = toset(local.oauth_apps)
  key      = each.key
}

# Step 2: Parse the secrets using regex to extract client_id and client_secret
locals {
  parsed_secrets = {
    for app, secret in data.bitwarden_secret.application : app => {
      secret_data         = jsondecode(secret.value[0])
      client_id           = local.secret_data["AUTHENTIK_CLIENT_ID"].value
      client_secret       = local.secret_data["AUTHENTIK_CLIENT_SECRET"].value
    }
  }
}

locals {
  applications = {
    grafana = {
      client_id     = local.parsed_secrets["grafana"].client_id
      client_secret = local.parsed_secrets["grafana"].client_secret
      group         = authentik_group.monitoring.name
      icon_url      = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/grafana.png"
      redirect_uri  = "https://grafana.${var.cluster_domain}/login/generic_oauth"
      launch_url    = "https://grafana.${var.cluster_domain}/login/generic_oauth"
    },
    spring-dev = {
      client_id     = local.parsed_secrets["spring_dev"].client_id
      client_secret = local.parsed_secrets["spring_dev"].client_secret
      group         = authentik_group.developer.name
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
  authorization_flow     = authentik_flow.provider-authorization-implicit-consent.uuid
  authentication_flow    = authentik_flow.authentication.uuid
  invalidation_flow      = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings     = data.authentik_property_mapping_provider_scope.oauth2.ids
  access_token_validity = "hours=4"
  signing_key           = data.authentik_certificate_key_pair.generated.id
  redirect_uris         = [each.value.redirect_uri]
}

resource "authentik_application" "application" {
  for_each           = local.applications
  name               = title(each.key)
  slug               = each.key
  protocol_provider  = authentik_provider_oauth2.oauth2[each.key].id
  group              = each.value.group
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
#   authorization_flow    = data.authentik_flow.default-authorization-flow.id
#   authentication_flow   = authentik_flow.homelab5767-authentication.uuid
#   invalidation_flow      = data.authentik_flow.default-provider-invalidation-flow.id
# }

# resource "authentik_application" "proxy_apps" {
#   for_each          = authentik_provider_proxy.proxy_providers
#   name              = each.value.name
#   slug              = replace(replace(lower(each.value.name), " ", "-"), "[^a-z0-9-]", "")
#   group             = var.proxy_applications[each.key].group
#   meta_launch_url   = each.value.external_host
#   protocol_provider = each.value.id
# }

# resource "authentik_service_connection_kubernetes" "local" {
#   name  = "Local"
#   local = true
# }

# resource "authentik_outpost" "outpost" {
#   name               = "homelab5767 Outpost"
#   service_connection = authentik_service_connection_kubernetes.local.id
#   protocol_providers = [for proxy in authentik_provider_proxy.proxy_providers : proxy.id]
#   config = jsonencode({
#     log_level : "debug"
#     authentik_host : format(var.authentik_url)
#     authentik_host_insecure : false
#     authentik_host_browser : var.authentik_host
#     object_naming_template : "ak-outpost-%(name)s"
#     kubernetes_replicas : 1
#     kubernetes_namespace : "security"
#     kubernetes_ingress_annotations : {
#       "cert-manager.io/cluster-issuer" : "letsencrypt-prod"
#     }
#     kubernetes_ingress_secret_name : "authentik-outpost-tls"
#     kubernetes_service_type : "ClusterIP"
#     kubernetes_disabled_components : [
#       "traefik middleware"
#     ]
#     # kubernetes_ingress_class_name : "external"
#   })
# }

# resource "authentik_provider_oauth2" "oauth2_providers" {
#   for_each              = var.oauth2_applications
#   name                  = each.key
#   access_token_validity = "hours=1"
#   client_id             = each.value.client_id
#   client_secret         = sensitive(each.value.client_secret)
#   authorization_flow     = data.authentik_flow.default-authorization-flow.id
#   authentication_flow    = authentik_flow.homelab5767-authentication.uuid
#   invalidation_flow      = data.authentik_flow.default-provider-invalidation-flow.id
#   redirect_uris         = each.value.redirect_uris
#   signing_key           = data.authentik_certificate_key_pair.default-certificate.id
#   property_mappings     = data.authentik_property_mapping_provider_scope.scopes.ids
# }

# resource "authentik_application" "oauth2_apps" {
#   for_each          = authentik_provider_oauth2.oauth2_providers
#   name              = each.value.name
#   slug              = replace(replace(lower(each.value.name), " ", "-"), "[^a-z0-9-]", "")
#   group             = var.oauth2_applications[each.key].group
#   meta_launch_url   = var.oauth2_applications[each.key].url
#   protocol_provider = each.value.id
# }
