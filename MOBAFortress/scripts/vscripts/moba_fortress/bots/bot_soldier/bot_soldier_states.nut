local me = self

local SOLDIER_ANIM_SPAWN = "Stand_LOSER"
local SOLDIER_ANIM_IDLE = "Stand_SECONDARY"
local SOLDIER_ANIM_RUN = "Run_SECONDARY"

class State
{
  tick = 0;
  name = "error";

  function Start() { }

  function ThinkInner()
  {
    try
    {
      Think();
    }
    catch(e) { }
    tick++;
    if (tick == 1000)
      tick = 0;
  }

  function Think() { }
}

SpawnState <- class extends State
{
    name = "enter";

    function Think()
    {
        if (tick == 0)
        {
            me.ResetSequence(me.LookupSequence(SOLDIER_ANIM_SPAWN))
            me.SetPlaybackRate(SOLDIER_ANIM_RATE)
        }
        if (tick == 100)
        {
            me.GetScriptScope().SetState(me.GetScriptScope().RunState())
        }
    }
}

RunState <- class extends State
{
    runAnim = true;
    lastTickCycle = 0; //For smoothly transitioning between animations.
    name = "run";

    function Start()
    {
        me.ResetSequence(me.LookupSequence(SOLDIER_ANIM_RUN));
        me.SetPlaybackRate(SOLDIER_ANIM_RATE);
        lastTickCycle = me.GetCycle();
    }

    function Think()
    {

      //Switch between moving animation and standing if we're moving or not
      if (!runAnim && me.GetLocomotionInterface().IsAttemptingToMove())
      {
          runAnim = true;
          me.SetSequence(me.LookupSequence(SOLDIER_ANIM_RUN));
          me.SetPlaybackRate(SOLDIER_ANIM_RATE);
      }
      if (runAnim && !me.GetLocomotionInterface().IsAttemptingToMove())
      {
          runAnim = false;
          me.SetSequence(me.LookupSequence(SOLDIER_ANIM_IDLE));
      }

      //Get player target
      local playerTarget = me.GetScriptScope().playerTarget;

      //We need a new path towards target every 100 ticks for performance reasons
      if (playerTarget && tick % 100 == 0)
          me.GetScriptScope().needsNewPath = true;

      //We we need a new path, check every 10 ticks, and if we do, draw a path to the target or our movement state
      if (me.GetScriptScope().needsNewPath && tick % 10 == 0)
      {
          if (playerTarget)
              me.GetScriptScope().SetNewPath(targetOrigin);
          else
              me.GetScriptScope().SetState(PatrolState());
      }

      //If we don't have a target to attack, go back to moving on our path
      if (!playerTarget)
          return;
      me.GetScriptScope().MoveByCurrentPath();

      local cycle = me.GetCycle();
      if (cycle < lastTickCycle || !runAnim)
      {
          local distanceToTarget = (me.GetOrigin() - targetOrigin).Length();
          if (distanceToTarget < 350)
          {
              me.GetScriptScope().SetState(AttackState());
          }
          else if (distanceToTarget > 450 && Time() > me.GetScriptScope().lastThrowTime)
          {
              me.GetScriptScope().lastThrowTime = Time() + RandomFloat(2.5, 5);
              me.GetScriptScope().SetState(ThrowState());
          }
      }
      lastTickCycle = cycle;
    }
}

DeathState <- class extends State
{
  name = "death";

  function Start()
  {
    local gibs = SpawnEntityFromTable("prop_dynamic",
    {
      model = me.GetModelName(),
      origin = me.GetOrigin(),
      angles = me.GetAbsAngles(),
      skin = me.GetSkin()
    })
  EntFireByHandle(gibs, "Break", null, 0, null, null);

  local index = nextbots.find(me);
  if (index != null);
    nextbots.remove(index);
    me.Kill();
  }

  function Think()
  {

  }
}

state <- SpawnState(); //Starting State

function SetState(newState)
{
    state = newState;
    newState.Start();
}