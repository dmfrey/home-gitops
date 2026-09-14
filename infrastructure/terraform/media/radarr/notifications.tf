# Alerts the moment a download needs manual review (e.g. a release whose
# payload turned out to be an executable instead of real media - Radarr's
# own import-time safety check flags these rather than auto-removing them).
# Same pattern as sonarr/notifications.tf. Reuses the Alertmanager
# Pushover app/token rather than a dedicated Radarr app.
resource "radarr_notification_pushover" "pushover" {
  name = "Pushover"

  on_grab                          = false
  on_download                      = false
  on_upgrade                       = false
  on_movie_added                   = false
  on_movie_delete                  = false
  on_movie_file_delete             = false
  on_movie_file_delete_for_upgrade = false
  on_health_issue                  = false
  on_health_restored               = false
  on_application_update            = false
  on_manual_interaction_required   = true

  include_health_warnings = false

  user_key = var.PUSHOVER_USER_KEY
  api_key  = var.ALERTMANAGER_PUSHOVER_TOKEN
}

# Routes on-download/on-upgrade events through chaski, which reformats them
# (title, year, client) into a richer Pushover message via its own
# dedicated app token - kept separate from the manual-interaction alert
# above since this is much higher-volume and wants independent muting.
resource "radarr_notification_webhook" "chaski" {
  name = "chaski"

  on_grab                          = false
  on_download                      = true
  on_upgrade                       = true
  on_rename                        = false
  on_movie_added                   = false
  on_movie_delete                  = false
  on_movie_file_delete             = false
  on_movie_file_delete_for_upgrade = false
  on_health_issue                  = false
  on_application_update            = false
  on_manual_interaction_required   = false

  include_health_warnings = false

  url    = "http://chaski.media.svc.cluster.local:8080/hooks/radarr-download"
  method = 1 # POST
}
