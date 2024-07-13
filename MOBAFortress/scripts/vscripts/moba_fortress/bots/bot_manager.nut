::waveNum <- 0;

::botSpawners <- []


GetAllSpawners <- function()
{
    for (local gen; gen = Entities.FindByClassname(gen, "bot_generator");)
    {
        botSpawners.append(gen)
    }
}

::SpawnMinion <- function(spawner, loadOut)
{
    //if (!spawner) return

    foreach (spawn in botSpawners)
    {
        NetProps.SetPropString(spawn, "m_className", loadOut.tfClass)
        DoEntFire("!self", "SpawnBot", "", -1, spawn, spawn)
    }
}

GetAllSpawners()