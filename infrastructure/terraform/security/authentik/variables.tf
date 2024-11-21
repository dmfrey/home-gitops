# variable "proxy_applications" {
#   type = map(object({
#     url             = string
#     group           = string
#     skip_path_regex = optional(string)
#   }))
# }

variable "cluster_domain" {
  type      = string
  description = "Domain for Authentik"
}

variable "bw_access_token" {
  type        = string
  description = "Bitwarden Secret Manager Access token"
  sensitive   = true
}

variable "users" {
  type = map(object({
    name   = string
    email  = string
    password = var.user_password
    groups = list(string)
  }))
}

variable "user_password" {
  description = "User's password"
  type = string
  sensitive = true
}
