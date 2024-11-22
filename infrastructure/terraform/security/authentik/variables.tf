
variable "cluster_domain" {
  type      = string
  description = "Domain for Authentik"
}

variable "bw_access_token" {
  type        = string
  description = "Bitwarden Secret Manager Access token"
  sensitive   = true
}

variable "groups" {
  type = map(object({
    name        = string
    superuser   = optional(bool, true)
    parent_name = optional(string)
  }))
}

variable "users" {
  type = map(object({
    name     = string
    email    = string
    password = string
    groups   = list(string)
  }))
}

variable "oauth_applications" {
  type = map(object({
    client_id     = string
    client_secret = string
    group         = string
    icon_url      = string
    redirect_uri  = string
    launch_url    = string
  }))
}

# variable "proxy_applications" {
#   type = map(object({
#     url             = string
#     group           = string
#     skip_path_regex = optional(string)
#   }))
# }
