function LookForTarget()
{
    //If we do not have a target or our target isn't alive or we have no path to our target, find a new target
    if (!playerTarget || !playerTarget.IsAlive() || pathFailed)
    {
        SetNewTarget(PickTarget());
        return;
    }
    if (pathDistance > 800)
    {
        local potentialTargets = GetAlivePlayersInRange(self.GetCenter(), 400);
        local len = potentialTargets.len();
        if (len > 0)
            SetNewTarget(potentialTargets[RandomInt(0, len - 1)]);
        else
            SetNewTarget(PickTarget());
    }
}

function SetNewTarget(target)
{
    local lastTarget = playerTarget;
    playerTarget = IsValidPlayer(target) ? target : null;
    if (playerTarget && lastTarget != playerTarget && Time() > spottedVOCooldown[playerTarget.entindex()])
    {
        spottedVOCooldown[playerTarget.entindex()] = Time() + 10;
        //EmitSoundLP(target, krampus, "mvm/Krampus_Spotted_0"+RandomInt(1,6)+".mp3");
    }
}

function PickTarget()
{
    local players = [];
    foreach (player in GetAlivePlayers())
        if (inside(player.GetOrigin(), KRAMPUS_ARENA_MIN, KRAMPUS_ARENA_MAX))
            players.push(player);
    local len = players.len();
    if (len == 0)
        return null;
    return players[RandomInt(0, len - 1)];
}

function PickTargetInSight(me)
{
    local players = [];
    foreach (player in GetAlivePlayers())
        if (TraceLine(me.EyePosition(), player.GetCenter(), me) > 0.95)
            players.push(player);
    local len = players.len();
    if (len == 0)
        return PickTarget();
    return players[RandomInt(0, len - 1)];
}