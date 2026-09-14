# Alerts the moment a download needs manual review (e.g. a release whose
# payload turned out to be an executable instead of real media - Sonarr's
# own import-time safety check flags these as "manual interaction required"
# rather than auto-removing them, since occasionally it's a legitimate
# multi-file release with a harmless bonus .exe). Reuses the same Pushover
# app/token as Alertmanager rather than a dedicated Sonarr app - simplest
# option, still distinguishable by message content.
resource "sonarr_notification_pushover" "pushover" {
  name = "Pushover"

  on_grab                            = false
  on_download                        = false
  on_upgrade                         = false
  on_series_add                      = false
  on_series_delete                   = false
  on_episode_file_delete             = false
  on_episode_file_delete_for_upgrade = false
  on_health_issue                    = false
  on_health_restored                 = false
  on_application_update              = false
  on_manual_interaction_required     = true

  include_health_warnings = false

  user_key = var.PUSHOVER_USER_KEY
  api_key  = var.ALERTMANAGER_PUSHOVER_TOKEN
}

# Routes on-download/on-upgrade events through chaski, which reformats them
# (title, episode, client) into a richer Pushover message via its own
# dedicated app token - kept separate from the manual-interaction alert
# above since this is much higher-volume and wants independent muting.
resource "sonarr_notification_webhook" "chaski" {
  name = "chaski"

  on_grab                            = false
  on_download                        = true
  on_upgrade                         = true
  on_rename                          = false
  on_series_add                      = false
  on_series_delete                   = false
  on_episode_file_delete             = false
  on_episode_file_delete_for_upgrade = false
  on_health_issue                    = false
  on_application_update              = false
  on_manual_interaction_required     = false

  include_health_warnings = false

  url    = "http://chaski.media.svc.cluster.local:8080/hooks/sonarr-download"
  method = 1 # POST
}
