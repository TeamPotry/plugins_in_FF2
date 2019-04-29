#include <sourcemod>
#include <sdktools>

#define VMT_PATH "materials/potry/steam_sale/10.vmt"
#define MODEL_PATH "materials/potry/steam_sale/10.vtf"

int spriteIndex;

public void OnPluginStart()
{
    spriteIndex = PrecacheModel(VMT_PATH);
    AddFileToDownloadsTable(VMT_PATH);
    AddFileToDownloadsTable(MODEL_PATH);

    RegAdminCmd("viewmodel", TestCmd, ADMFLAG_CHEATS);
}

public Action TestCmd(int client, int argc)
{
    float pos[3];
    GetClientEyePosition(client, pos);

    pos[2] += 15.0;

    TE_SetupGlowSprite(pos, spriteIndex, 10.0, 0.1, 255);
    TE_SendToAll();
}
/*
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(IsClientInGame(client) && IsPlayerAlive(client))
    {
        PrintCenterText(client, "%d", GetEntPropEnt(client, Prop_Send, "m_hViewModel"));
    }
}
*/
