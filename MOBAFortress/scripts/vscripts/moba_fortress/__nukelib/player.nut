::GetAllPlayers <- function()
{
    local allPlayers = [];
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player)
            allPlayers.push(player);
    }
    return allPlayers;
}

::GetAlivePlayers <- function()
{
    local alivePlayers = [];
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player && GetPropInt(player, "m_lifeState") == 0)
                alivePlayers.push(player);
    }
    return alivePlayers;
}

::GetAlivePlayersInRange <- function(center, radius)
{
    local inRangePlayers = [];
    foreach (player in GetAlivePlayers())
    {
        local deltaVector = player.GetCenter() - center;
        if ((player.GetCenter() - center).Length() <= radius)
            inRangePlayers.push(player);
    }
    return inRangePlayers;
}

::CTFPlayer.IsAlive <- function()
{
    return GetPropInt(this, "m_lifeState") == 0;
}

::CTFBot.IsAlive <- CTFPlayer.IsAlive;

::IsValidPlayer <- function(player)
{
    try
    {
        return player && player.IsValid() && player.IsPlayer() && player.GetTeam() > 1;
    }
    catch(e)
    {
        return false;
    }
}

::EmitGlobalSound <- function(sound_name)
{
    EmitSoundEx({
        sound_name = sound_name,
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
        volume = 1,
        soundlevel = 150,
        flags = 1,
        channel = 0
    });
}

::EmitSoundLP <- function(listener, speaker, voiceline)
{
    //Thanks ficool2 for the idea
    local offset = Vector(999999, 999999, 999999);
    local restore = {};
    foreach (player in GetAllPlayers())
        if (player != listener)
        {
            restore[player] <- GetPropVector(player, "m_vecViewOffset");
            SetPropVector(player, "m_vecViewOffset", offset);
        }

    EmitSoundEx({
        sound_name = voiceline,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_PAS_ATTENUATION,
        volume = 1,
        flags =  1,
        channel = 1,
        sound_level = 150,
        entity = speaker,
        speaker_entity = speaker
    });

    foreach (player, offset in restore)
        SetPropVector(player, "m_vecViewOffset", offset);
}

::CTFPlayer.Yeet <- function(vector)
{
    SetPropEntity(this, "m_hGroundEntity", null);
    this.ApplyAbsVelocityImpulse(vector);
    this.RemoveFlag(FL_ONGROUND);
}

::CTFBot.Yeet <- CTFPlayer.Yeet;

::player_collection <- function(defValue = 0)
{
    local array = [];
    array.resize(MAX_PLAYERS + 1, defValue);
    return array;
}