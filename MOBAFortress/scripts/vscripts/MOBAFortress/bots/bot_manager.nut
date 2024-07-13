

function SpawnSoldierBot(spawnPoint = null, team = TF_TEAM_NEU)
{
    if (!spawnPoint)  //We need a place to spawn this bad boy

    soldier = SpawnEntityFromTable("base_boss",
    {
        origin = spawnPoint.GetOrigin(),
        angles = spawnPoint.GetAbsAngles(),
        vscripts = "moba_fortress/bots/bot_soldier/bot_soldier.nut",
        thinkfunction = "SoldierThink",
		playbackrate = 1.0,
        targetname = "soldierbot",
        TeamNum = team
    })

    local hp = 1000 + SOLDIER_HEALTH_BASE + SOLDIER_HEALTH_ADD_PER_PLAYER * GetAllPlayers().len();
    soldier.SetHealth(hp);
    soldier.SetModelScale(SOLDIER_SCALE, -1)
    soldier.SetMaxHealth(hp);
    soldier.SetModelSimple(SOLDIER_MODEL);
    soldier.SetPlaybackRate(1.0);

    nextbots.append(soldier);

    return soldier
}