resource "authentik_provider_proxy" "proxy_providers" {
  for_each              = var.proxy_applications
  name                  = each.key
  mode                  = "forward_single"
  access_token_validity = "hours=1"
  external_host         = each.value.url
  skip_path_regex       = each.value.skip_path_regex
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  authentication_flow   = authentik_flow.homelab5767-authentication.uuid
}

resource "authentik_application" "proxy_apps" {
  for_each          = authentik_provider_proxy.proxy_providers
  name              = each.value.name
  slug              = replace(replace(lower(each.value.name), " ", "-"), "[^a-z0-9-]", "")
  group             = var.proxy_applications[each.key].group
  meta_launch_url   = each.value.external_host
  protocol_provider = each.value.id
}

resource "authentik_service_connection_kubernetes" "local" {
  name  = "Local"
  local = true
}

resource "authentik_outpost" "outpost" {
  name               = "homelab5767 Outpost"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = [for proxy in authentik_provider_proxy.proxy_providers : proxy.id]
  config = jsonencode({
    log_level : "debug"
    authentik_host : format(var.authentik_url)
    authentik_host_insecure : false
    authentik_host_browser : var.authentik_host
    object_naming_template : "ak-outpost-%(name)s"
    kubernetes_replicas : 1
    kubernetes_namespace : "security"
    kubernetes_ingress_class_name: "external-nginx"
    kubernetes_ingress_annotations : {
      "cert-manager.io/cluster-issuer" : "letsencrypt-prod"
    }
    kubernetes_ingress_secret_name : "authentik-outpost-tls"
    kubernetes_service_type : "ClusterIP"
    kubernetes_disabled_components : [
      "traefik middleware"
    ]
    kubernetes_ingress_class_name : "nginx"
  })
}

resource "authentik_provider_oauth2" "oauth2_providers" {
  for_each              = var.oauth2_applications
  name                  = each.key
  access_token_validity = "hours=1"
  client_id             = each.value.client_id
  client_secret         = sensitive(each.value.client_secret)
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
  authentication_flow   = authentik_flow.homelab5767-authentication.uuid
  redirect_uris         = each.value.redirect_uris
  signing_key           = data.authentik_certificate_key_pair.default-certificate.id
  property_mappings     = data.authentik_scope_mapping.oauth2-scopes.ids
}

resource "authentik_application" "oauth2_apps" {
  for_each          = authentik_provider_oauth2.oauth2_providers
  name              = each.value.name
  slug              = replace(replace(lower(each.value.name), " ", "-"), "[^a-z0-9-]", "")
  group             = var.oauth2_applications[each.key].group
  meta_launch_url   = var.oauth2_applications[each.key].url
  protocol_provider = each.value.id
}
