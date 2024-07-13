local precacheme  = Entities.FindByClassname(null, "player");
precacheme.PrecacheSoundScript("MVM.SentryBusterIntro")
precacheme.PrecacheSoundScript("MVM.SentryBusterLoop")
precacheme.PrecacheSoundScript("MVM.SentryBusterSpin")
precacheme.PrecacheSoundScript("MVM.SentryBusterExplode")

precacheme.PrecacheSoundScript("Robot.Greeting")

PrecacheModel("models/bots/demo/bot_team_sentry_buster.mdl")

class BaseBuster
{
    constructor(baseBotHealth, baseBotScale, baseBotModel, baseBotSpeed, baseAnimPlaybackRate, baseBotAnimIdle, baseBotAnimMove, baseBotAnimDetonate, baseBotAnimDance, baseExplosionRadius)
    {
        health              = baseBotHealth
        scale               = baseBotScale
        model               = baseBotModel
        speed               = baseBotSpeed
        animIdle            = baseBotAnimIdle
        animMove            = baseBotAnimMove
        animPlaybackRate    = baseAnimPlaybackRate
        animDetonate        = baseBotAnimDetonate
        animeDance          = baseBotAnimDance
        explosionRadius     = baseExplosionRadius
    }

    health              = null
    scale               = null
    model               = null
    speed               = null
    animPlaybackRate    = null
    animIdle            = null
    animMove            = null
    animDetonate        = null
    animeDance          = null
    explosionRadius     = null
}

sentryBusterBot <- BaseBuster(500,   1,    "models/bots/demo/bot_team_sentry_buster.mdl", 300,     1,    "Stand_MELEE",  "Run_MELEE", "sentry_buster_preExplode", "primary_deploybomb", 200)

enum state
{
    idle        = "idle"
    move        = "move"
    detonate    = "detonate"
    dance       = "dance"
}


// The big boy that handles all our behavior
class BusterBot
{
	function constructor(bot_ent, follow_ent, bot_type, owner)
	{
		bot = bot_ent;

        myowner = owner

		move_speed = bot_type.speed;
		turn_rate = 2.0;
		search_dist_z = 128.0;
		search_dist_nearest = 128.0;

		path = [];
		path_index = 0;
		path_reach_dist = 16.0;
		path_follow_ent = follow_ent;
		path_follow_ent_dist = 100.0;
        detonate_dist = 50;
		path_target_pos = follow_ent.GetOrigin();
		path_update_time_next = Time();
		path_update_time_delay = 0.2;
		path_update_force = true;
		area_list = {};

		seq_idle = bot_ent.LookupSequence(bot_type.animIdle);
		seq_run = bot_ent.LookupSequence(bot_type.animMove);
        seq_det = bot_ent.LookupSequence(bot_type.animDetonate)
        seq_dance = bot_ent.LookupSequence(bot_type.animeDance)
		pose_move_x = bot_ent.LookupPoseParameter("move_x");

        curState = state.dance
		debug = 0;

		// Add behavior that will run every tick
		AddThinkToEnt(bot_ent, "BotThink");
	}

	function UpdatePath()
	{
		// Clear out the path first
		ResetPath();

		// If there is a follow entity specified, then the bot will pathfind to the entity
		if (path_follow_ent && path_follow_ent.IsValid())
			path_target_pos = path_follow_ent.GetOrigin();

		// Pathfind from the bot's position to the target position
		local pos_start = bot.GetOrigin();
		local pos_end = path_target_pos;

		local area_start = NavMesh.GetNavArea(pos_start, search_dist_z);
		local area_end = NavMesh.GetNavArea(pos_end, search_dist_z);

		// If either area was not found, try use the closest one
		if (area_start == null)
			area_start = NavMesh.GetNearestNavArea(pos_start, search_dist_nearest, false, true);
		if (area_end == null)
			area_end = NavMesh.GetNearestNavArea(pos_end, search_dist_nearest, false, true);

		// If either area is still missing, then bot can't progress
		if (area_start == null || area_end == null)
			return false;

		// If the start and end area is the same, one path point is enough and all the expensive path building can be skipped
		if (area_start == area_end)
		{
			path.append(PathPoint(area_end, pos_end, Constants.ENavTraverseType.NUM_TRAVERSE_TYPES));
			return true;
		}

		// Build list of areas required to get from the start to the end
		if (!NavMesh.GetNavAreasFromBuildPath(area_start, area_end, pos_end, 0.0, Constants.ETFTeam.TEAM_ANY, false, area_list))
			return false;

		// No areas found? Uh oh
		if (area_list.len() == 0)
			return false;

		// Now build points using the list of areas, which the bot will then follow
		local area_target = area_list["area0"];
		local area = area_target;
		local area_count = area_list.len();

		// Iterate through the list of areas in order and initialize points
		for (local i = 0; i < area_count && area != null; i++)
		{
			path.append(PathPoint(area, area.GetCenter(), area.GetParentHow()));
			area = area.GetParent(); // Advances to the next connected area
		}

		// Reverse the list of path points as the area list is connected backwards
		path.reverse();

		// Now compute accurate path points, using adjacent points + direction data from nav
		local path_first = path[0];
		local path_count = path.len();

		// First point is simply our current position
		path_first.pos = bot.GetOrigin();
		path_first.how = Constants.ENavTraverseType.NUM_TRAVERSE_TYPES; // No direction specified

		for (local i = 1; i < path_count; i++)
		{
			local path_from = path[i - 1];
			local path_to = path[i];

			// Computes closest point within the "portal" between adjacent areas
			path_to.pos = path_from.area.ComputeClosestPointInPortal(path_to.area, path_to.how, path_from.pos);
		}

		// Add a final point so the bot can precisely move towards the end point when it reaches the final area
		path.append(PathPoint(area_end, pos_end, Constants.ENavTraverseType.NUM_TRAVERSE_TYPES));
	}

	function AdvancePath()
	{
		// Check for valid path first
		local path_len = path.len();
		if (path_len == 0)
			return false;

		local path_pos = path[path_index].pos;
		local bot_pos = bot.GetOrigin();

		// Are we close enough to the path point to consider it as 'reached'?
		if ((path_pos - bot_pos).Length2D() < path_reach_dist)
		{
			// Start moving to the next point
			path_index++;
			if (path_index >= path_len)
			{
				// End of the line!
				ResetPath();
				return false;
			}
		}

		return true;
	}

	function ResetPath()
	{
		area_list.clear();
		path.clear();
		path_index = 0;
	}

	function Move()
	{
		// Recompute the path if forced to do so
		if (path_update_force)
		{
			UpdatePath();
			path_update_force = false;
		}
		// Recompute path to our target if present
		else if (path_follow_ent && path_follow_ent.IsValid())
		{
			// Is it time to re-compute the path?
			local time = Time();
			if (path_update_time_next < time)
			{
				// Check if the bot is close enough to the path_track
				if ((path_target_pos - path_follow_ent.GetOrigin()).Length() > detonate_dist)
				{

                    UpdatePath();
					// Don't recompute again for a moment
					path_update_time_next = time + path_update_time_delay;
				}
                else if((bot.GetOrigin() - path_follow_ent.GetOrigin()).Length() < detonate_dist)
                {
                    curState = state.detonate
                    return
                }
			}
		}

		// Check and advance up our path
		if (AdvancePath())
		{
			local path_pos = path[path_index].pos;
			local bot_pos = bot.GetOrigin();

			// Direction towards path point
			local move_dir = (path_pos - bot_pos);
			move_dir.Norm();

			// Convert direction into angle form
			local move_ang = VectorAngles(move_dir);

			// Approach new desired angle but only on the Y axis
			local bot_ang = bot.GetAbsAngles()
			move_ang.x = bot_ang.x;
			move_ang.y = ApproachAngle(move_ang.y, bot_ang.y, turn_rate);
			move_ang.z = bot_ang.z;

			// Set our new position and angles
			// Velocity is calculated from direction times speed, and converted from per-second to per-tick time
			bot.SetAbsOrigin(bot_pos + (move_dir * move_speed * FrameTime()));
			bot.SetAbsAngles(move_ang);

            curState = state.move;
			return
		}
		curState = state.idle
		return
	}

	function Update()
	{
        if(debug == 1) DebugDrawText(bot.GetOrigin(), curState, false, 0.05); //Show our state above our head


        //=======================================STATES==============================================
        if (curState == state.idle)
        {
            if (bot.GetSequence() != seq_idle)
			{
				bot.SetSequence(seq_idle);
				bot.SetPoseParameter(pose_move_x, 0.0); // Clear the move_x pose
			}

            if ((bot.GetOrigin() - path_follow_ent.GetOrigin()).Length() > path_follow_ent_dist)
            {
                curState = state.move
            }
        }

        if (curState == state.move)
        {
            // Moving, set the run animation
            if (bot.GetSequence() != seq_run)
            {
                bot.SetSequence(seq_run);
                bot.SetPoseParameter(pose_move_x, 1.0); // Set the move_x pose to max weight
            }
            Move()
        }

        if (curState == state.detonate)
        {
            if (bot.GetSequence() != seq_det)
            {
                bot.SetCycle(0.0)
                bot.SetSequence(seq_det);
                EmitSoundOn("MVM.SentryBusterSpin", bot)
            }

            if (( bot.GetSequence() == seq_det && bot.GetCycle() > 0.99) && (NetProps.GetPropInt(bot, "m_lifeState") != 1) )
            {
                EmitSoundOn("MVM.SentryBusterExplode", bot)
                DispatchParticleEffect("rd_robot_explosion", bot.GetOrigin(), bot.GetAngles())

				local prevIgnore = null
                for (local ent; ent = Entities.FindInSphere(ent, bot.GetOrigin(), 200);) //TODO, impliment explosion radius variable to replace 200
                    {
                        if ( ((ent.GetTeam() != myowner.GetTeam()) && (ent.GetTeam() != 0)) || (ent == myowner) ) //Only kill enemies and the owner of the buster
                        {
							local trace =
							{
								start       = bot.GetCenter(),
								end         = ent.GetCenter(),
								mask 		= 33636363 //MASK_PLAYERSOLID
							}
							TraceLineEx(trace)

                            trace.enthit.TakeDamageEx(myowner, myowner, null, ent.GetCenter(), bot.GetCenter(), ent.GetHealth()*2, 64 + 2097152)
							prevIgnore = trace.enthit
						}
                    }

                bot.Kill()
                bot = null
            }
        }

        if (curState == state.dance)
        {
            if (bot.GetSequence() != seq_dance)
            {
                bot.SetSequence(seq_dance);
            }

            if (bot.GetCycle() > 0.05 && bot.GetCycle() < 0.06) EmitSoundOn("Robot.Greeting", bot) // Play a friendly sound on spawn

            if (bot.GetSequence() == seq_dance && bot.GetCycle() > 0.2) //Switch to the idle state when we are done with %20 of the animation
            {
                curState = state.idle
            }
        }


        //=======================================/STATES==============================================


        if(!bot) return 0.0

		// Replay animation if it has finished
		if (bot.GetCycle() > 0.99)
			bot.SetCycle(0.0);

		// Run animations
        bot.StudioFrameAdvance();
        bot.DispatchAnimEvents(bot);

		// Visualize current path in debug mode
		if (debug == 2)
		{
			// Stay around for 1 tick
			// Debugoverlays are created on 1st tick but start rendering on 2nd tick, hence this must be doubled
			local frame_time = FrameTime() * 2.0;

			// Draw connected path points
			local path_len = path.len();
			if (path_len > 0)
			{
				local path_start_index = path_index;
				if (path_start_index == 0)
					path_start_index++;

				for (local i = path_start_index; i < path_len; i++)
				{
					DebugDrawLine(path[i - 1].pos, path[i].pos, 0, 255, 0, true, frame_time);
				}
			}

			// Draw areas from built path
			foreach (name, area in area_list)
			{
				area.DebugDrawFilled(255, 0, 0, 30, frame_time, true, 0.0);
				DebugDrawText(area.GetCenter(), name, false, frame_time);
			}
		}

		return 0.0; // Think again next frame
	}

    function OnKilled()
	{
		// Change life state to "dying"
		// The bot won't take any more damage, and sentries will stop targeting it
		NetProps.SetPropInt(bot, "m_lifeState", 1);
		// Reset health, preventing the default base_boss death behavior
		bot.SetHealth(bot.GetMaxHealth() * 20);
		// Custom death behavior can be added here
		// For this example, turn into a ragdoll with the saved damage force
		bot.BecomeRagdollOnClient(damage_force);

        bot.StopSound("MVM.SentryBusterSpin")
	}

	bot = null;						// The bot entity we belong to
    myowner = null

	move_speed = null;				// How fast to move
	turn_rate = null;				// How fast to turn
	search_dist_z = null;			// Maximum distance to look for a nav area downwards
	search_dist_nearest = null; 	// Maximum distance to look for any nearby nav area

	path = null;					// List of BotPathPoints
	path_index = null;				// Current path point bot is at, -1 if none
	path_reach_dist = null;			// Distance to a path point to be considered as 'reached'
	path_follow_ent = null;			// What entity to move towards
	path_follow_ent_dist = null;	// Maximum distance after which the path is recomputed
									// if follow entity's current position is too far from our target position
    detonate_dist = null
	path_target_pos = null;			// Position where bot wants to navigate to
	path_update_time_next = null;	// Timer for when to update path again
	path_update_time_delay = null;  // Seconds to wait before trying to attempt to update path again
	path_update_force = null;		// Force path recomputation on the next tick
	area_list = null;				// List of areas built in path

	seq_idle = null;				// Animation to use when idle
	seq_run = null;
    seq_det = null;				// Animation to use when running
    seq_dance = null
	pose_move_x = null;				// Pose parameter to set for running animation

    expRadius = null

    curState = null

	damage_force = null;
	debug = true;					// When true, debug visualization is enabled
}

function BotThink()
{
	// Let the bot class handle all the work
	return self.GetScriptScope().my_bot.Update();
}

function SentryBusterCreate()
{
    local player = GetListenServerHost();

    local targetedSentry = FindClosestOfEnemyEntitiesToMe(player ,"obj_sentrygun*")
    if (targetedSentry)
    {
        // Find point where player is looking
        local team  = player.GetTeam()
        local trace =
        {
            start       = player.EyePosition() + (player.GetForwardVector() * 100),
            end         = player.EyePosition() + (player.GetForwardVector() * 100) + (Vector(0,0,-1) * 150),
			//end         = player.EyePosition() + (player.EyeAngles() * 100) + (Vector(0,0,-1) * 150),
            mask        = 81931, //MASK_PLAYERSOLID_BRUSHONLY
            ignore      = player
        }
        TraceLineEx(trace)

        DebugDrawLine(trace.start, trace.end, 255, 0, 0, true, 3)

        //Deny spawn if the hit location is greater than 45degrees
        if (trace.plane_normal.Dot(Vector(0, 0, 1)) <  0.707)
        {
            printl("Invalid bot spawn location");
            EmitSoundOnClient("Player.UseDeny" ,player)
            return false
        }


        // Spawn bot at the end point
        local bot = SpawnEntityFromTable("base_boss",
        {
            targetname      = "robotMinion_" + team,
            origin          = trace.pos,
            angles          = player.GetAngles(),
            TeamNum         = player.GetTeam()
            model           = sentryBusterBot.model,
            skin            = team - 2
            playbackrate    = 1.0,          // Required for animations to be simulated
            health          = sentryBusterBot.health,
            solid           = 0

        });

        EntityOutputs.AddOutput(bot, "OnKilled", "item_currencypack*", "Kill", null, 0.0, -1)
        // Add scope to the entity
        bot.ValidateScriptScope();

        EmitSoundOn("MVM.SentryBusterIntro", bot)
        DispatchParticleEffect((player.GetTeam() == 2) ? "teleportedin_red" : "teleportedin_blue", bot.GetOrigin(), bot.GetForwardVector())

        //EmitAmbientSoundOn("MVM.SentryBusterIntro", 50, 80, 1.0, bot)
        bot.GetScriptScope().my_bot <- BusterBot(bot, targetedSentry, sentryBusterBot, player)   //Append custom bot class and initialize its behavior
        return true
    }
    else
    {
        printl("No enemy Sentryguns on the map.");
        EmitSoundOnClient("Player.UseDeny" ,player)
        return false;
    }

}


__CollectGameEventCallbacks(this)

function FindClosestOfEnemyEntitiesToMe(me, classname)
{
    //Find all "classname"" on the map, we want to target the closest one to the player that spawned us
    local distanceToTarget = 9999999
    local previousDistanceToTarget = 99999999
    local targetedTarget = null

    for (local ent; ent = Entities.FindByClassname(ent, classname);)
    {
        if (ent) //Did we find a target?
        {
            if (ent.GetTeam() != me.GetTeam()) //Did we find an /enemy/ target?
            {
                distanceToTarget = (me.GetOrigin() - ent.GetOrigin()).Length()  //How far away is it?

                if (distanceToTarget < previousDistanceToTarget) //Is it closer than the previous record holder for closest target?
                {

                    targetedTarget = ent    //Oh it did? That's our new target

                }
            }
            previousDistanceToTarget = distanceToTarget //Store this distance for next check
        }
    }
    return targetedTarget
}