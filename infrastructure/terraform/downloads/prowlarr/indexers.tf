resource "prowlarr_indexer" "usenet_nzbplanet" {
  enable          = true
  name            = "NzbPlanet"
  implementation  = "Newznab"
  config_contract = "NewznabSettings"
  app_profile_id  = 1
  protocol        = "usenet"
  priority        = 1
  tags            = []

  fields = [
    {
      name: "baseUrl"
      text_value: "https://api.nzbplanet.net"
    },
    {
      name: "apiPath"
      text_value: "/api"
    },
    {
      name: "apiKey"
      sensitive_value: var.NZBPLANET_API_KEY
    },
    {
      name: "baseSettings.queryLimit"
      number_value: "20000"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    }
  ]
}