resource "prowlarr_tag" "cross_seed" {
  label = "cross-seed"
}

resource "prowlarr_tag" "flaresolverr" {
  # Marks which indexers should route through the FlareSolverr indexer
  # proxy (indexer-proxy.tf) - currently just torrent_uindex and
  # torrent_btetree, both blocked by Cloudflare's anti-bot protection
  # without it. See prowlarr_indexer_proxy_flaresolverr.flaresolverr's
  # comment for the full incident writeup.
  label = "flaresolverr"
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

  lifecycle {
    ignore_changes = [fields]
  }
}

resource "prowlarr_indexer" "torrent_btetree" {
  enable          = true
  name            = "BT.etree"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = [prowlarr_tag.cross_seed.id, prowlarr_tag.flaresolverr.id]

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
  # Disabled 2026-07-16: served multiple fake torrents (bare .exe payloads
  # disguised as current TV episodes, some byte-identical across different
  # fake titles) that Sonarr's safety check caught before import. Actual
  # toggle lives in Prowlarr directly (lifecycle.ignore_changes below), this
  # is just to keep the declared state from being misleading.
  # cross-seed tag removed 2026-08-10: cross-seed selects indexers by tag
  # regardless of enable state, so it kept querying this disabled indexer
  # and logging "responded with code 410 when fetching caps" every cycle.
  enable          = false
  name            = "LimeTorrents"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 25
  tags            = []

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
  # Priority lowered to 50 (last resort) 2026-08-10: served two 0-byte fake
  # torrents in one day, disguised as real releases with the torrent's own
  # advertised name ending in .scr (a Windows executable extension). Sonarr
  # correctly refused to import either (no eligible video files), but this
  # keeps the indexer as fallback-only rather than tied for first choice
  # with the other torrent indexers. Actual change lives in Prowlarr
  # directly (lifecycle.ignore_changes below), this is just to keep the
  # declared state from being misleading - same pattern as
  # torrent_limetorrents below.
  #
  # Disabled 2026-10-14 (trial, review ~2026-10-21): five more malware-bait
  # torrents named "....exe" were grabbed from here on 2026-10-13. Priority is
  # only a tiebreaker, so it didn't stop them; Sonarr refused to import all
  # five. About 60 grabs in the previous 30 days came from this indexer, so
  # check how many episodes had no other source before deciding to keep it off.
  #
  # Trial concluded 2026-10-22, kept disabled: Sonarr, Radarr and Lidarr all
  # kept grabbing from the other indexers (Sonarr 194 grabs in the 8 days after
  # the switch-off, 0 from this one), and none of the 126 / 52 / 37 monitored
  # missing episodes, movies and albums aired or released after 2026-10-14.
  # Only two old Poldark (2015) episodes and two movies (The Ritual, Methodic)
  # have a grab from it in their history.
  # cross-seed tag removed 2026-10-22 (applied live in Prowlarr): cross-seed
  # selects indexers by tag regardless of enable state, so it kept asking for
  # this disabled indexer's caps and logging "responded with code 410" - same
  # as torrent_limetorrents below.
  enable          = false
  name            = "TorrentDownload"
  implementation  = "Cardigann"
  config_contract = "CardigannSettings"
  app_profile_id  = 1
  protocol        = "torrent"
  priority        = 50
  tags            = []

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
  tags            = [prowlarr_tag.cross_seed.id, prowlarr_tag.flaresolverr.id]

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
