#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
    RegConsoleCmd("dec", Command_Dec, "");
}

public Action Command_Dec(int client, int args)
{
    int decapitations=GetEntProp(client, Prop_Send, "m_iDecapitations");
    PrintToChatAll("%d", decapitations);
}
