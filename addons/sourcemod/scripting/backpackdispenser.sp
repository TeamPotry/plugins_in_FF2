#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <dhooks>

#pragma newdecls required

#define DISPENSER_BLUEPRINT	"models/buildables/dispenser_blueprint.mdl"

int g_CarriedDispenser[MAXPLAYERS+1];

#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)
bool g_bDispenserBlocked[MAX_EDICTS+1];

Handle g_hSDKMakeCarriedObject;
Handle g_hSDKAttachObjectToObject;
Handle g_hSDKLookupAttachment;
Handle g_hSDKSetParent;

public Plugin myinfo =
{
	name = "[TF2] Backpack Dispenser",
	author = "Pelipoika",
	description = "Engineers can carry their dispensers on their backs",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

public void OnPluginStart()
{
	GameData hConfig = LoadGameConfigFile("tf2.backpackdispenser");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Virtual, "CBaseObject::MakeCarriedObject");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); //Player
	if ((g_hSDKMakeCarriedObject = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed To create SDKCall for CBaseObject::MakeCarriedObject offset");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseObject::AttachObjectToObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer); //Player
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	if ((g_hSDKAttachObjectToObject = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed To create SDKCall for CBaseObject::AttachObjectToObject");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimating::LookupAttachment");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_hSDKLookupAttachment = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed To create SDKCall for CBaseAnimating::LookupAttachment");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseEntity::SetParent");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_hSDKSetParent = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed To create SDKCall for CBaseEntity::SetParent");

	CreateDynamicDetour(hConfig, "CTFPlayer::CanPickupBuilding", DHookCallback_CanPickupBuilding_Pre);

	delete hConfig;

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_dropobject", Event_PlayerDropObject);

	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
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

public MRESReturn DHookCallback_CanPickupBuilding_Pre(int client, DHookReturn ret, DHookParam params)
{
	if(params.IsNull(1))
		return MRES_Ignored;

	int dispenser = params.Get(1);
	if(g_CarriedDispenser[client] == EntIndexToEntRef(dispenser))
	{
		ret.Value = false;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public void OnMapStart()
{
	for(int i = 1; i <= MAX_EDICTS; i++)
		g_bDispenserBlocked[i] = false;
}

public void OnClientPutInServer(int client)
{
	g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
}

public void OnEntityDestroyed(int iEntity)
{
	if(IsValidEntity(iEntity))
	{
		char classname[64];
		GetEntityClassname(iEntity, classname, sizeof(classname));

		if(StrEqual(classname, "obj_dispenser"))
		{
			int builder = GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder");
			if(builder > 0 && builder <= MaxClients && IsClientInGame(builder))
			{
				if(g_CarriedDispenser[builder] != INVALID_ENT_REFERENCE)
				{
					int Dispenser = EntRefToEntIndex(g_CarriedDispenser[builder]);

					int iLink = GetEntPropEnt(Dispenser, Prop_Send, "m_hEffectEntity");
					if(IsValidEntity(iLink))
					{
						AcceptEntityInput(iLink, "ClearParent");
						AcceptEntityInput(iLink, "Kill");
					}

					g_CarriedDispenser[builder] = INVALID_ENT_REFERENCE;

					TF2_RemoveCondition(builder, TFCond_MarkedForDeath);
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		//When playing MvM we don't want blue engineers to be able to carry dispensers
		if(GameRules_GetProp("m_bPlayingMannVsMachine") && TF2_GetClientTeam(client) != TFTeam_Red)
			return Plugin_Changed;

		if(g_CarriedDispenser[client] == INVALID_ENT_REFERENCE)
		{
			if(buttons & IN_RELOAD && GetEntProp(client, Prop_Send, "m_bCarryingObject") != 1)
			{
				int iAim = GetClientAimTarget(client, false)
				if(IsValidEntity(iAim))
				{
					char strClass[64];
					GetEntityClassname(iAim, strClass, sizeof(strClass));
					if(StrEqual(strClass, "obj_dispenser") && IsBuilder(iAim, client))
					{
						EquipDispenser(client, iAim);
					}
				}
			}
		}
		else if(g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
		{
			if((buttons & IN_RELOAD && buttons & IN_ATTACK2) && GetEntProp(client, Prop_Send, "m_bCarryingObject") == 0 && g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
			{
				UnequipDispenser(client);
			}
		}

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client > 0 && client <= MaxClients && IsClientInGame(client) && g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
	{
		DestroyDispenser(client);
	}
}

public Action Event_PlayerDropObject(Event event, const char[] name, bool dontBroadcast)
{
	int index = event.GetInt("index");
	// PrintToServer("%d, %d", GetEntProp(index, Prop_Send, "m_nSolidType"), GetEntProp(index, Prop_Send, "m_usSolidFlags"));
	if(g_bDispenserBlocked[index])
	{
		// SetEntProp(index, Prop_Send, "m_CollisionGroup", 21);
		SetEntProp(index, Prop_Send, "m_nSolidType", 2);
		SetEntProp(index, Prop_Send, "m_usSolidFlags", 4);

		float temp[3];
		TeleportEntity(index, NULL_VECTOR, NULL_VECTOR, temp);

		g_bDispenserBlocked[index] = false;
	}
}

stock void EquipDispenser(int client, int target)
{
	float dPos[3], bPos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", dPos);
	GetClientAbsOrigin(client, bPos);

	if(GetVectorDistance(dPos, bPos) <= 125.0 && IsValidBuilding(target))
	{
		int trigger = -1;
		while ((trigger = FindEntityByClassname(trigger, "dispenser_touch_trigger")) != -1)
		{
			if(IsValidEntity(trigger))
			{
				int ownerentity = GetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity");
				if(ownerentity == target)
				{
					SetVariantString("!activator");
					AcceptEntityInput(trigger, "SetParent", target);
				}
			}
		}

		// PrintToServer("%d", GetEntProp(target, Prop_Send, "m_CollisionGroup"));

		int iLink = CreateLink(client);
		float pPos[3], pAng[3], pTemp[3];

		// SetVariantString("!activator");
		// AcceptEntityInput(target, "SetParent", iLink);

		// SetVariantString("flag");
		// AcceptEntityInput(target, "SetParentAttachment", client);

		int attachment = SDKCall(g_hSDKLookupAttachment, iLink, "flag");
		// PrintToServer("attachment: %d, g_hSDKLookupAttachment: %X", attachment, g_hSDKLookupAttachment);
		SDKCall(g_hSDKSetParent, target, iLink, attachment);

		SetEntPropEnt(target, Prop_Send, "m_hEffectEntity", iLink);
/*
		SetVariantString("!activator");
		AcceptEntityInput(target, "SetParent", client);

		SetVariantString("flag");
		AcceptEntityInput(target, "SetParentAttachment", client);
*/
		// PrintToChatAll("%d", GetEntProp(target, Prop_Send, "m_iDesiredBuildRotations"));

		// pPos[0] = 30.0;	//This moves it up/down
		// pPos[1] = 40.0;

		pPos[0] = -10.0; // 옆 회전
		pPos[1] = 75.0; // 높이?
		pPos[2] = 15.0; // 등에서 디스펜서와의 거리

		// pAng[0] = 180.0;
		pAng[0] = 95.0; // 앞쪽으로 기울리는 각도
		// pAng[1] = -90.0;
		pAng[1] = -90.0;
		// pAng[2] = 90.0;

		// SDKCall(g_hSDKAttachObjectToObject, target, client, 0, pTemp);

		SetEntPropVector(iLink, Prop_Send, "m_vecOrigin", pPos);
		SetEntPropVector(iLink, Prop_Send, "m_angRotation", pAng);

		// 아득히 안보이는 거리에 설치하여 플레이어가 집지 못하지 할 것
		// 너무 멀리 잡으면 회복 트리거가 인식을 못함 ㅇㄴ
		// pPos[0] = 200.0;
		pPos[0] = 0.0;
		pPos[1] = 60.0;
		pPos[2] = 60.0;

		// pAng[0] = 180.0;
		// pAng[1] = -90.0;
		// pAng[2] = 90.0;

		SetEntPropVector(target, Prop_Send, "m_vecOrigin", pPos);
		SetEntPropVector(target, Prop_Send, "m_angRotation", pAng);

		SetEntProp(target, Prop_Send, "m_CollisionGroup", 0);
		SetEntProp(target, Prop_Send, "m_nSolidType", 0);
		SetEntProp(target, Prop_Send, "m_usSolidFlags", 0x0004);

		SetEntProp(target, Prop_Send, "m_fEffects",
			GetEntProp(target, Prop_Send, "m_fEffects") | ~32);

		TF2_AddCondition(client, TFCond_MarkedForDeath, -1.0);

		g_CarriedDispenser[client] = EntIndexToEntRef(target);
	}
}
/*
public Action AttachDispenser(Handle timer, DataPack data)
{
	int link = data.ReadCell(), dispenser = data.ReadCell();

	SetVariantString("flag");
	AcceptEntityInput(dispenser, "SetParentAttachment", link);

	AcceptEntityInput(dispenser, "Hide");
	AcceptEntityInput(dispenser, "Show");
	return Plugin_Continue;
}
*/
stock void UnequipDispenser(int client)
{
	int Dispenser = EntRefToEntIndex(g_CarriedDispenser[client]);
	if(Dispenser != INVALID_ENT_REFERENCE)
	{
		int iBuilder = GetPlayerWeaponSlot(client, view_as<int>(TFWeaponSlot_PDA));

		SDKCall(g_hSDKMakeCarriedObject, Dispenser, client);

		SetEntPropEnt(iBuilder, Prop_Send, "m_hObjectBeingBuilt", Dispenser);
		SetEntProp(iBuilder, Prop_Send, "m_iBuildState", 2);

		SetEntProp(Dispenser, Prop_Send, "m_bCarried", 1);
		SetEntProp(Dispenser, Prop_Send, "m_bPlacing", 1);
		SetEntProp(Dispenser, Prop_Send, "m_bCarryDeploy", 0);
		SetEntProp(Dispenser, Prop_Send, "m_iDesiredBuildRotations", 0);
		SetEntProp(Dispenser, Prop_Send, "m_iUpgradeLevel", 1);

		// SetEntProp(Dispenser, Prop_Send, "m_CollisionGroup", 21);
		SetEntProp(Dispenser, Prop_Send, "m_nSolidType", 0);
		SetEntProp(Dispenser, Prop_Send, "m_usSolidFlags", 0x0004);
		g_bDispenserBlocked[Dispenser] = true;

		SetEntityModel(Dispenser, DISPENSER_BLUEPRINT);

		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iBuilder);
		AcceptEntityInput(Dispenser, "ClearParent");

		int iLink = GetEntPropEnt(Dispenser, Prop_Send, "m_hEffectEntity");
		if(IsValidEntity(iLink))
		{
			AcceptEntityInput(Dispenser, "ClearParent");
			AcceptEntityInput(iLink, "ClearParent");
			RemoveEntity(iLink);

			TF2_RemoveCondition(client, TFCond_MarkedForDeath);
		}

		g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
	}
}

stock void DestroyDispenser(int client)
{
	int Dispenser = EntRefToEntIndex(g_CarriedDispenser[client]);
	if(Dispenser != INVALID_ENT_REFERENCE)
	{
		int iLink = GetEntPropEnt(Dispenser, Prop_Send, "m_hEffectEntity");
		if(IsValidEntity(iLink))
		{
			AcceptEntityInput(iLink, "ClearParent");
			AcceptEntityInput(iLink, "Kill");

			SetVariantInt(5000);
			AcceptEntityInput(Dispenser, "RemoveHealth");

			TF2_RemoveCondition(client, TFCond_MarkedForDeath);

			g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
		}
	}
}

stock int CreateLink(int iClient)
{
	int iLink = CreateEntityByName("tf_taunt_prop");
	DispatchKeyValue(iLink, "targetname", "DispenserLink");
	DispatchSpawn(iLink);

	char strModel[PLATFORM_MAX_PATH];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", strModel, PLATFORM_MAX_PATH);

	SetEntityModel(iLink, strModel);

	SetEntProp(iLink, Prop_Send, "m_fEffects", 16|64);

	SetVariantString("!activator");
	AcceptEntityInput(iLink, "SetParent", iClient);

	SetVariantString("flag");
	AcceptEntityInput(iLink, "SetParentAttachment", iClient);

	return iLink;
}

stock bool IsValidBuilding(int iBuilding)
{
	if (IsValidEntity(iBuilding))
	{
		if (GetEntProp(iBuilding, Prop_Send, "m_bPlacing") == 0
		 && GetEntProp(iBuilding, Prop_Send, "m_bCarried") == 0
		 && GetEntProp(iBuilding, Prop_Send, "m_bCarryDeploy") == 0)
			return true;
	}

	return false;
}

stock bool IsBuilder(int iBuilding, int iClient)
{
	return (GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == iClient);
}
