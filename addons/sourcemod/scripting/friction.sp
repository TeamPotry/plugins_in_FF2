public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(!IsClientInGame(client) || !IsPlayerAlive(client))   continue;

        int frictionOffset = FindSendPropInfo("CBasePlayer", "m_szLastPlaceName") + 104;
        SetEntDataFloat(client, frictionOffset, 0.1); // momsurffix2.games.txt

        // PrintToChatAll("%d", frictionOffset);


        // SetEntPropFloat(client, Prop_Send, "m_flConstraintRadius", 1000.0);
        // SetEntPropFloat(client, Prop_Send, "m_flConstraintSpeedFactor", 100.2);
    }
}
