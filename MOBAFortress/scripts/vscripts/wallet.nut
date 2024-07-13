local g_kill_pay = 10000
local g_assist_pay = 50

local debug = true

GameModeUsesCurrency()
GameModeUsesUpgrades()
ForceEnableUpgrades(2)


function OnGameEvent_player_death(params)
{
    local attacker  = GetPlayerFromUserID(params.attacker)
    local assister  = GetPlayerFromUserID(params.assister)
    local victim    = GetPlayerFromUserID(params.userid)

    if(!attacker) return //If there is no attacker, like environmental kills, return

    if (attacker == victim) return //Do not pay anyone if they died of suicide

    if (debug) printl("Paying player " + attacker + " $" + g_kill_pay)
    attacker.AddCurrency(g_kill_pay)

    //Award Medics full pay for assists
    if (assister)
    {
        if(assister.GetPlayerClass() == 5)
        {
            if (debug) printl("Awarded ASSISTER with " + " $" + g_kill_pay)
            assister.AddCurrency(g_kill_pay)
        }
        else
        {
            if (debug) printl("Awarded ASSISTER with " + " $" + g_assist_pay)
            assister.AddCurrency(g_assist_pay)
        }
    }
}




__CollectGameEventCallbacks(this)

