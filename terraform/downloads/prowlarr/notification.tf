resource "prowlarr_notification_pushover" "pushover" {

  name                      = "pushover"

  api_key                   = var.PROWLARR_PUSHOVER_API_KEY
  user_key                  = var.PROWLARR_PUSHOVER_USER_KEY
  priority                  = 2
  retry                     = 30

  on_health_issue           = true
  on_health_restored        = true
  include_health_warnings   = true

  on_grab                   = true
  include_manual_grabs      = true

  on_application_update     = false

}