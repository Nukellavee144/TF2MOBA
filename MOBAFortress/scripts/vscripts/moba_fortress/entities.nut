::main_script <- this;

::nextbots <- []; //List of all bots

::red_minion_spawners <- [];
::blu_minion_spawners <- [];
::neutral_minion_spawners <- [];

::red_minion_startingpaths <- [];
::blu_minion_startingpaths <- [];
::neutral_minion_startingpaths <- [];

GetAllMinionSpawners <-function()
{
  for (local spawns; spawns = Entities.FindByName(spawns, "minion_spawn*");)
  {
    local spawnName = spawns.GetName()

    if (startswith(spawnName, "minion_spawn_red"))
      red_minion_spawners.append(spawns)
    else if (startswith(spawnName, "minion_spawn_blu"))
      blu_minion_spawners.append(spawns)
    else
      neutral_minion_spawners.append(spawns)
  }

  red_minion_spawners.sort()
  blu_minion_spawners.sort()
  neutral_minion_spawners.sort()
}


GetAllMinionStartingPaths <- function()
{
  for (local path; path = Entities.FindByName(path, "minion_path*");)
  {
    local pathName = path.GetName()
    if (!endswith(pathName, "_0")) continue //Only grab starting paths

    if (startswith(pathName, "minion_path_red"))
      red_minion_startingpaths.append(path)
    else if (startswith(pathName, "minion_path_blu"))
      blu_minion_startingpaths.append(path)
    else
      neutral_minion_startingpaths.append(path)
  }

  red_minion_startingpaths.sort()
  blu_minion_startingpaths.sort()
  neutral_minion_startingpaths.sort()
}

GetAllMinionSpawners()
GetAllMinionStartingPaths()

DebugDrawPathPairs <- function()
{
    printl("Debugging paths")

    foreach (spawn in red_minion_spawners)
    {
        foreach (path in red_minion_startingpaths)
        {
            if (path == spawn.GetMoveParent())
            {
                printl("Pairing " + path + " and " + spawn)
                DebugDrawLine(spawn.GetOrigin(), path.GetOrigin(), 255, 150, 0, false, 100)
            }
        }
    }

    foreach (spawn in blu_minion_spawners)
    {
        printl(spawn)
        foreach (path in blu_minion_startingpaths)
        {
            printl(path + " " + spawn.GetMoveParent())
            if (path == spawn.GetMoveParent())
            {
                printl("Pairing " + path + " and " + spawn)
                DebugDrawLine(spawn.GetOrigin(), path.GetOrigin(), 0, 150, 255, false, 100)
            }
        }
    }
}

DebugDrawPathPairs()

//::tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");


