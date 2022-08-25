#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

Handle g_SDKCallSentryDeploy;

public void OnPluginStart()
{
    RegConsoleCmd("testengi", TestCmd);

    GameData gamedata = new GameData("potry");
    if (gamedata)
    {
        g_SDKCallSentryDeploy = PrepSDKCall_SentryDeploy(gamedata);
    }
}

Handle PrepSDKCall_SentryDeploy(GameData gamedata)
{
    StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFWeaponBuilder::Deploy");

	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDK call: CTFWeaponBuilder::Deploy");

	return call;
}

void SDKCall_SentryDeploy(int pda)
{
	if (g_SDKCallSentryDeploy)
		SDKCall(g_SDKCallSentryDeploy, pda);
}

public Action TestCmd(int client, int args)
{
    char classname[64];
    for(int loop = 0; loop <= TFWeaponSlot_Item2; loop++)
    {
        int temp = GetPlayerWeaponSlot(client, loop);
        if(IsValidEntity(temp))
        {
            GetEntityClassname(temp, classname, sizeof(classname));
            PrintToChatAll("slot = %d, classname = ''%s''", loop, classname);
        }
    }

    int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);// GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    int m_hObjectBeingBuilt = GetEntPropEnt(weapon, Prop_Send, "m_hObjectBeingBuilt");
    bool m_aBuildableObjectTypes[4];
    for(int loop = 0; loop < 4; loop++)
    {
        m_aBuildableObjectTypes[loop] = GetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", _, loop) > 0;

        PrintToChatAll("m_aBuildableObjectTypes[%d] = %s", loop, m_aBuildableObjectTypes[loop] ? "true" : "false");
    }

    PrintToChatAll("m_hObjectBeingBuilt = %d", m_hObjectBeingBuilt);

    float temp[3];
    int sentry = TF2_BuildSentry(client, temp, temp, 3);
    if(IsValidEntity(sentry))
    {
        // DispatchSpawn(sentry);
        SetEntPropEnt(weapon, Prop_Send, "m_hObjectBeingBuilt", sentry);
        SetEntProp(weapon, Prop_Send, "m_iBuildState", 2);

        SetEntProp(sentry, Prop_Send, "m_bCarried", 1);
		SetEntProp(sentry, Prop_Send, "m_bPlacing", 1);
		SetEntProp(sentry, Prop_Send, "m_bCarryDeploy", 0);
		SetEntProp(sentry, Prop_Send, "m_iDesiredBuildRotations", 0);
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", 1);

        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
        SDKCall_SentryDeploy(weapon);

        PrintToChatAll("sentry = %d", sentry);
    }
    return Plugin_Continue;
}

stock int TF2_BuildSentry(int builder, float fOrigin[3], float fAngle[3], int level, bool mini=false, bool disposable=false, bool carried=false, int flags=4)
{
    static const float m_vecMinsMini[3] = {-15.0, -15.0, 0.0};
    float m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
    static const float m_vecMinsDisp[3] = {-13.0, -13.0, 0.0};
    float m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};

    int sentry = CreateEntityByName("obj_sentrygun");

    if(IsValidEntity(sentry))
    {
        AcceptEntityInput(sentry, "SetBuilder", builder);

        DispatchKeyValueVector(sentry, "origin", fOrigin);
        DispatchKeyValueVector(sentry, "angles", fAngle);

        if(mini)
        {
            SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
            SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
            SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
            // SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
            SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
            DispatchSpawn(sentry);

            SetVariantInt(100);
            AcceptEntityInput(sentry, "SetHealth");

            SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
            SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
            SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
        }
        else if(disposable)
        {
            SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
            SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
            SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
            // SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
            SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
            DispatchSpawn(sentry);

            SetVariantInt(100);
            AcceptEntityInput(sentry, "SetHealth");

            SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
            SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
            SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
        }
        else
        {
            SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
            SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
            SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
            // SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
            SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
            DispatchSpawn(sentry);
        }

        // SetEntProp(sentry, Prop_Send, "m_bPlayerControlled", 1);
        SetEntProp(sentry, Prop_Send, "m_iTeamNum", GetClientTeam(builder));

        return sentry;
    }

    return -1;
}
