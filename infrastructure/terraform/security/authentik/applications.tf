
resource "authentik_provider_oauth2" "oauth2" {
  for_each              = var.oauth_applications
  name                  = each.key
  client_id             = each.value.client_id
  client_secret         = each.value.client_secret
  authorization_flow     = authentik_flow.provider-authorization-implicit-consent.uuid
  authentication_flow    = authentik_flow.authentication.uuid
  invalidation_flow      = data.authentik_flow.default-provider-invalidation-flow.id
  property_mappings     = data.authentik_property_mapping_provider_scope.oauth2.ids
  access_token_validity = "hours=4"
  signing_key           = data.authentik_certificate_key_pair.generated.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url = each.value.redirect_uri
    }
  ]
}

resource "authentik_application" "application" {
  for_each           = var.oauth_applications
  name               = title(each.key)
  slug               = each.key
  protocol_provider  = authentik_provider_oauth2.oauth2[each.key].id
  group              = each.value.group
  open_in_new_tab    = true
  meta_icon          = each.value.icon_url
  meta_launch_url    = each.value.launch_url
  policy_engine_mode = "all"

  depends_on = [
    authentik_group.developers,
    authentik_group.infrastructure,
    authentik_group.grafana_admin,
    authentik_group.monitoring,
    authentik_group.users,
    authentik_group.downloads,
    authentik_group.home
  ]

}

resource "authentik_provider_proxy" "proxy_providers" {
  for_each              = var.proxy_applications
  name                  = each.key
  mode                  = "forward_single"
  access_token_validity = "hours=1"
  external_host         = each.value.url
  skip_path_regex       = each.value.skip_path_regex
  authorization_flow     = authentik_flow.provider-authorization-implicit-consent.uuid
  authentication_flow    = authentik_flow.authentication.uuid
  invalidation_flow      = data.authentik_flow.default-provider-invalidation-flow.id
}

resource "authentik_application" "proxy_apps" {
  for_each          = authentik_provider_proxy.proxy_providers
  name              = each.value.name
  slug              = replace(replace(lower(each.value.name), " ", "-"), "[^a-z0-9-]", "")
  group             = var.proxy_applications[each.key].group
  open_in_new_tab   = true
  meta_launch_url   = each.value.external_host
  protocol_provider = each.value.id
}

resource "authentik_outpost" "outpost" {
  name               = "homelab5767 Outpost"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = [for proxy in authentik_provider_proxy.proxy_providers : proxy.id]
  config = jsonencode({
    log_level : "debug"
    authentik_host : "http://authentik-server.security.svc.cluster.local:80"
    authentik_host_insecure : false
    authentik_host_browser : "https://auth.${var.cluster_domain}"
    object_naming_template : "ak-outpost-%(name)s"
    kubernetes_replicas : 2
    kubernetes_namespace : "security"
    kubernetes_ingress_annotations : {
      "cert-manager.io/cluster-issuer" : "letsencrypt-prod",
      "nginx.ingress.kubernetes.io/cors-allow-credentials": "true",
      "nginx.ingress.kubernetes.io/cors-allow-origin": "https://${var.cluster_domain}",
      "nginx.ingress.kubernetes.io/cors-allow-methods": "PUT, GET, POST, OPTIONS, DELETE, PATCH",
      "nginx.ingress.kubernetes.io/enable-cors": "true"
    }
    kubernetes_ingress_secret_name : "authentik-outpost-tls"
    kubernetes_service_type : "ClusterIP"
    kubernetes_disabled_components : [
      "traefik middleware"
    ]
    kubernetes_ingress_class_name : "external"
  })
}
