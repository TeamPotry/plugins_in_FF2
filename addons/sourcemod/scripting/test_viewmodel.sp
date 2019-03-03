public void OnPluginStart()
{
    RegAdminCmd("viewmodel", TestCmd, ADMFLAG_CHEATS);
}

public Action TestCmd(int client, int argc)
{
    //
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(IsClientInGame(client) && IsPlayerAlive(client))
    {
        PrintCenterText(client, "%d", GetEntPropEnt(client, Prop_Send, "m_hViewModel"));
    }
}
