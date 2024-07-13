
class Tower
{
    constructor(entity)
    {
        towerEnt = entity
    }

    function SetUpTowerLocation()
    {
        local isJungle = towerEnt.GetName().find("jungle") != null

        //Set team
        local teamNum = (towerEnt.GetName().find("red") != null) ? 2 : 3
        if (isJungle) teamNum = 0
        towerEnt.SetTeam(teamNum)

        //Set color
        local skin = (teamNum == 2) ? 0 : 1
        towerEnt.SetSkin(skin)

        if (isJungle) SetEntityColor(towerEnt, 55, 255, 35, 255)

        //Set bounds, and therefore, hitboxes
        DoEntFire("!self", "AddOutput", "maxs 85 85 190", 0, null, towerEnt)
        DoEntFire("!self", "AddOutput", "mins -85 -85 0", 0, null, towerEnt)

        //Clear money map-wide on death.
        EntityOutputs.AddOutput(towerEnt, "OnKilled", "item_currencypack*", "Kill", null, 0.0, -1)
    }

	function OnKilled()
	{
        //DispatchParticleEffect("cinefx_goldrush", towerEnt.GetOrigin(), towerEnt.GetAngles())
        DispatchParticleEffect("fireSmokeExplosion", towerEnt.GetOrigin(), towerEnt.GetAngles())
		DispatchParticleEffect("mvm_tank_destroy", towerEnt.GetOrigin(), towerEnt.GetAngles())
		DispatchParticleEffect("mvm_tank_destroy_embers", towerEnt.GetOrigin(), towerEnt.GetAngles())
		DispatchParticleEffect("mvm_tank_destroy_bloom", towerEnt.GetOrigin(), towerEnt.GetAngles())

        EmitSoundOn(TOWER_EXPLOSION_SOUND, towerEnt)
        ScreenShake(towerEnt.GetOrigin(), 100.0, 10.0, 5.0, 3000.0, 0, true)
	}

    towerEnt = null
}



::HasTowerScript <- function(ent)
{
    if (ent.GetName().find("tower_") == null) return false
	// Return true if this entity has the my_bot script scope
	return (ent.GetScriptScope() != null && ent.GetScriptScope().my_tower != null);
}

//Attach this script to each tower on the map
for (local ent; ent = Entities.FindByName(ent, "tower_*");)
{
    ent.ValidateScriptScope()
    ent.GetScriptScope().my_tower <- Tower(ent);
    ent.GetScriptScope().my_tower.SetUpTowerLocation()
}
