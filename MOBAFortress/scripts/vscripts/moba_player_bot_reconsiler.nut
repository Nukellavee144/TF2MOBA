//Mimics player to player interactions for players vs base_boss minions

CheckForBackstabsThink <- function()
{
    self.GetScriptScope().CanBackstabBot = false

    if (self.GetActiveWeapon().GetClassname() != "tf_weapon_knife") return

    printl("Checking for Backstab")
    local enthit = SwingTrace(self)
    ClientPrint(GetListenServerHost(), 3, "" + Time()+ "" + enthit)

    if (!enthit) return

    local victimView = ent.GetAngles()
    victimView.z = 0
    victimView.Norm()

    local deltaPos = ent.GetOrigin() - self.GetOrigin()
    deltaPos.Norm()

    local spyView = self.EyeAngles().Forward()
    spyView.z = 0

    local knife  = self.GetActiveWeapon()
    local viewModel = NetProps.GetPropEntity(self, "m_hViewModel")

    if (    RAD2DEG*acos(victimView.Dot(deltaPos)) < 90 &&
            RAD2DEG*acos(spyView.Dot(deltaPos)) < 60 &&
            RAD2DEG*acos(spyView.Dot(victimView)) < 107.5 &&
            !(self.InCond(TF_COND_STEALTHED_BLINK) || self.IsStealthed()) )
    {
        if (!NetProps.GetPropBool(knife, "m_bReadyToBackstab"))
            NetProps.SetPropFloat(knife, "m_flTimeWeaponIdle", 0)

        NetProps.SetPropBool(knife, "m_bReadyToBackstab", true)
        self.GetScriptScope().CanBackstabBot = true
    }
//     else
//    {
//         if (NetProps.GetPropBool(knife, "m_bReadyToBackstab")) //Exit the backstab animation right away
//             NetProps.SetPropFloat(knife, "m_flTimeWeaponIdle", 0)
//         NetProps.SetPropBool(knife, "m_bReadyToBackstab", false)
//    }



    return 0.1
}

function OnGameEvent_post_inventory_application(params)
{
    local player = GetPlayerFromUserID(params.userid)

    NetProps.SetPropString(player, "m_iszScriptThinkFunction", "") //Reset players think

    if (NetProps.GetPropInt(player, "m_PlayerClass.m_iClass") == 8) //SPY
    {
        printl("Attaching to Spy")
        player.ValidateScriptScope()
        player.GetScriptScope().CheckForBackstabsThink <- CheckForBackstabsThink //Put the function inside of the Spy
        player.GetScriptScope().CanBackstabBot <- false //Create a variable to keep track of if we can backstab a bot
        AddThinkToEnt(player, "CheckForBackstabsThink")
    }

}

__CollectGameEventCallbacks(this)

function SwingTrace(player) {
    local eyePosition = player.EyePosition()
    local eyeAngles = player.EyeAngles()
    local trace = {
        start = eyePosition
        end = eyePosition + eyeAngles.Forward() * 48
        mask = 0x200400B // MASK_SOLID
        ignore = player,
        filter = function(entity)
        {
            if (IsMinion(entity) && entity.GetTeam() != self.GetTeam())
                return TRACE_STOP;
            return TRACE_CONTINUE;
        }
    }
    TraceLineEx(trace)
    if (!trace.hit) {
        trace.hullmin <- Vector(-18, -18, -18)
        trace.hullmax <- Vector(18, 18, 18)
        TraceHull(trace)
    }
    if ("enthit" in trace)
        return trace.enthit

    return null
}