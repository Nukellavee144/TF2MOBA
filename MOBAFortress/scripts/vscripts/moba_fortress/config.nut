PrecacheModel("models/bots/scout/bot_scout.mdl")
PrecacheModel("models/bots/soldier/bot_soldier.mdl")
PrecacheModel("models/bots/pyro/bot_pyro.mdl")
PrecacheModel("models/bots/demo/bot_demo.mdl")
PrecacheModel("models/bots/heavy/bot_heavy.mdl")
PrecacheModel("models/bots/engineer/bot_engineer.mdl")
PrecacheModel("models/bots/medic/bot_medic.mdl")
PrecacheModel("models/bots/sniper/bot_sniper.mdl")
PrecacheModel("models/bots/spy/bot_spy.mdl")

PrecacheModel("models/bots/scout_boss/bot_scout_boss.mdl")
PrecacheModel("models/bots/soldier_boss/bot_soldier_boss.mdl")
PrecacheModel("models/bots/pyro_boss/bot_pyro_boss.mdl")
PrecacheModel("models/bots/demo_boss/bot_demo_boss.mdl")
PrecacheModel("models/bots/heavy_boss/bot_heavy_boss.mdl")

//Giant bot idle sounds
world.PrecacheScriptSound("MVM.GiantScoutLoop")
world.PrecacheSoundScript("MVM.GiantSoldierLoop")
world.PrecacheSoundScript("MVM.GiantPyroLoop")
world.PrecacheSoundScript("MVM.GiantDemomanLoop")
world.PrecacheSoundScript("MVM.GiantHeavyLoop")

//Footstep Sounds
world.PrecacheSoundScript("MVM.BotStep")
world.PrecacheSoundScript("MVM.GiantSoldierStep")
world.PrecacheSoundScript("MVM.GiantHeavyStep")

::SCOUT_MODEL <- "models/bots/scout/bot_scout.mdl"
::SOLDIER_MODEL <- "models/bots/soldier/bot_soldier.mdl"
::PYRO_MODEL <- "models/bots/pyro/bot_pyro.mdl"
::DEMO_MODEL <- "models/bots/demo/bot_demo.mdl"
::HEAVY_MODEL <- "models/bots/heavy/bot_heavy.mdl"
::ENGINEER_MODEL <- "models/bots/engineer/bot_engineer.mdl"
::MEDIC_MODEL <- "models/bots/medic/bot_medic.mdl"
::SNIPER_MODEL <- "models/bots/sniper/bot_sniper.mdl"
::SPY_MODEL <- "models/bots/spy/bot_spy.mdl"

::GIANT_SCOUT_MODEL <- "models/bots/scout_boss/bot_scout_boss.mdl"
::GIANT_SOLDIER_MODEL <- "models/bots/soldier_boss/bot_soldier_boss.mdl"
::GIANT_PYRO_MODEL <- "models/bots/pyro_boss/bot_pyro_boss.mdl"
::GIANT_DEMO_MODEL <- "models/bots/demo_boss/bot_demo_boss.mdl"
::GIANT_HEAVY_MODEL <- "models/bots/heavy_boss/bot_heavy_boss.mdl"
::GIANT_ENGINEER_MODEL <- ENGINEER_MODEL //These guys don't have boss models :(
::GIANT_MEDIC_MODEL <- MEDIC_MODEL
::GIANT_SNIPER_MODEL <- SNIPER_MODEL
::GIANT_SPY_MODEL <- SPY_MODEL

::GIANT_SCOUT_SOUND_LOOP <- "MVM.GiantScoutLoop"
::GIANT_SOLDIER_SOUND_LOOP <- "MVM.GiantSoldierLoop"
::GIANT_PYRO_SOUND_LOOP <- "MVM.GiantPyroLoop"
::GIANT_DEMO_SOUND_LOOP <- "MVM.GiantDemomanLoop"
::GIANT_HEAVY_SOUND_LOOP <- "MVM.GiantHeavyLoop"
::GIANT_ENGINEER_SOUND_LOOP <- ""
::GIANT_MEDIC_SOUND_LOOP <- ""
::GIANT_SNIPER_SOUND_LOOP <- ""
::GIANT_SPY_SOUND_LOOP <- ""

//Towers
world.PrecacheSoundScript("misc/rd_robot_explosion01.wav")

::TOWER_EXPLOSION_SOUND <- "misc/rd_robot_explosion01.wav"
