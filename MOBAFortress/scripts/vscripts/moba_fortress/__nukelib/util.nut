IncludeScript("moba_fortress/__nukelib/netprops.nut");
IncludeScript("moba_fortress/__nukelib/constants.nut");
IncludeScript("moba_fortress/__nukelib/player.nut");

::IsValidEnemyTarget <- function (victim)
{
    if (victim == null)
        return false

    if (!IsMinion(victim) && !IsTower(victim) && !IsBuilding(victim) && !victim.IsPlayer()) //Skip anything that isn't a player, base_boss, or building
        return false

    if (victim.GetTeam() == 1) //Skip Spectators
        return false

    if (victim.GetTeam() == me.GetTeam()) //Will not attack my own team
        return false

    if(victim.IsPlayer())
    {
      if (victim.InCond(TF_COND_HALLOWEEN_GHOST_MODE)) //Skip Halloween spooky ghosts
        return false

      if (IsPlayerStealthed(victim)) //Or a stealthed player
        return false

      if (victim.InCond(TF_COND_DISGUISED) && victim.GetDisguiseTeam() == me.GetTeam()) //Skip players disguised as my own team. I'm stoopid
        return false
    }

    return true
}

::IsBuilding <- function (ent)
{
    local className = ent.GetClassname()
    return (className == "obj_sentrygun" || className == "obj_dispenser" || className == "obj_teleporter")
}

::IsSentry <- function (ent)
{
    return (ent.GetClassname() == "obj_sentrygun")
}

::IsDispenser <- function (ent)
{
    return ( ent.GetClassname() == "obj_dispenser")
}

::IsTeleporter <- function (ent)
{
    return (ent.GetClassname() == "obj_teleporter")
}

::IsMinion <- function (ent)
{
    return startswith(ent, "minion_")
}

::IsTower <- function (ent)
{
    return startswith(ent, "tower_")
}

function GetTargetPriority(currentTarget, testTarget)
{
    local tests = [     //Earlier on this list = Higher Priority
        @(e) IsTower(e),
        @(e) e.IsPlayer(),
        @(e) IsSentry(e),
        @(e) IsTeleporter(e),
        @(e) IsMinion(e),
        @(e) IsDispenser(e)
    ]
    foreach (test in tests) {
        local currentPasses = test(currentTarget)
        local newPasses = test(testTarget)
        if (!currentPasses && !newPasses) continue
        return currentPasses ? currentTarget : testTarget
    }
    return currentTarget
}

::CreateAoE <- function(center, radius, applyDamageFunc, applyPushFunc)
{
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local target = PlayerInstanceFromIndex(i);
        if (!target || !target.IsAlive())
            continue;
        local deltaVector = target.GetCenter() - center;
        local distance = deltaVector.Norm();
        if (distance > radius)
            continue;

        applyPushFunc(target, deltaVector, distance);
        applyDamageFunc(target, deltaVector, distance);
    }

    local target = null;
    while (target = Entities.FindByClassname(target, "obj_*"))
    {
        local deltaVector = target.GetCenter() - center;
        local distance = deltaVector.Norm();
        if (distance > radius)
            continue;

        applyDamageFunc(target, deltaVector, distance);
    }
}

::clampCeiling <- function(valueA, valueB)
{
    if (valueA < valueB)
        return valueA;
    return valueB;
}

::clampFloor <- function(valueA, valueB)
{
    if (valueA > valueB)
        return valueA;
    return valueB;
}

::clamp <- function(value, min, max)
{
    if (value < min)
        return min;
    if (value > max)
        return max;
    return value;
}

::inside <- function(vector, min, max)
{
    return vector.x >= min.x && vector.x <= max.x
        && vector.y >= min.y && vector.y <= max.y
        && vector.z >= min.z && vector.z <= max.z;
}

::MAX_WEAPONS <- 8;

::GivePlayerWeapon <- function(player, className, itemID)
{
    local weapon = Entities.CreateByClassname(className);
    NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", itemID);
    NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true);
    NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true);
    weapon.SetTeam(player.GetTeam());
    Entities.DispatchSpawn(weapon);

    // remove existing weapon in same slot
    for (local i = 0; i < MAX_WEAPONS; i++)
    {
        local heldWeapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
        if (heldWeapon == null)
            continue;
        if (heldWeapon.GetSlot() != weapon.GetSlot())
            continue;
        heldWeapon.Destroy();
        NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i);
        break;
    }

    player.Weapon_Equip(weapon);
    player.Weapon_Switch(weapon);

    return weapon;
}

::RemoveAllButOneWeaponSlot <- function (player, weaponSlot)
{
    for (local slot = 0; slot < 7; slot++)
    {
        local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", slot)
        if (weapon)
        {
            if (weapon.GetSlot() == weaponSlot) // melee
            player.Weapon_Switch(weapon) // switch to melee
            else
                weapon.Kill() // nuke everything else
        }
    }
}

::RemoveAllWeapons <- function (player)
{
    for (local slot = 0; slot < 7; slot++)
    {
        local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", slot)
        if (weapon)
        {
            weapon.Kill()
        }
    }
}

::SetEntityColor <- function(entity, r, g, b, a)
{
    local color = (r) | (g << 8) | (b << 16) | (a << 24);
    NetProps.SetPropInt(entity, "m_clrRender", color);
}
