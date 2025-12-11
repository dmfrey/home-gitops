
variable "OP_CONNECT_HOST" {
  type        = string
  description = "Oneopass Connect URL"
}

variable "OP_CONNECT_TOKEN" {
  type        = string
  description = "The path to the service account JSON for OnePassword."
  sensitive   = true
  default     = null
}

variable "CLUSTER_DOMAIN" {
  type      = string
  description = "Domain for Authentik"
}

# variable "users" {
#   type = map(object({
#     name     = string
#     email    = string
#     password = string
#     groups   = list(string)
#   }))
# }

# variable "oauth_applications" {
#   type = map(object({
#     client_id     = string
#     client_secret = string
#     group         = string
#     icon_url      = string
#     redirect_uri  = string
#     launch_url    = string
#   }))
# }

# variable "proxy_applications" {
#   type = map(object({
#     url             = string
#     group           = string
#     skip_path_regex = optional(string)
#   }))
# }

# variable "proxy_applications" {
#   type = map(object({
#     url             = string
#     group           = string
#     skip_path_regex = optional(string)
#   }))
# }
