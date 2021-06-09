#include <sourcemod>
#include <tf2items>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>

#define PLUGIN_VERSION "20201104"

public Plugin:myinfo = {
	name = "Freak Fortress 2: Kill useless person",
	description = "",
	author = "Nopied◎",
	version = PLUGIN_VERSION,
};

ConVar CvarStartTimer, CvarAmountOfDamage;

public void OnPluginStart()
{
    CvarStartTimer = CreateConVar("ff2_kill_useless_after_start", "0.0", "Amount of seconds for start kill the useless after round start. 0 to disable", _, true, 0.0);
    CvarAmountOfDamage = CreateConVar("ff2_useless_damage", "0", "To kill the useless who has less damage than this value. 0 to disable", _, true, 0.0);

    HookEvent("teamplay_round_start", OnRoundStart);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    float timer = CvarStartTimer.FloatValue;

    if(timer > 0.0)
        CreateTimer(15.4 + timer, KillUseless, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action KillUseless(Handle timer)
{
    int amount = CvarAmountOfDamage.IntValue;

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client)
        && FF2_GetBossTeam() != TF2_GetClientTeam(client) && FF2_GetClientDamage(client) < amount)
            FakeClientCommandEx(client, "kill");
    }

    return Plugin_Continue;
}
