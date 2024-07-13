IncludeScript("moba_fortress/bots/bot_soldier/bot_soldier_states.nut");
IncludeScript("moba_fortress/bots/bot_nav.nut");
IncludeScript("moba_fortress/bots/bot_target.nut");

self.KeyValueFromFloat("speed", 300);
EntFireByHandle(self, "SetStepHeight", "1", -1, null, null);
SetPropVector(self, "m_vecViewOffset", Vector(0, 0, 70));

playerTarget <- null
moveTarget <- null
stuckTicks <- 0;
targetTicks <- 0;

function SoldierThink()
{
    state.ThinkInner()
    self.StudioFrameAdvance()

    try
    {
      if (targetTicks++ > 66)
      {
        targetTicks = 0;
        LookForTarget();
      }
    }
    catch(e) { }

    DebugDrawText(self.GetCenter() + self.GetUpVector()*50, "State: " + state.name, false, FrameTime() * 2.0)
    DebugDrawText(self.GetCenter() + self.GetUpVector()*70, "Target: " + self.GetScriptScope().playerTarget, false, FrameTime() * 2.0)
    return -1
}