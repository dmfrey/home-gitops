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
      text_value = "https://api.nzbplanet.net"
    },
    {
      name       = "apiPath"
      text_value = "/api"
    },
    {
      name      = "apiKey"
      set_value = var.NZBPLANET_API_KEY
    },
    {
      name       = "vipExpiration"
      text_value = "2025-02-05"
    },
    {
      name         = "baseSettings.queryLimit"
      number_value = 20000
    },
    {
      name         = "baseSettings.limitsUnit"
      number_value = 0
    }
  ]
}