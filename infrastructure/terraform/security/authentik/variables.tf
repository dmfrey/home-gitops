variable "authentik_url" {
  type        = string
  description = "authentik url used to connect"
  default     = "http://authentik.security.svc.cluster.local:80"
}

variable "AUTHENTIK_BOOTSTRAP_TOKEN" {
  type        = string
  description = "authentik token used for authentication to api"
  sensitive   = true
}

variable "AUTHENTIK_PLEX_CLIENT_ID" {
  type        = string
  description = "client id to use for plex source authentication"
  sensitive   = true
}

variable "AUTHENTIK_PLEX_TOKEN" {
  type        = string
  description = "token to use for plex source authentication"
  sensitive   = true
}

variable "PLEX_SERVER_ID" {
  type        = string
  description = "ID of authorized Plex server"
  sensitive   = true
}

variable "authentik_host" {
  type        = string
  description = "public url for authentik"
}

variable "proxy_applications" {
  type = map(object({
    url             = string
    group           = string
    skip_path_regex = optional(string)
  }))
}

variable "oauth2_applications" {
  type = map(object({
    url           = string
    group         = string
    client_id     = string
    client_secret = string
    redirect_uris = list(string)
  }))
}

variable "groups" {
  type = map(object({
    name      = string
    parent    = optional(string)
    superuser = optional(bool)
  }))
}

variable "users" {
  type = map(object({
    name   = string
    email  = string
    groups = list(string)
  }))
}

variable "external_domain" {
  type      = string
  sensitive = true
}
