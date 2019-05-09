#include <sourcemod>
#include <sdktools>
#include <sprites>

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
    Sprite sprite = Sprite.Init("test", spriteIndex);

    pos[2] += 15.0;
    sprite.SetPos(pos);
    sprite.Parent = client;
    sprite.Time = 10.0;
    sprite.Size = 0.1;

    sprite.Fire();
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
