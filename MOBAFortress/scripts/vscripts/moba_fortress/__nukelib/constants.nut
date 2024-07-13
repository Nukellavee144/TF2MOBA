foreach (c in [
    Constants.ETFClass,
    Constants.ETFTeam,
    Constants.ETFCond,
    Constants.FPlayer,
    Constants.FButtons,
    Constants.FDmgType,
    Constants.FSolid,
    Constants.ETFDmgCustom
])
    foreach (k, v in c)
        getroottable()[k] <- v;

::TF_TEAM_UNASSIGNED <- TEAM_UNASSIGNED;
::TF_TEAM_RED <- 2;
::TF_TEAM_BLU <- 3;
::TF_TEAM_NEU <- 0;
::TF_TEAM_SPECTATOR <- TEAM_SPECTATOR;
::TF_CLASS_HEAVY <- TF_CLASS_HEAVYWEAPONS;
::MAX_PLAYERS <- MaxClients().tointeger();