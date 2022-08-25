#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iBeamModel, g_iHaloModel;

public void OnMapStart()
{
    Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if(gameConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}

	char buffer[PLATFORM_MAX_PATH];
	if(GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
	{
		g_iBeamModel = PrecacheModel(buffer);
	}
	if(GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
	{
		g_iHaloModel = PrecacheModel(buffer);
	}
	delete gameConfig;
}

public void OnGameFrame()
{
    float pos[3], vecMin[3], vecMax[3], temp[3], tempAngles[3];
    int colors[4] = {255, 255, 255, 255};

    for (int client = 1; client <= MaxClients; client++)
    {
        if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
            continue;

        GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
        GetEntPropVector(client, Prop_Send, "m_vecMins", vecMin);
        GetEntPropVector(client, Prop_Send, "m_vecMaxs", vecMax);

        if(IsStockInPosition(client, pos, vecMin, vecMax))
        {
            TR_GetEndPosition(temp);

            // TE_SetupBeamPoints(pos, temp, g_iBeamModel, g_iHaloModel, 0, 10, 10.0, 10.0, 30.0, 0, 0.0, colors, 10);
            TE_SetupSparks(temp, tempAngles, 1, 10);
    		TE_SendToClient(client);
        }
    }
}

stock bool IsStockInPosition(int ent, float pos[3], float vecMin[3], float vecMax[3])
{
	TR_TraceHullFilter(pos, pos, vecMin, vecMax, MASK_ALL, TraceAnything, ent);
	return TR_DidHit();
}

public bool TraceAnything(int entity, int contentsMask, any data)
{
    return entity == 0 || entity != data;
}
