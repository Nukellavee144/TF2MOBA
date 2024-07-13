root <- getroottable();
if ("tf2moba" in root)
	return;

foreach (a,b in Constants)
	foreach (k,v in b)
		if (!(k in root))
			root[k] <- v;

::CONST <- getconsttable()
CONST.setdelegate({ _newslot = @(k, v) compilestring("const " + k + "=" + (typeof(v) == "string" ? ("\"" + v + "\"") : v))() })

// Fold constants
::ROOT <- getroottable()
if (!("ConstantNamingConvention" in ROOT))
{
    foreach (a, b in Constants)
        foreach (k, v in b)
            if (v == null)
                ROOT[k] <- 0
            else
                ROOT[k] <- v
}



CreateByClassname <- Entities.CreateByClassname.bindenv(Entities);
FindByClassname <- Entities.FindByClassname.bindenv(Entities);
FindByName <- Entities.FindByName.bindenv(Entities);

GetPropArraySize <- NetProps.GetPropArraySize.bindenv(NetProps);
GetPropEntity <- NetProps.GetPropEntity.bindenv(NetProps);
GetPropEntityArray <- NetProps.GetPropEntityArray.bindenv(NetProps);
GetPropBool <- NetProps.GetPropBool.bindenv(NetProps);
GetPropBoolArray <- NetProps.GetPropBoolArray.bindenv(NetProps);
GetPropFloat <- NetProps.GetPropFloat.bindenv(NetProps);
GetPropFloatArray <- NetProps.GetPropFloatArray.bindenv(NetProps);
GetPropInfo <- NetProps.GetPropInfo.bindenv(NetProps);
GetPropInt <- NetProps.GetPropInt.bindenv(NetProps);
GetPropIntArray <- NetProps.GetPropIntArray.bindenv(NetProps);
GetPropString <- NetProps.GetPropString.bindenv(NetProps);
GetPropStringArray <- NetProps.GetPropStringArray.bindenv(NetProps);
GetPropType <- NetProps.GetPropType.bindenv(NetProps);
GetPropVector <- NetProps.GetPropVector.bindenv(NetProps);
GetPropVectorArray <- NetProps.GetPropVectorArray.bindenv(NetProps);
GetTable <- NetProps.GetTable.bindenv(NetProps);
HasProp <- NetProps.HasProp.bindenv(NetProps);
SetPropBool <- NetProps.SetPropBool.bindenv(NetProps);
SetPropBoolArray <- NetProps.SetPropBoolArray.bindenv(NetProps);
SetPropEntity <- NetProps.SetPropEntity.bindenv(NetProps);
SetPropEntityArray <- NetProps.SetPropEntityArray.bindenv(NetProps);
SetPropFloat <- NetProps.SetPropFloat.bindenv(NetProps);
SetPropFloatArray <- NetProps.SetPropFloatArray.bindenv(NetProps);
SetPropInt <- NetProps.SetPropInt.bindenv(NetProps);
SetPropIntArray <- NetProps.SetPropIntArray.bindenv(NetProps);
SetPropString <- NetProps.SetPropString.bindenv(NetProps);
SetPropStringArray <- NetProps.SetPropStringArray.bindenv(NetProps);
SetPropVector <- NetProps.SetPropVector.bindenv(NetProps);
SetPropVectorArray <- NetProps.SetPropVectorArray.bindenv(NetProps);

GetNavArea <- NavMesh.GetNavArea.bindenv(NavMesh);
GetNearestNavArea <- NavMesh.GetNearestNavArea.bindenv(NavMesh);
GetNavAreasFromBuildPath <- NavMesh.GetNavAreasFromBuildPath.bindenv(NavMesh);
GetNavAreasInRadius <- NavMesh.GetNavAreasInRadius.bindenv(NavMesh);
GetNavArea <- NavMesh.GetNavArea.bindenv(NavMesh);
GetAllNavAreas <- NavMesh.GetAllAreas.bindenv(NavMesh);
GetNavAreaByID <- NavMesh.GetNavAreaByID.bindenv(NavMesh);

SetConvarValue <- Convars.SetValue.bindenv(Convars);

MASK_SOLID <- (CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_MONSTER|CONTENTS_GRATE);
FLT_MAX <- 3.402823466e+38;
NAN <- casti2f(0x7fa00000);
RAD2DEG <- 57.295779513;
DMG_CRIT <- DMG_ACID;
MAX_CLIENTS <- MaxClients().tointeger();
TICKRATE <- 67;
TICKDT <- 0.015; // ~1/66

NEXTBOT_SPAWNS <-
[
	Vector(6417, -352, 4)
];

class BotPathPoint
{
	constructor(_area, _pos, _how)
	{
		area = _area;
		pos = _pos;
		how = _how;
	}

	area = null;
	pos = null;
	how = null;
}

MASK_WORLD <- CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_OPAQUE|CONTENTS_MOVEABLE;
MASK_SOLID <- (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_WINDOW | CONTENTS_MONSTER | CONTENTS_GRATE)
MASK_BLOCKLOS <- (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_BLOCKLOS)
MASK_BLOCKLOS_AND_NPCS <- (MASK_BLOCKLOS | CONTENTS_MONSTER)
SF_NORESPAWN <- (1 << 30)

IncludeScript("trace_filter")

gamerules <- FindByClassname(null, "tf_gamerules");
worldspawn <- FindByClassname(null, "worldspawn");

if (!("nextbots" in root))
	nextbots <- []

red_minion_spawners <- [];
blu_minion_spawners <- [];
neutral_minion_spawners <- [];

red_minion_startingpaths <- [];
blu_minion_startingpaths <- [];
neutral_minion_startingpaths <- [];

::BotPathPoint <- class
{
	constructor(_area, _pos, _how)
	{
		area = _area
		pos = _pos
		how = _how
	}

	area = null
	pos = null
	how = null
}

::GetAllMinionSpawners <-function()
{
    for (local ent; ent = Entities.FindByName(ent, "minion_spawn_*");) //Look for all minion spawners on the map
    {
        if (ent.GetName().find("red") != null) //If it's RED, add it to the list of red minion spawners
        {
            red_minion_spawners.append(ent)
        }
        else if (ent.GetName().find("blu") != null) //If it's BLU, add it to the list of blu minion spawners
        {
            blu_minion_spawners.append(ent)
        }
        else neutral_minion_spawners.append(ent) //If it's not red or blu, add it to the list of neutral minion spawners
    }
}

::GetAllMinionStartingPaths <- function()
{
    for (local ent; ent = Entities.FindByName(ent, "minion_path_*");)
    {
        if (ent.GetName().find("_0") == null) continue //Only grab the starting paths

        if (ent.GetName().find("red") != null)
        {
            red_minion_startingpaths.append(ent)
        }
        else if (ent.GetName().find("blu") != null)
        {
            blu_minion_startingpaths.append(ent)
        }
        else neutral_minion_startingpaths.append(ent)
    }

}

::IsAlive <- function (player)
{
	return GetPropInt(player, "m_lifeState") == 0;
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
    return ent.GetName().find("minionbot_") != null
}

::IsTower <- function (ent)
{
    return ent.GetName().find("tower_") != null
}

function GetTargetPriority(currentTarget, testTarget) {
    local tests = [                                 //Earlier on this list = Higher Priority
        @(e) e.GetName().find("tower_") != null,
        @(e) e.IsPlayer(),
        @(e) IsSentry(e),
        @(e) IsTeleporter(e),
        @(e) e.GetName().find("minion_") != null,
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

// Constrains an angle into [-180, 180] range
function NormalizeAngle(target)
{
    target %= 360.0;
    if (target > 180.0)
        target -= 360.0;
    else if (target < -180.0)
        target += 360.0;
    return target;
}

// Approaches an angle at a given speed
function ApproachAngle(target, value, speed)
{
    target = NormalizeAngle(target);
    value = NormalizeAngle(value);
    local delta = NormalizeAngle(target - value);
    if (delta > speed)
        return value + speed;
    else if (delta < -speed)
        return value - speed;
    return value;
}

function Lerp( from, to, smooth = 0.5 )
{
    return from + (( to - from ) * smooth);
}

function AnglesToVector(angles)
{
    local pitch = angles.x * Constants.Math.Pi / 180.0
    local yaw = angles.y * Constants.Math.Pi / 180.0
    local x = cos(pitch) * cos(yaw)
    local y = cos(pitch) * sin(yaw)
    local z = sin(pitch)
    return Vector(x, y, z)
}

function VectorAngles(forward)
{
    local yaw, pitch;
    if ( forward.y == 0.0 && forward.x == 0.0 )
    {
        yaw = 0.0;
        if (forward.z > 0.0)
            pitch = 270.0;
        else
            pitch = 90.0;
    }
    else
    {
        yaw = (atan2(forward.y, forward.x) * 180.0 / Constants.Math.Pi);
        if (yaw < 0.0)
            yaw += 360.0;
        pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / Constants.Math.Pi);
        if (pitch < 0.0)
            pitch += 360.0;
    }

    return QAngle(pitch, yaw, 0.0);
}

function RemapAngle(angle)
{
    if (angle > 180.0)
    {
        angle -= 360.0;
    }

    if (angle < -180.0)
    {
        angle += 360.0;
    }
    return angle;
}

function Clamp(value, lowerBound, upperBound)
{
    if (value < lowerBound)
    {
        return lowerBound;
    }
    else if (value > upperBound)
    {
        return upperBound;
    }
    else
    {
        return value;
    }
}

function ClearBots()
{
    for (local ent; ent = Entities.FindByName(ent, "robotMinion_*");)
    {
        ent.Kill()
    }
}

function HasBotScript(ent)
{
    if (ent.GetName().find("minionbot_") == null) return false
	// Return true if this entity has the my_bot script scope
	return (ent.GetScriptScope() != null && ent.GetScriptScope().nextbot != null);
}

GetAllMinionSpawners()
GetAllMinionStartingPaths()
