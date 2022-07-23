#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2utils>
#include <dhooks>
#include <tf2attributes>
#include <medigun_patch>

#pragma newdecls required

#define PLUGIN_NAME     "Medigun Patch"
#define PLUGIN_AUTHOR   "Nopied"
#define PLUGIN_VERSION  "20220723"

Handle OnHeal;

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    version = PLUGIN_VERSION,
};

float g_flLastDamgeTime[MAXPLAYERS+1];

public void OnPluginStart()
{
    HookEvent("teamplay_round_start", OnRoundStart);

    GameData gamedatafile = LoadGameConfigFile("ghostbuster_defs.games");
    if(gamedatafile == null)
        SetFailState("Cannot find file ghostbuster_defs.games!");

    CreateDynamicDetour(gamedatafile, "CWeaponMedigun::AllowedToHealTarget", _, Detour_AllowedToHealTargetPost);
    // CreateDynamicDetour(gamedatafile, "CWeaponMedigun::HealTargetThink", DHookCallback_Medigun_HealTargetThink_Pre, DHookCallback_Medigun_HealTargetThink_Post);
    delete gamedatafile;

    OnHeal = CreateGlobalForward("TF2_OnHealTarget", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        g_flLastDamgeTime[client] = 0.0;
    }
}

static void CreateDynamicDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if (detour)
	{
		if (callbackPre != INVALID_FUNCTION)
			detour.Enable(Hook_Pre, callbackPre);

		if (callbackPost != INVALID_FUNCTION)
			detour.Enable(Hook_Post, callbackPost);
	}
	else
	{
		LogError("Failed to create detour setup handle for %s", name);
	}
}

// bool g_bBlockHealing = false;
// int g_iCurrentHealth, g_iHealingTarget;

public MRESReturn Detour_AllowedToHealTargetPost(int pThis, Handle hReturn, Handle hParams)
{
    if(pThis==-1 || DHookIsNullParam(hParams, 1))
    {
        return MRES_Ignored;
    }
    int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity"), targettoheal=DHookGetParam(hParams, 1);
    bool result = false, tempResult = result;
    Action action;

    if(!IsValidEntity(targettoheal) || targettoheal == 0) return MRES_Ignored;

    Call_StartForward(OnHeal);
    Call_PushCell(owner);
    Call_PushCell(targettoheal);
    Call_PushCellRef(tempResult);
    Call_Finish(action);

    if(action == Plugin_Changed)
    {
        result = tempResult;
        DHookSetReturn(hReturn, result);
        return MRES_ChangedOverride;
    }

    if(IsValidClient(targettoheal) && IsPlayerAlive(targettoheal))
    {
        float pos[3];
        GetClientEyePosition(targettoheal, pos);

        if(IsValidClient(owner) && TF2_GetClientTeam(owner) != TF2_GetClientTeam(targettoheal)
        && GetEntPropFloat(pThis, Prop_Send, "m_flChargeLevel") < 1.0 && GetEntProp(pThis, Prop_Send, "m_bChargeRelease") == 0)
        {
            if(!(TF2_IsPlayerInCondition(targettoheal, TFCond_Ubercharged) || TF2_IsPlayerInCondition(targettoheal, TFCond_UberchargedHidden))
              && g_flLastDamgeTime[owner] < GetGameTime())
            {
                g_flLastDamgeTime[owner] = GetGameTime() + 0.15;
                // 30 per second (6.0 per 0.2 second)
                SDKHooks_TakeDamage(targettoheal, owner, owner, 6.0, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, pThis, pos, pos);

                // disable heal a while heal player on other team.
                TF2Attrib_AddCustomPlayerAttribute(owner, "heal rate penalty", 0.0, 0.25);
            }

            DHookSetReturn(hReturn, true);
            return MRES_ChangedOverride;
        }
    }
    else if(IsValidEntity(targettoheal) && targettoheal>MaxClients)
    {
        char classname[64];
        GetEntityClassname(targettoheal, classname, sizeof(classname));

        float pos[3];
        GetEntPropVector(targettoheal, Prop_Data, "m_vecOrigin", pos);

        if(!StrEqual(classname, "obj_dispenser") && !StrEqual(classname, "obj_sentrygun")
            && !StrEqual(classname, "obj_teleporter"))
                return MRES_Ignored;

        if(GetClientTeam(owner) != GetEntProp(targettoheal, Prop_Send, "m_iTeamNum")
            && g_flLastDamgeTime[owner] < GetGameTime())
        {
            g_flLastDamgeTime[owner] = GetGameTime() + 0.15;
            // 30 per second (6.0 per 0.2 second)
            SDKHooks_TakeDamage(targettoheal, owner, owner, 6.0, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, pThis, pos, pos);

            // disable heal a while heal player on other team.
            TF2Attrib_AddCustomPlayerAttribute(owner, "heal rate penalty", 0.0, 0.25);
            // g_bBlockHealing = true;
            // g_iHealingTarget = targettoheal;
        }

        DHookSetReturn(hReturn, true);
        return MRES_ChangedOverride;
    }

    return MRES_Ignored;
}
/*
public MRESReturn DHookCallback_Medigun_HealTargetThink_Pre(int pThis)
{
    if(pThis==-1)			return MRES_Ignored;

    if(g_bBlockHealing)
        g_iCurrentHealth = GetEntProp(g_iHealingTarget, Prop_Data, "m_iHealth");

    return MRES_Ignored;
}

public MRESReturn DHookCallback_Medigun_HealTargetThink_Post(int pThis)
{
    bool blockThis = g_bBlockHealing;
    g_bBlockHealing = false;

    if(pThis==-1)			return MRES_Ignored;

    if(blockThis)
        SetEntProp(g_iHealingTarget, Prop_Data, "m_iHealth", g_iCurrentHealth);

    return MRES_Ignored;
}
*/
stock bool IsValidClient(int client)
{
    return (0 < client && client <= MaxClients && IsClientInGame(client));
}
