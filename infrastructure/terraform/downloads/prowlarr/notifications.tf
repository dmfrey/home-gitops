# Alerts when an indexer goes unhealthy/into backoff (e.g. the BT.etree /
# Uindex Cloudflare-block incident) instead of only finding out when a
# downstream *arr app fails to search it. Reuses the Alertmanager Pushover
# app/token rather than a dedicated Prowlarr app.
resource "prowlarr_notification_pushover" "pushover" {
  name = "Pushover"

  on_grab                = false
  on_health_issue        = true
  on_health_restored     = true
  on_application_update  = false

  include_health_warnings = false
  include_manual_grabs    = false

  user_key = var.PUSHOVER_USER_KEY
  api_key  = var.ALERTMANAGER_PUSHOVER_TOKEN
}
