resource "prowlarr_tag" "cross_seed" {
  label = "cross-seed"
}

resource "prowlarr_indexer" "usenet_nzbplanet" {
  enable          = true
  redirect        = true
  name            = "NzbPlanet"
  implementation  = "Newznab"
  config_contract = "NewznabSettings"
  app_profile_id  = 1
  protocol        = "usenet"
  priority        = 1
  tags            = [prowlarr_tag.cross_seed.id]

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
      name: "vipExpiration"
      text_value: ""
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

resource "prowlarr_indexer" "torrent_btetree" {
  enable          = true
  name            = "BT.etree"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "definitionFile"
      text_value: "btetree"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    },
    {
      name: "sort"
      number_value: "0"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "prowlarr_indexer" "torrent_eztv" {
  enable          = true
  name            = "EZTV"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "definitionFile"
      text_value: "eztv"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "prowlarr_indexer" "torrent_knaben" {
  enable          = true
  name            = "Knaben"
  implementation  = "Knaben"
  config_contract = "NoAuthTorrentBaseSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "prowlarr_indexer" "torrent_limetorrents" {
  enable          = true
  name            = "LimeTorrents"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "definitionFile"
      text_value: "limetorrents"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    },
    {
      name: "downloadlink"
      number_value: "1"
    },
    {
      name: "downloadlink2"
      number_value: "0"
    },
    {
      name: "sort"
      number_value: "0"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "prowlarr_indexer" "torrent_showrss" {
  enable          = true
  name            = "showRSS"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "definitionFile"
      text_value: "showrss"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "prowlarr_indexer" "torrent_thepiratebay" {
  enable          = true
  name            = "The Pirate Bay"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "definitionFile"
      text_value: "thepiratebay"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "prowlarr_indexer" "torrent_torrentdownload" {
  enable          = true
  name            = "TorrentDownload"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "definitionFile"
      text_value: "torrentdownload"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    },
    {
      name: "sort"
      number_value: "1"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "prowlarr_indexer" "torrent_uindex" {
  enable          = true
  name            = "Uindex"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id]

  fields = [
    {
      name: "definitionFile"
      text_value: "uindex"
    },
    {
      name: "baseSettings.limitsUnit"
      number_value: "0"
    }
  ]

  lifecycle {
    ignore_changes = all
  }
}
