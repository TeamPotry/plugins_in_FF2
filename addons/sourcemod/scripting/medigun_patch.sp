#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <dhooks>

#include <medigun_patch>

#pragma newdecls required

#define PLUGIN_NAME     "Example all-heal plugin"
#define PLUGIN_AUTHOR   "Naydef"
#define PLUGIN_VERSION  "1.0"

Handle OnHeal;

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    version = PLUGIN_VERSION,
};

Handle hDetourAllowedToHealTarget;

public void OnPluginStart()
{
    Handle gamedatafile=LoadGameConfigFile("ghostbuster_defs.games");
    if(gamedatafile==null)
    {
        SetFailState("Cannot find file ghostbuster_defs.games!");
    }
    hDetourAllowedToHealTarget=DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
    if(hDetourAllowedToHealTarget==null)
    {
        SetFailState("Failed to create CWeaponMedigun::AllowedToHealTarget detour!");
    }
    // Load the address of the function from PTaH's signature gamedata file.
    if(!DHookSetFromConf(hDetourAllowedToHealTarget, gamedatafile, SDKConf_Signature, "CWeaponMedigun::AllowedToHealTarget"))
    {
        SetFailState("Failed to load CWeaponMedigun::AllowedToHealTarget signature from gamedata");
    }
    // Load the address of the function from PTaH's signature gamedata file.
    delete gamedatafile;

    //CWeaponMedigun::AllowedToHealTarget
    DHookAddParam(hDetourAllowedToHealTarget, HookParamType_CBaseEntity);

    // Add a post hook on the function.
    if(!DHookEnableDetour(hDetourAllowedToHealTarget, false, Detour_AllowedToHealTargetPost))
    {
        SetFailState("Failed to detour CWeaponMedigun::AllowedToHealTarget!");
    }

    OnHeal = CreateGlobalForward("TF2_OnHealTarget", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
}

public MRESReturn Detour_AllowedToHealTargetPost(int pThis, Handle hReturn, Handle hParams)
{
    if(pThis==-1 || DHookIsNullParam(hParams, 1))
    {
        return MRES_Ignored;
    }
    int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity"), targettoheal=DHookGetParam(hParams, 1);
    bool result = false, tempResult = result;
    Action action;

    if(!IsValidEntity(targettoheal)) return MRES_Ignored;

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

        if(IsValidClient(owner) && TF2_GetClientTeam(owner) != TF2_GetClientTeam(targettoheal) && GetEntProp(pThis, Prop_Send, "m_bChargeRelease") <= 0)
        {
            SDKHooks_TakeDamage(targettoheal, owner, owner, 6.0, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, pThis, pos, pos);
            DHookSetReturn(hReturn, true);

            return MRES_ChangedOverride;
        }
    }
    /*
    else if(IsValidEntity(targettoheal) && targettoheal>MaxClients)
    {
        if(HasEntProp(targettoheal, Prop_Send, "m_iHealth"))
        {
            int health=GetEntProp(targettoheal, Prop_Send, "m_iHealth");
            SetEntProp(targettoheal, Prop_Send, "m_iHealth", health+5);
        }
    }
    */

    return MRES_Ignored;
}

stock bool IsValidClient(int client)
{
    return (0 < client && client <= MaxClients && IsClientInGame(client));
}
