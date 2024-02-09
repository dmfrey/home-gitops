resource "prowlarr_indexer" "nzbplanet" {
  enable          = true
  name            = "NzbPlanet"
  implementation  = "Newznab"
  config_contract = "NewznabSettings"
  protocol        = "usenet"
  priority        = 10
  tags            = []

  fields = [
    {
      name       = "baseUrl"
      set_value = "https://api.nzbplanet.net"
    },
    {
      name       = "apiPath"
      set_value = "/api"
    },
    {
      name      = "apiKey"
      set_value = var.NZBPLANET_API_KEY
    },
    {
      name       = "vipExpiration"
      set_value = "2025-02-05"
    },
    {
      name         = "baseSettings.queryLimit"
      set_value = 20000
    },
    {
      name         = "baseSettings.limitsUnit"
      set_value = 0
    }
  ]
}