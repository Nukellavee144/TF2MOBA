ClearGameEventCallbacks();

::world <- Entities.FindByClassname(null,"worldspawn")

local g_kill_pay = 10000
local g_assist_pay = 50

IncludeScript("moba_fortress/__nukelib/util.nut")
IncludeScript("moba_fortress/config.nut")
IncludeScript("moba_fortress/tower.nut")
IncludeScript("moba_fortress/bots/bot_manager.nut")
//IncludeScript("moba_fortress/minionClasses.nut")

//We use money in this gamemode as progression
GameModeUsesCurrency()
GameModeUsesUpgrades()
ForceEnableUpgrades(2)

// IncludeScript("moba_fortress/entities.nut")
// IncludeScript("moba_fortress/bots/bot_manager.nut")

::robotify <- function()
{
    if (!self) return

    //if (RandomInt(0, 2) == 0) self.AddBotTag("giant")
    local giantOrSmall = self.HasBotTag("giant") ? "GIANT_" : ""
    local classNames =
    [
        "SCOUT"
        "SNIPER"
        "SOLDIER"
        "DEMO"
        "MEDIC"
        "HEAVY"
        "PYRO"
        "SPY"
        "ENGINEER"
    ]
    local className = classNames[self.GetPlayerClass() - 1]

    local modelName = format("%s%s_MODEL", giantOrSmall, className)
    self.SetCustomModelWithClassAnimations(getroottable()[modelName])

    self.SetModelScale( self.HasBotTag("giant") ? 1.75 : 1 , 0)

    //Add giant idle sound effects
    if (self.HasBotTag("giant"))
    {
        local soundName = format("GIANT_%s_SOUND_LOOP", className)
        if (soundName == "GIANT__SOUND_LOOP") return //If they don't have a loop sound, don't add a loop sound
        EmitSoundEx({
            sound_name = getroottable()[soundName],
            channel = 4, //Body
            volume = 0.4, // 0-1
            entity = self,
            speaker_entity = self,
            flags = 1
        })
    }

    //Set Bot Player Name
    local teamName = self.GetTeam() == 2 ? "Red" : "Blue"
    local loadoutName = "$LoadoutName$"
    local botName = format("%s %s", teamName, loadoutName)
    SetFakeClientConVarValue(self, "name", botName.tostring()) //Set my name

    NetProps.SetPropIntArray(self, "m_iAmmo", 0, 3) //Remove bots metal TODO: Bots currently drop an ammo box that has 5 metal in it. Find way to stop metalbox entirely

    RemoveAllButOneWeaponSlot(self, 1) //Set weapon

    self.AddCustomAttribute("voice pitch scale", 0, -1)                         //No voice TODO: Get robot voices working. Do this via soundscript

    self.AddCustomAttribute("mod weapon blocks healing", 1 , -1)                //No healing
    self.AddCustomAttribute("crit mod disabled", 1, -1)                         //No Random Crits
    self.AddCustomAttribute("no crit boost", 1, -1)                             //No given crits either such as intel capture crits or first blood

    local footStepID = self.HasBotTag("giant") ? 3 : 2                          //2 for small bot steps. 3 for big bot steps.
    if (self.GetPlayerClass() == 5) footStepID = 0                              //Medics have wheels so no footstep sounds
    self.AddCustomAttribute("override footstep sound set", footStepID, -1)

    //self.AddCustomAttribute("airblast vulnerability multiplier", 0.5, -1)     //Disallow Pyros from just displacing us easily

    if (self.HasBotTag("jungle")) SetEntityColor(self, 55, 255, 35, 255)        //If we're a Jungle mob, turn us green. TODO: Create proper green team skins

    // if (self.GetPlayerClass() == 3)
    // {
    //     GivePlayerWeapon(self, "tf_weapon_particle_cannon", 441)
    //     self.AddCustomAttribute("Projectile speed decreased", 0.5, -1)
    // }
}

function OnGameEvent_player_spawn(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (player == null) return

    if (IsPlayerABot(player)) EntFireByHandle(player, "CallScriptFunction", "robotify", -1, null, null);
}

function OnGameEvent_player_death(params)
{
    local attacker  = GetPlayerFromUserID(params.attacker)
    local assister  = GetPlayerFromUserID(params.assister)
    local victim    = GetPlayerFromUserID(params.userid)

    local weapon  = Entities.FindByClassname(null, "tf_dropped_weapon") //Remove dropped weapons on death.
    if (weapon) weapon.Destroy()

	if (IsPlayerABot(victim))
	{
		// Spawn fancy gibs instead of just disappearing
		local gibs = SpawnEntityFromTable("prop_dynamic",
		{
			model = victim.GetModelName(),
			origin = victim.GetOrigin(),
			angles = victim.GetAbsAngles(),
			skin = victim.GetSkin()
            scale = victim.GetModelScale()
		})
		EntFireByHandle(gibs, "Break", null, 0, null, null)

        StopGiantSoundLoop(victim)

		victim.Kill()   // Hide the body
	}

    PayForKill(attacker, assister, victim)
}

function OnGameEvent_player_disconnect(params)
{
    local player = GetPlayerFromUserID(params.userid)

    if (IsPlayerABot(player) && player.HasBotTag("giant")) StopGiantSoundLoop(player)
}

function OnGameEvent_npc_hurt(params)
{
	local ent = EntIndexToHScript(params.entindex);

    //If the NPC hurt was a tower
    if (HasTowerScript(ent))
    {
        // Check if the tower is about to die
		if ((ent.GetHealth() - params.damageamount) <= 0)
		{
			// Run the tower's OnKilled function
			ent.GetScriptScope().my_tower.OnKilled();
		}
    }
}

__CollectGameEventCallbacks(this);
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);

PayForKill <- function(attacker, assister, victim)
{
    local debug = false
    if (attacker == victim) return //Do not pay anyone if they died of suicide
    if (IsPlayerABot(attacker)) return //Don't pay out for bot kills

    if (debug) printl("Paying player " + attacker + " $" + g_kill_pay)
    if (attacker) attacker.AddCurrency(g_kill_pay)

    if (assister && !IsPlayerABot(assister)) //Only pay humans
    {
        if(assister.GetPlayerClass() == 5) //Medics get full pay for assists
        {
            if (debug) printl("Awarded ASSISTER with " + " $" + g_kill_pay)
            assister.AddCurrency(g_kill_pay)
        }
        else
        {
            if (debug) printl("Awarded ASSISTER with " + " $" + g_assist_pay)
            assister.AddCurrency(g_assist_pay)
        }
    }
}

StopGiantSoundLoop <- function(bot)
{
    //Mute giant bot looping sounds
    if (bot.HasBotTag("giant"))
    {
        local classNames =
        [
            "SCOUT"
            "SNIPER"
            "SOLDIER"
            "DEMO"
            "MEDIC"
            "HEAVY"
            "PYRO"
            "SPY"
            "ENGINEER"
        ]
        local className = classNames[bot.GetPlayerClass() - 1]

        local soundName = format("GIANT_%s_SOUND_LOOP", className)
        EmitSoundEx({
            sound_name = getroottable()[soundName],
            channel = 4, //Body
            volume = 0.1, // 0-1
            entity = bot,
            speaker_entity = bot,
            flags = 4
        })
    }
}