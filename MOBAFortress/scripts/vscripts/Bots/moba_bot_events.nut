// Made by Mikusch, special thanks to ficool2 for assistance
// https://steamcommunity.com/profiles/76561198071478507

const DAMAGE_EVENTS_ONLY = 1

function OnPostSpawn()
{
	AddThinkToEnt(self, "UpdateBots")
}

function UpdateBots()
{
	if (!("nextbots" in getroottable()))
		return

	// Remove any invalids
	nextbots = nextbots.filter(function(index, nextbot) {
		return nextbot != null && nextbot.IsValid()
	})

	foreach (nextbot in nextbots)
		nextbot.GetScriptScope().nextbot.Update()

	return 0.1
}

function OnGameEvent_npc_hurt(params)
{
	if (!("nextbots" in getroottable()))
		return

	local npc = EntIndexToHScript(params.entindex)
    local attacker_player = GetPlayerFromUserID(params.attacker_player)


	if (nextbots.find(npc) != null && params.health - params.damageamount <= 0) //On NPC Death
	{
		// Prevent death
		NetProps.SetPropInt(npc, "m_takedamage", DAMAGE_EVENTS_ONLY)

		// Spawn fancy gibs instead of just disappearing
		local gibs = SpawnEntityFromTable("prop_dynamic",
		{
			model = npc.GetModelName(),
			origin = npc.GetOrigin(),
			angles = npc.GetAbsAngles(),
			skin = npc.GetSkin()
		})
		EntFireByHandle(gibs, "Break", null, 0, null, null)

		local index = nextbots.find(npc)
		if (index != null)
			nextbots.remove(index)

		// Actually remove NPC
		npc.Kill()
	}
}

// Round restart
function OnGameEvent_scorestats_accumulated_update(params)
{
	if (!("nextbots" in getroottable()))
		return

	nextbots.clear()
}

function OnScriptHook_OnTakeDamage(params)
{
	if (!("nextbots" in getroottable()))
		return;

	local victim = params.const_entity
    local inflictor = params.inflictor

	if (nextbots.find(victim) == null) return //Stop if we don't have a victim

	// Save the damage force into the bot's data
	victim.GetScriptScope().nextbot.damage_force = params.damage_force;

	// Avoid miniguns and sentry guns shredding us!
	if (params.weapon != null && params.weapon.GetClassname() == "tf_weapon_minigun")
		params.damage *= 0.6

	else if (inflictor != null && inflictor.GetClassname() == "obj_sentrygun")
		params.damage *= 0.5

	else if (params.weapon != null && params.weapon.GetClassname() == "tf_weapon_knife")
	{
		if (!inflictor.GetScriptScope().CanBackstabBot) return //If the Spy detected we could backstab the bot, apply backstab stuff

		//Play Backstab animation
		local viewModel = NetProps.GetPropEntity(inflictor, "m_hViewModel")
		viewModel.ResetSequence(viewModel.LookupSequence("knife_backstab"))

		//Deal backstab damage
		params.crit_type = 2
		params.damage_type = params.damage_type | Constants.FDmgType.DMG_ACID
		params.damage = victim.GetMaxHealth() * 2

	}

	else if (params.weapon != null && params.weapon.GetClassname() == "tf_weapon_sniperrifle")
	{
		local lastHitPart = NetProps.GetPropInt(victim, "m_LastHitGroup");
		printl(lastHitPart)

		if (lastHitPart == Constants.EHitGroup.HITGROUP_HEAD)
		{
			params.crit_type = 2
			params.damage_type = params.damage_type | Constants.FDmgType.DMG_ACID;
		}
	}
}

    // if (ent.IsPlayer() && HasBotScript(inf) && params.damage_type == 1)
    // {
	// 	// Don't crush the player if a bot pushes them into a wall
    //     params.damage = 0;
    // }

    //Make bots take headshots


__CollectGameEventCallbacks(this)