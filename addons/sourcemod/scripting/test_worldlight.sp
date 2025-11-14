#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public void OnPluginStart()
{
    RegAdminCmd("light", Cmd_Test, ADMFLAG_CHEATS);
}

public Action Cmd_Test(int client, int args)
{
    char lightstyle[32];
    GetCmdArg(1, lightstyle, sizeof(lightstyle));

    SetLightStyle(0, lightstyle);

    return Plugin_Continue;
}