
// 0 is no team
// 1 is specator
// 2 is red
// 3 is blue

local waveNum = 0

function SpawnMinions(minionType = "", team = null,  spawner = -1)
{

    for (local i = 0; i < red_minion_spawners.len(); i++)
    {
        SoldierCreate(red_minion_spawners[i], 2, red_minion_startingpaths[i])
    }

    for (local i = 0; i < blu_minion_spawners.len(); i++)
    {
        SoldierCreate(blu_minion_spawners[i], 3, blu_minion_startingpaths[i])
    }

    for (local i = 0; i < neutral_minion_spawners.len(); i++)
    {
        SoldierCreate(neutral_minion_spawners[i], 0, neutral_minion_startingpaths[i])
    }

    waveNum++
}

function SpawnRedMinions()
{
    for (local i = 0; i < red_minion_spawners.len(); i++)
    {
        SoldierCreate(red_minion_spawners[i], 2, red_minion_startingpaths[i])
    }
}

function SpawnBluMinions()
{
    for (local i = 0; i < blu_minion_spawners.len(); i++)
    {
        SoldierCreate(blu_minion_spawners[i], 3, blu_minion_startingpaths[i])
    }
}

function ClearBots()
{
    foreach (bot in nextbots) {
        bot.Kill()
    }
}

DoIncludeScript("Bots/moba_minion_soldier", root)