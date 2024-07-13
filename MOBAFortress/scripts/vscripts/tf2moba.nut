ClearGameEventCallbacks()

IncludeScript("moba_init", getroottable())

IncludeScript("Bots/moba_minion_manager")
IncludeScript("Bots/moba_bot_events", getroottable())
IncludeScript("moba_player_bot_reconsiler")
IncludeScript("wallet")
//IncludeScript("tower")

SetConvarValue("tf_base_boss_max_turn_rate", 200); // make nextbots turn faster
::nextbots <- [];
::nav_areas <- [];



// function OnPostSpawn()
// {
//     if (nav_areas.len() == 0)
// 	{
// 		local areas = {};
// 		GetAllNavAreas(areas);
// 		foreach (k, area in areas)
//         {
// 			nav_areas.append(area);
//         }

// 		AddThinkToEnt(worldspawn, "OnGameFrame");
// 	}
// }

// __CollectGameEventCallbacks(this);