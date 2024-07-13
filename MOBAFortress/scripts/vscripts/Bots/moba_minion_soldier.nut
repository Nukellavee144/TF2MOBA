// Made by Mikusch, special thanks to ficool2 for assistance
// https://steamcommunity.com/profiles/76561198071478507

// Allow expression constants

local BOT_BASE_NAME = "shotgun_soldier"
local BOT_MODEL = "models/bots/soldier/bot_soldier.mdl"
local BOT_IDLE_SOUND = format("Soldier.Robot%02d", RandomInt(1, 15))
local BOT_USE_PATH = true //Does this bot follow a path?

// enum BOT_MOVE_TYPE
// {
//     USE_PATH = 0, //Follow the pathtracks assigned to you until you get stopped by a minion or tower
//     STAY_PUT = 1, //Stay where you are and defend it
//     WANDER = 2,	//Move to random spots around the map
//     FIND_CLOSEST_TARGET = 3 //After you spawn, find the closest enemy target to you and go attack it
// }

// enum BOT_HOSTILITY_TYPE
// {
// 	HOSTILE_TO_ALL = 0, //Attack anything that isn't on our team
// 	HOSTILE_TO_PLAYERS = 1, //Attack only enemy players
// 	NON_HOSTILE = 2 //Do not attack anything.
// }

// local BOT_MOVEMENT_METHOD = null //Set this to a BOT_MOVE_TYPE
// local BOT_HOSTILITY = null //Set this to a BOT_HOSTILITY_TYPE

//what's the model's number for each team skin
local RED_TEAM_COLOR_NUM = 0
local BLU_TEAM_COLOR_NUM = 1
local NEU_TEAM_COLOR_NUM = 0

BOT_WEAPON <- Entities.CreateByClassname("tf_weapon_shotgun_soldier");
NetProps.SetPropInt(BOT_WEAPON, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 10);
NetProps.SetPropBool(BOT_WEAPON, "m_AttributeManager.m_Item.m_bInitialized", true);
BOT_WEAPON.SetClip1(-1);
Entities.DispatchSpawn(BOT_WEAPON);

local BOT_WEAPON_MODEL = "models/weapons/c_models/c_shotgun/c_shotgun.mdl"
local BOT_WEAPON_SHOOT_SOUND = "Weapon_Shotgun.Single"
local BOT_WEAPON_TRACER_PARTICLE = "bullet_pistol_tracer01_red"
local BOT_WEAPON_MUZZLEFLASH_PARTICLE = "muzzle_shotgun_flash"

local BOT_HURT_PARTICLE_EFFECT = "rd_bot_impact_sparks2"

local BOT_WEAPON_PELLETS_PER_SHOT = 5
local BOT_WEAPON_DAMAGE_PER_PELLET = 12 //Damage at mid-range. Subject to falloff/rampup
local BOT_WEAPON_TIME_FIRE_DELAY = 2
local BOT_WEAPON_TIME_FIRE_DELAY_VARIANCE = 0.1 //Small varience in fire rate for variety and to break stalemates
local BOT_WEAPON_SPREAD = 0.1
local BOT_WEAPON_RANGE = 1000.0 //It will fire if the target is within this range

local BOT_VISION_RANGE = 2000.0 //It will accept targets within this range

local BOT_HEALTH = 125
local BOT_MAX_SPEED = 250.0
local BOT_FOV = 90.0
local BOT_MOVE_RANGE = 300.0 //Bot will attempt to get this close to it's move target
local BOT_TURN_RATE = 5.0
local PATH_UPDATE_INTERVAL = 0.1

PrecacheModel(BOT_WEAPON_MODEL)
PrecacheScriptSound(BOT_WEAPON_SHOOT_SOUND)
PrecacheScriptSound(BOT_IDLE_SOUND)
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = BOT_WEAPON_TRACER_PARTICLE })
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = BOT_HURT_PARTICLE_EFFECT })


class Soldier_Minion
{
	constructor(entity, starting_path)
	{
		me = entity

		if (starting_path)
        	path_ent = starting_path
		//If the bot is closer than this to the desired location, it is considered to be at it.
		max_dist_from_path_ent = 24.0;

		locomotion = me.GetLocomotionInterface()

		path_update_time_next = Time()
		path_update_force = true

		sequence_spawn = me.LookupSequence("Stand_LOSER")
		sequence_idle = me.LookupSequence("Stand_SECONDARY")
		sequence_run = me.LookupSequence("Run_SECONDARY")

		pose_move_x = me.LookupPoseParameter("move_x")
		pose_move_y = me.LookupPoseParameter("move_y")

		pose_body_pitch = me.LookupPoseParameter("body_pitch")
		pose_body_yaw = me.LookupPoseParameter("body_yaw")

		me.SetSequence(sequence_spawn)

        //Put a weapon in their hands
		weapon = SpawnEntityFromTable("prop_dynamic", { model = BOT_WEAPON_MODEL, solid = SOLID_NONE })
		EntFireByHandle(weapon, "SetParent", "!activator", 0, me, null)
		weapon.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT)
		NetProps.SetPropInt(weapon, "m_fEffects", EF_BONEMERGE | EF_BONEMERGE_FASTCULL)
		weapon.SetLocalOrigin(Vector())
		weapon.SetLocalAngles(QAngle())

		attachment_muzzle = weapon.LookupAttachment("muzzle")

		me.AddFlag(FL_NPC)
		me.SetCollisionGroup(COLLISION_GROUP_PLAYER)

		EntFireByHandle(me, "SetStepHeight", "18", 0, null, null)
		EntFireByHandle(me, "SetMaxJumpHeight", "18", 0, null, null)
		me.KeyValueFromFloat("speed", BOT_MAX_SPEED)

		me.SetSize(Vector(-24, -24, 0), Vector(24, 24, 82))

		nextbots.append(me)
	}

	function UpdatePath(target)
	{
		ResetPath()

		// if (!HasVictim()) //If we don't have a victim, get a new path
		// 	return

		if (target) path_target_pos = target.GetOrigin()
			else return

		local pos_start = m_vecAbsOrigin + Vector(0, 0, 1)
		local pos_end = path_target_pos + Vector(0, 0, 1)

		local area_start = NavMesh.GetNavArea(pos_start, 128.0)
		local area_end = NavMesh.GetNavArea(pos_end, 128.0)
		if (area_start == null)
			area_start = NavMesh.GetNearestNavArea(pos_start, 512.0, false, false)
		if (area_end == null)
			area_end = NavMesh.GetNearestNavArea(pos_end, 512.0, false, false)

		if (area_start == null || area_end == null)
			return false

		if (area_start == area_end)
		{
			path.append(BotPathPoint(area_end, pos_end, NUM_TRAVERSE_TYPES))
			return true
		}

		if (!NavMesh.GetNavAreasFromBuildPath(area_start, area_end, pos_end, 0.0, TEAM_ANY, false, path_areas))
			return false

		if (path_areas.len() == 0)
			return false

		local area_target = path_areas["area0"]
		local area = area_target
		local area_count = path_areas.len()

		for (local i = 0; i < area_count && area != null; i++)
		{
			path.append(BotPathPoint(area, area.GetCenter(), area.GetParentHow()))
			area = area.GetParent()
		}

		path.append(BotPathPoint(area_start, m_vecAbsOrigin, NUM_TRAVERSE_TYPES))
		path.reverse()

		local path_count = path.len()
		for (local i = 1; i < path_count; i++)
		{
			local path_from = path[i - 1]
			local path_to = path[i]

			path_to.pos = path_from.area.ComputeClosestPointInPortal(path_to.area, path_to.how, path_from.pos)
		}

		path.append(BotPathPoint(area_end, pos_end, NUM_TRAVERSE_TYPES))
	}

	function AdvancePath()
	{
		local path_len = path.len()
		if (path_len == 0)
			return false

		if ((path[path_index].pos - m_vecAbsOrigin).Length2D() < 32.0)
		{
			path_index++
			if (path_index >= path_len)
			{
				ResetPath()
				return false
			}
		}

		return true
	}

	function ResetPath()
	{
		path_areas.clear()
		path.clear()
		path_index = 0
		path_target_pos = null
	}

	function Move()
	{
		if (path_update_force)
		{
			UpdatePath(path_ent)
			path_update_force = false
		}
		else if (path_update_time_next <= curtime) //If it's time to update the path again
		{




			if (path_target_pos != null) //If we are using paths and we actually have a path
			{
				if ((me.GetOrigin() - path_target_pos).Length() < max_dist_from_path_ent) //If we are close enough to our current path target
				{
					local nextPath =  NetProps.GetPropEntity(path_ent,"m_pnext")
					if (nextPath) path_ent = nextPath

					UpdatePath(path_ent);

					path_update_time_next = curtime + PATH_UPDATE_INTERVAL; // Don't recompute again for a moment
				}
			}
			else if (path_target_pos == null || HasVictim() && (path_target_pos - attack_target.GetOrigin()).Length() > 16.0)
			{
				UpdatePath(path_ent)
				path_update_time_next = curtime + PATH_UPDATE_INTERVAL
			}





		}

		local look_ang = m_angAbsRotation

		if (AdvancePath())
		{
			local path_pos = path[path_index].pos

			local move_dir = path_pos - m_vecAbsOrigin
			move_dir.Norm()

			local my_forward = m_angAbsRotation.Forward()
			my_forward.x = my_forward.x + 0.1 * (move_dir.x - my_forward.x)
			my_forward.y = my_forward.y + 0.1 * (move_dir.y - my_forward.y)

			look_ang = atan2(my_forward.y, my_forward.x)
			look_ang = QAngle(0, look_ang * RAD2DEG, 0)

			if (HasVictim())
			{
				if ((m_vecAbsOrigin - attack_target.GetOrigin()).Length() > BOT_MOVE_RANGE || !IsLineOfSightClear(me, attack_target))
				{
					locomotion.SetDesiredSpeed(BOT_MAX_SPEED)
					locomotion.Approach(path_pos, 1.0)
				}
			} else if (path_ent)
			{
				locomotion.SetDesiredSpeed(BOT_MAX_SPEED)
				locomotion.Approach(path_pos, 1.0)
			}
		}

		// If we have a victim and it is in our view cone, turn towards it
		if (HasVictim())
		{
			local half_fov = cos(0.5 * BOT_FOV * PI / 180.0)
			if (PointWithinViewAngle(m_vecEyePosition, attack_target.EyePosition(), look_ang.Forward(), half_fov) && IsLineOfSightClear(me, attack_target))
				look_ang = LookAtEntity(attack_target)
		}

		me.SetAbsAngles(look_ang)
	}

	function Vocalize()
	{
		if (next_vocalize_time <= curtime)
		{
			next_vocalize_time = curtime + RandomFloat(30, 60)

			me.EmitSound(BOT_IDLE_SOUND)
		}
	}

	function LookAtEntity(entity)
	{
		local look_ang = LookAt(entity.GetCenter())

        if(entity.IsPlayer())
        {
            // Crouch jumping or taunting makes the box weird
            if (entity.IsPlayer() && !(entity.GetFlags() & FL_ONGROUND) && entity.GetFlags() & FL_DUCKING || entity.InCond(TF_COND_TAUNTING))
            {
                local bone = entity.LookupBone("bip_spine_2")
                if (bone != 0)
                {
                    look_ang = LookAt(entity.GetBoneOrigin(bone))
                }
            }
        }

		return look_ang
	}

	function LookAt(pos)
	{
		look_dir = pos - m_vecEyePosition
		look_dir.Norm()

		local look_angle = atan2(look_dir.y, look_dir.x)
		local look_ang = QAngle(0, look_angle * RAD2DEG, 0)

		// Smoothly turn towards the target position
		local current_yaw = m_angAbsRotation.y
		local target_yaw = look_ang.y
		local delta_yaw = target_yaw - current_yaw

		delta_yaw = NormalizeAngle(delta_yaw)

		// Turn smoothly towards the target yaw
		local turn_speed = BOT_TURN_RATE / (1 + exp(-abs(delta_yaw)))
		if (delta_yaw > turn_speed) delta_yaw = turn_speed
		else if (delta_yaw < -turn_speed) delta_yaw = -turn_speed

		look_ang.y = current_yaw + delta_yaw

		// Set the pose parameters for pitch and yaw
		local pitch_angle = asin(look_dir.z)
		local pitch_degrees = pitch_angle * RAD2DEG
		me.SetPoseParameter(pose_body_pitch, pitch_degrees)

		local yaw_degrees = delta_yaw
		me.SetPoseParameter(pose_body_yaw, yaw_degrees)

		return look_ang
	}

	function HasVictim()
	{
		return attack_target != null && attack_target.IsValid()
	}

	function SelectVictim()
	{

		if (IsPotentiallyChaseable(attack_target) && curtime <= attack_target_focus_timer)
			return


		local new_victim = null
		local victim_range_sq = FLT_MAX

        for (local ent; ent = Entities.FindInSphere( ent, me.GetCenter(), BOT_VISION_RANGE );) //If we are near an enemy
		{

            if (!IsValidEnemyTarget(ent)) //Skip invalid targets
                continue

            local delta = ent.GetCenter() - m_vecEyePosition
            delta.Norm()

            if (me.GetAbsAngles().Forward().Dot(delta) < 0.087) // cos(170/2) //Skip if the target is behind us
                continue

            local range_sq = (ent.GetCenter() - me.GetCenter()).Length()

            if (range_sq > BOT_VISION_RANGE) //Skip if target is too far away
                continue;

            if (range_sq < victim_range_sq) //If the new check is closer than the old check, use the new one
            {
                new_victim = ent
                victim_range_sq = range_sq
            }

        }

		if (new_victim != null) //If we don't have a new victim to check, don't check again for 3 seconds
		{
			attack_target_focus_timer = curtime + 3.0
		}

		attack_target = new_victim
	}

	function RunAnimations()
	{
		me.StudioFrameAdvance()
		me.DispatchAnimEvents(me)

		// Wait for spawning animation to finish
		if (me.GetSequence() == sequence_spawn && me.GetCycle() < 1)
			return

		if (locomotion.IsAttemptingToMove())
			me.ResetSequence(sequence_run)
		else
			me.ResetSequence(sequence_idle)

        local movement_dir = locomotion.GetVelocity()
        local speed = movement_dir.Norm() / BOT_MAX_SPEED
        me.SetPoseParameter(pose_move_x, movement_dir.Dot(m_angAbsRotation.Forward()) * speed)
        me.SetPoseParameter(pose_move_y, movement_dir.Dot(m_angAbsRotation.Left()) * speed)
	}

	function PrimaryAttack()
	{
		local tempPlayer = null
		local MAX_PLAYERS = MaxClients().tointeger()
		for (local i = 1; i <= MAX_PLAYERS ; i++)
		{
			if (PlayerInstanceFromIndex(i))
			{
				tempPlayer = PlayerInstanceFromIndex(i)
				break
			}
		}

		if (!tempPlayer) return

		BOT_WEAPON.SetTeam(me.GetTeam());

		NetProps.SetPropFloat(BOT_WEAPON, "m_flNextPrimaryAttack", 0); //Set things so it works
		NetProps.SetPropBool(tempPlayer, "m_bLagCompensation", false)

		local tempPlayerOrigin = tempPlayer.GetOrigin();
		NetProps.SetPropVector(tempPlayer, "m_vecAbsOrigin", me.GetOrigin()) //Place the temp player at the bot's position

		NetProps.SetPropEntity(BOT_WEAPON, "m_hOwner", tempPlayer); //Set the owner of the weapon to the player
		BOT_WEAPON.PrimaryAttack();

		NetProps.SetPropBool(tempPlayer, "m_bLagCompensation", true) //Reset the things that had to be set to make it work
		NetProps.SetPropVector(tempPlayer, "m_vecAbsOrigin", tempPlayerOrigin)



		// // Check if enemy is under our crosshair
		// local trace =
		// {
		// 	start = m_vecEyePosition,
		// 	end = m_vecEyePosition + look_dir * BOT_WEAPON_RANGE,
		// 	ignore = me,
		// 	mask = 1107296257, // CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_HITBOX
        //     filter = function(entity)
        //     {
        //         if (IsValidEnemyTarget(entity))
        //             return TRACE_STOP;
        //         return TRACE_CONTINUE;
        //     }
		// }

        // //DebugDrawLine(trace.start, trace.end, 255, 255, 255, true, 1)

        // if (!TraceLineEx(trace) || !("enthit" in trace) || trace.enthit == null || !IsValidEnemyTarget(trace.enthit))
        //         return false

		// me.EmitSound(BOT_WEAPON_SHOOT_SOUND)

        // for (local j = 0; j < BOT_WEAPON_PELLETS_PER_SHOT; j++)
        // {
        //     // Apply weapon spread
        //     local x = RandomFloat(-0.5, 0.5) + RandomFloat(-0.5, 0.5)
        //     local y = RandomFloat(-0.5, 0.5) + RandomFloat(-0.5, 0.5)
        //     local shoot_forward = look_dir
        //     local shoot_right = shoot_forward.Cross(Vector(0, 0, 1))
        //     local shoot_up = shoot_right.Cross(shoot_forward)
        //     local shoot_dir = shoot_forward + (shoot_right * BOT_WEAPON_SPREAD * x) + (shoot_up * BOT_WEAPON_SPREAD * y)
        //     shoot_dir.Norm()

        //     // Check if a bullet can pass through
        //     trace.end = m_vecEyePosition + shoot_dir * BOT_WEAPON_RANGE
        //     trace.mask = MASK_SOLID | CONTENTS_HITBOX

        //     if (!TraceLineEx(trace))
        //         return false

        //     local muzzle_origin = weapon.GetAttachmentOrigin(attachment_muzzle)
        //     local muzzle_angles = weapon.GetAttachmentAngles(attachment_muzzle)

        //     local muzzle_forward = muzzle_angles.Forward()
        //     muzzle_forward.Norm()

        //     local tracer = SpawnEntityFromTable("info_particle_system",
        //     {
        //         effect_name = BOT_WEAPON_TRACER_PARTICLE,
        //         start_active = 1,
        //         origin = muzzle_origin,
        //         angles = muzzle_forward
        //     })
        //     EntFireByHandle(tracer, "Kill", null, BOT_WEAPON_TIME_FIRE_DELAY, null, null)

        //     DispatchParticleEffect(BOT_WEAPON_MUZZLEFLASH_PARTICLE, muzzle_origin, muzzle_forward)

        //     local target = SpawnEntityFromTable("info_target", { origin = trace.endpos, spawnflags = 0x01 })
        //     NetProps.SetPropEntityArray(tracer, "m_hControlPointEnts", target, 0)
        //     EntFireByHandle(target, "Kill", null, BOT_WEAPON_TIME_FIRE_DELAY, null, null)

        //     // Hit a valid target
        //     if ("enthit" in trace && trace.enthit != null && IsValidEnemyTarget(trace.enthit))
        //     {
        //         if (trace.enthit.IsPlayer())
        //         {
        //             if (!trace.enthit.InCond(TF_COND_DISGUISED))
        //             {
        //                 trace.enthit.EmitSound("Flesh.BulletImpact")
        //             }
        //         }

        //         if (IsMinion(trace.enthit) || IsBuilding(trace.enthit) || IsTower(trace.enthit))
        //         {
        //             trace.enthit.EmitSound("MVM_Robot.BulletImpact")
        //             DispatchParticleEffect(BOT_HURT_PARTICLE_EFFECT, trace.pos, trace.plane_normal)
        //         }

        //         // Passing Vector() auto-calculates damage force and position
        //         trace.enthit.TakeDamageCustom(me, me, null, Vector(), Vector(), BOT_WEAPON_DAMAGE_PER_PELLET, DMG_BULLET + DMG_SLOWBURN , TF_DMG_CUSTOM_NONE)
        //     }
        // }

		return true
	}

	function DrawDebugInfo()
	{
		local duration = FrameTime()*2

		local path_len = path.len()
		if (path_len > 0)
		{
			local path_start_index = 0
			if (path_start_index == 0)
				path_start_index++

			for (local i = path_start_index; i < path_len; i++)
			{
				local p1 = path[i-1]
				local p2 = path[i]

				local clr
				if (p1.how <= GO_WEST || p1.how >= NUM_TRAVERSE_TYPES)
					clr = [0, 255, 0]
				else if (p1.how ==  GO_JUMP)
					clr = [128, 128, 255]
				else
					clr = [255, 128, 192]

				DebugDrawLine(p1.pos, p2.pos, clr[0], clr[1], clr[2], true, duration)
				DebugDrawText(p1.pos, i.tostring(), false, duration)
			}
		}

		foreach (name, area in path_areas)
			area.DebugDrawFilled(255, 0, 0, 30, duration, true, 0.0)

		DebugDrawCircle(me.GetCenter(), Vector(0,125,0), 0.75, BOT_VISION_RANGE, true, duration)
		DebugDrawCircle(me.GetCenter(), Vector(255,0,0), 0.75, BOT_WEAPON_RANGE, true, duration)

		local text_pos = Vector(m_vecAbsOrigin.x, m_vecAbsOrigin.y, m_vecAbsOrigin.z + 90.0) + m_angAbsRotation.Left() * -32.0
		local z_offset = -8.0

		/*
		DebugDrawText(
			text_pos,
			format("origin: %f %f %f", m.m_vecAbsOrigin.x, m.m_vecAbsOrigin.y, m.m_vecAbsOrigin.z),
			false, duration
		)
		text_pos.z += z_offset
		DebugDrawText(
			text_pos,
			format("angles: %f %f %f", m.m_vecViewAngles.x, m.m_vecViewAngles.y, m.m_vecViewAngles.z),
			false, duration
		)
		text_pos.z += z_offset
		DebugDrawText(
			text_pos,
			format("velocity: %f %f %f", m.m_vecVelocity.x, m.m_vecVelocity.y, m.m_vecVelocity.z),
			false, duration
		)
		text_pos.z += z_offset
		DebugDrawText(
			text_pos,
			format("basevelocity: %f %f %f", m.m_vecBaseVelocity.x, m.m_vecBaseVelocity.y, m.m_vecBaseVelocity.z),
			false, duration
		)
		text_pos.z += z_offset
		DebugDrawText(
			text_pos,
			format("forward: %g", m.m_flForwardMove),
			false, duration
		)
		text_pos.z += z_offset
		DebugDrawText(
			text_pos,
			format("side: %g", m.m_flSideMove),
			false, duration
		)
		text_pos.z += z_offset
		DebugDrawText(
			text_pos,
			format("ground: %s", m.m_ground ? m.m_ground.tostring() : "null"),
			false, duration
		)
		text_pos.z += z_offset
		DebugDrawText(
			text_pos,
			format("speed: %g", m.m_vecVelocity.Length2D()),
			false, duration
		)
		text_pos.z += z_offset
		*/
	}

	function Update()
	{
		curtime = Time()
		m_vecAbsOrigin = me.GetOrigin()
		m_angAbsRotation = me.GetAbsAngles()
		m_vecEyePosition = m_vecAbsOrigin + Vector(0, 0, 72)

		RunAnimations()

		if (me.GetSequence() != sequence_spawn)
		{
            if (!IsAlive(me)) return //Don't do anything if I'm dead

			SelectVictim()
        	Move()
			Vocalize()

			if (next_primary_attack <= curtime && PrimaryAttack())
			{
				next_primary_attack = curtime + BOT_WEAPON_TIME_FIRE_DELAY + RandomFloat(-BOT_WEAPON_TIME_FIRE_DELAY_VARIANCE/2, BOT_WEAPON_TIME_FIRE_DELAY_VARIANCE/2)
			}
		}

		DrawDebugInfo()
	}

	me = null

	locomotion = null

	path_ent = null
	max_dist_from_path_ent = null
	curtime = 0.0
	m_vecAbsOrigin = Vector()
	m_angAbsRotation = QAngle()
	m_vecEyePosition = Vector()

	look_dir = Vector()

	path = []
	path_index = 0

	path_target_pos = Vector()
	path_update_time_next = 0.0
	path_update_time_delay = 0.0
	path_update_force = false
	path_areas = {}

	sequence_spawn = -1
	sequence_idle = -1
	sequence_run = -1
	pose_move_x = -1
	pose_move_y = -1
	pose_body_pitch = -1
	pose_body_yaw = -1

	weapon = null
	attachment_muzzle = 0

	next_primary_attack = 0.0
	attack_target = null
	attack_target_focus_timer = 0.0
	next_vocalize_time = 0.0

    damage_force = null
}

if (this == getroottable())
{
	function SoldierCreate(spawner, team, starting_path = null)
	{

		local entity = SpawnEntityFromTable("base_boss",
		{
			targetname = "minionbot_" + BOT_BASE_NAME + UniqueString(),
            teamnum = team,
			origin = spawner.GetOrigin(),
            angles = spawner.GetAngles(),
			model = BOT_MODEL,
			skin = (team == 2) ? RED_TEAM_COLOR_NUM : (team == 3) ? BLU_TEAM_COLOR_NUM : NEU_TEAM_COLOR_NUM,
			playbackrate = 1.0,
			health = BOT_HEALTH
		})
        EntityOutputs.AddOutput(entity, "OnKilled", "item_currencypack*", "Kill", null, -1, -1)

		//entity.SetSolid(Constants.ESolidType.SOLID_NONE)
		//entity.SetSolid(0)


		entity.ValidateScriptScope()
		entity.GetScriptScope().nextbot <- Soldier_Minion(entity, starting_path)

		return entity
	}

	AddThinkToEnt(worldspawn, "UpdateBots")
	//SoldierCreate()
}
else
{
	function OnPostSpawn()
	{
		self.ValidateScriptScope()
		self.GetScriptScope().nextbot <- Soldier_Minion(self)
	}
}

::IsPotentiallyChaseable <- function (victim)
{
	if (victim == null || !victim.IsValid())
		return false

    if (!IsValidEnemyTarget(victim))
        return false

	if (NetProps.GetPropInt(victim, "m_lifeState") != 0)
		return false

	local area = victim.GetLastKnownArea()
	if (area == null || area.HasAttributeTF(TF_NAV_SPAWN_ROOM_BLUE | TF_NAV_SPAWN_ROOM_RED))
		return false

	return true
}

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

::IsLineOfSightClear <- function(entity, target)
{
	local trace =
	{
		start = m_vecEyePosition,
		end = target.GetCenter(),
		ignore = entity,
		mask = MASK_BLOCKLOS_AND_NPCS | CONTENTS_IGNORE_NODRAW_OPAQUE
	}

	if (!TraceLineEx(trace) || !("enthit" in trace))
		return false


	return trace.enthit == target
}

::PointWithinViewAngle <- function(pos_src, pos_target, look_dir, half_fov)
{
	local delta = pos_target - pos_src
	local cos_diff = look_dir.Dot(delta)

	if (cos_diff < 0)
		return false

	return (cos_diff * cos_diff > delta.LengthSqr() * half_fov * half_fov)
}

::IsPlayerStealthed <- function(player)
{
	return player.IsStealthed() &&
		!player.InCond(TF_COND_BURNING) &&
		!player.InCond(TF_COND_URINE) &&
		!player.InCond(TF_COND_STEALTHED_BLINK) &&
		!player.InCond(TF_COND_BLEEDING)
}