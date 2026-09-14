# Alerts on download/import failures needing review. Lidarr's provider has
# no on_manual_interaction_required flag (unlike sonarr/radarr) - these two
# are the closest equivalent "something is stuck, go look" signals. Same
# pattern as sonarr/notifications.tf. Reuses the Alertmanager Pushover
# app/token rather than a dedicated Lidarr app.
resource "lidarr_notification_pushover" "pushover" {
  name = "Pushover"

  on_grab                = false
  on_upgrade             = false
  on_release_import      = false
  on_artist_delete       = false
  on_album_delete        = false
  on_health_issue        = false
  on_health_restored     = false
  on_application_update  = false
  on_download_failure    = true
  on_import_failure      = true

  include_health_warnings = false

  user_key = var.PUSHOVER_USER_KEY
  api_key  = var.ALERTMANAGER_PUSHOVER_TOKEN
}
