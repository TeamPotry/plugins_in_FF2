#include <sdktools>
#include <sdkhooks>
#include <CBaseAnimatingOverlay>
#include <dhooks>

Handle g_hMyNextBotPointer;
Handle g_hGetLocomotionInterface;
Handle g_hGetStepHeight;
Handle g_hStudioFrameAdvance;
Handle g_hAllocateLayer;
Handle g_hResetSequence;

public void OnPluginStart()
{
    RegAdminCmd("npc", Cmd_Test, ADMFLAG_CHEATS);

    GameData gamedata = new GameData("potry");
    if (gamedata)
    {
        // g_hMyNextBotPointer = PrepSDKCall_MyNextBotPointer(gamedata);
        // g_hGetLocomotionInterface = PrepSDKCall_GetLocomotionInterface(gamedata); // NOT WORKING ON LINUX
        g_hStudioFrameAdvance = PrepSDKCall_StudioFrameAdvance(gamedata);
        g_hAllocateLayer = PrepSDKCall_AllocateLayer(gamedata);
        g_hResetSequence = PrepSDKCall_ResetSequence(gamedata);

        // TODO: 리눅스 버전에서 직접 Hook 할 방법
        CreateDynamicDetour(gamedata, "CTFBaseBoss::GetCurrencyValue", DHookCallback_GetCurrencyValue_Pre);
        // CreateDynamicDetour(gamedata, "CTFBaseBossLocomotion::GetStepHeight", DHookCallback_GetStepHeight_Pre);
        // g_hGetStepHeight = SetupDynamicDetour(gamedata, "ILocomotion::GetStepHeight");
        // g_hGetStepHeight = DHookCreateEx(gamedata, "ILocomotion::GetStepHeight", HookType_Raw, ReturnType_Float, ThisPointer_Address, ILocomotion_GetStepHeight);

        delete gamedata;
    }
    else
    {
        SetFailState("Could not find potry gamedata");
    }
}
/*
static Handle SetupDynamicDetour(GameData gamedata, const char[] name)
{
	DHookSetup setup = DHookCreateFromConf(gamedata, name);
    // setup.SetFromConf(gamedata, SDKConf_Signature, name);
	if (setup)
        return view_as<Handle>(setup);

	LogError("Failed to create setup handle for %s", name);
    return null;
}
*/
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

public MRESReturn DHookCallback_GetCurrencyValue_Pre(int ent, DHookReturn ret)
{
    // PrintToChatAll("%.1f", ret.Value);
    ret.Value = 0;
    return MRES_Supercede;
}

/* Does not work
public MRESReturn DHookCallback_GetStepHeight_Pre(Address pThis, DHookReturn ret)
{
    // PrintToChatAll("%.1f", ret.Value);
    ret.Value = 100.0;
    return MRES_Supercede;
}
*/


// https://github.com/Pelipoika/TF2_NextBot/blob/master/npc_playerclone.sp
public Action Cmd_Test(int client, int args)
{
    float pos[3];
    {
        float eyePos[3], eyeAngles[3];
        GetClientEyePosition(client, eyePos);
        GetClientEyeAngles(client, eyeAngles);

        GetAngleVectors(eyeAngles, eyeAngles, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(eyeAngles, 100.0);
        AddVectors(eyePos, eyeAngles, pos);
    }

    float ang[3]; GetClientAbsAngles(client, ang);
    float zeroVector[3], vecMins[3], vecMaxs[3];

    GetEntPropVector(client, Prop_Data, "m_vecMins", vecMins);
    GetEntPropVector(client, Prop_Data, "m_vecMaxs", vecMaxs);

    char strModel[PLATFORM_MAX_PATH];
    GetEntPropString(client, Prop_Data, "m_ModelName", strModel, PLATFORM_MAX_PATH);

    int npc = CreateEntityByName("base_boss");
    // DispatchKeyValueVector(npc, "origin", pos);
    // DispatchKeyValueVector(npc, "angles", ang);
    DispatchKeyValue(npc, "model", strModel);
    DispatchKeyValue(npc, "modelscale", "1.0");
    DispatchKeyValue(npc, "speed", "0.0");
    DispatchKeyValue(npc, "health", "500");
    DispatchSpawn(npc);

    SetEntPropVector(npc, Prop_Data, "m_vecMins", vecMins);
    SetEntPropVector(npc, Prop_Data, "m_vecMaxs", vecMaxs);

    // FIXME: 중력이 계속 적용됨.
    // 별도의 특수한 MOVETYPE가 있는 것으로 추정
    TeleportEntity(npc, pos, ang, zeroVector);

    int item = CreateEntityByName("prop_dynamic");
    DispatchKeyValue(item, "model", strModel);
    DispatchSpawn(item);

    SetEntProp(item, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nSkin"));
    SetEntProp(item, Prop_Send, "m_hOwnerEntity", npc);
    SetEntProp(item, Prop_Send, "m_fEffects", (1 << 0)|(1 << 9));

    SetEntPropVector(item, Prop_Data, "m_vecMins", vecMins);
    SetEntPropVector(item, Prop_Data, "m_vecMaxs", vecMaxs);

    TeleportEntity(item, pos, ang, zeroVector);
    SetVariantString("!activator");
    AcceptEntityInput(item, "SetParent", npc);

    // AcceptEntityInput(npc, "SetParent", item);

    SetVariantString("head");
    AcceptEntityInput(item, "SetParentAttachmentMaintainOffset");

    SetEntityGravity(npc, 0.0);
    SetEntityMoveType(npc, MOVETYPE_NONE);
    SetEntityRenderMode(npc, RENDER_NONE);

    SetEntityGravity(item, 0.0);
    SetEntityMoveType(item, MOVETYPE_NONE);

    SetEntProp(npc, Prop_Data, "m_bloodColor", -1); //Don't bleed
    SetEntProp(npc, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nSkin")); //Don't bleed
    SetEntPropEnt(npc, Prop_Data, "m_hOwnerEntity", 0);
    SetEntData(npc, FindSendPropInfo("CTFBaseBoss", "m_lastHealthPercentage") + 28, false, 4, true); //ResolvePlayerCollisions
    SetEntProp(npc, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nSkin"));
    SetEntProp(npc, Prop_Send, "m_fEffects", (1 << 0)|(1 << 9));
    // SetEntProp(npc, Prop_Send, "m_CollisionGroup", 2);
    // SetEntProp(npc, Prop_Send, "m_usSolidFlags", 0x0004);

    // ActivateEntity(npc);

    // 애니메이션 값 복사

    //Allocate 15 layers for max copycat
    for (int i = 0; i <= 12; i++)
    	SDKCall(g_hAllocateLayer, npc, 0);

    SDKCall(g_hResetSequence, npc, GetEntProp(client, Prop_Send, "m_nSequence"));

    CBaseAnimatingOverlay overlayP = CBaseAnimatingOverlay(client);
    CBaseAnimatingOverlay overlay = CBaseAnimatingOverlay(npc);

    for (int i = 0; i <= 12; i++)
    {
        CAnimationLayer layerP = overlayP.GetLayer(i);
        CAnimationLayer layer = overlay.GetLayer(i);

        if(!(layerP.IsActive()))
        	continue;

        //PrintToServer("%i", i);

        layer.Set(m_fFlags, 			layerP.Get(m_fFlags));
        layer.Set(m_bSequenceFinished, 	layerP.Get(m_bSequenceFinished));
        layer.Set(m_bLooping,			layerP.Get(m_bLooping));
        layer.Set(m_nSequence,			layerP.Get(m_nSequence));
        layer.Set(m_flCycle,			layerP.Get(m_flCycle));
        layer.Set(m_flPrevCycle,		layerP.Get(m_flPrevCycle));
        // layer.Set(m_flWeight,			0.0);
        layer.Set(m_flWeight,			layerP.Get(m_flWeight));
        layer.Set(m_flPlaybackRate,		layerP.Get(m_flPlaybackRate));
        layer.Set(m_flBlendIn,			layerP.Get(m_flBlendIn));
        layer.Set(m_flBlendOut,			layerP.Get(m_flBlendOut));
        layer.Set(m_flKillRate, 		0.0);
        layer.Set(m_flKillDelay, 		50000000000.0);
        layer.Set(m_flLayerAnimtime, 	layerP.Get(m_flLayerAnimtime));
        layer.Set(m_flLayerFadeOuttime, layerP.Get(m_flLayerFadeOuttime));
        layer.Set(m_nActivity,			layerP.Get(m_nActivity));
        layer.Set(m_nPriority,			layerP.Get(m_nPriority));
        layer.Set(m_nOrder, 			layerP.Get(m_nOrder));
    }

    for (int i = 0; i < 24; i++)
    {
    	float flValue = GetEntPropFloat(client, Prop_Send, "m_flPoseParameter", i);
    	SetEntPropFloat(npc, Prop_Send, "m_flPoseParameter", flValue, i);
    }

    //Done
    SetEntityRenderMode(npc, RENDER_NORMAL);

    //Play anims a bit so they get played to their set values
    SDKCall(g_hStudioFrameAdvance, npc);

    // PrintToChatAll("Spawned %d", npc);
}

Handle PrepSDKCall_MyNextBotPointer(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::MyNextBotPointer");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDK call: CBaseEntity::MyNextBotPointer");

	return call;
}

int SDKCall_MyNextBotPointer(int ent)
{
    if(g_hMyNextBotPointer)
        SDKCall(g_hMyNextBotPointer, ent);

    return -1;
}

Handle PrepSDKCall_GetLocomotionInterface(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "INextBot::GetLocomotionInterface");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDK call: INextBot::GetLocomotionInterface");

	return call;
}

any SDKCall_GetLocomotionInterface(int address)
{
    if(g_hGetLocomotionInterface)
        SDKCall(g_hGetLocomotionInterface, address);

    return -1;
}

Handle PrepSDKCall_StudioFrameAdvance(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseAnimating::StudioFrameAdvance");

	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDK call: CBaseAnimating::StudioFrameAdvance");

	return call;
}

int SDKCall_StudioFrameAdvance(int ent)
{
	if (g_hAllocateLayer)
		return SDKCall(g_hAllocateLayer, ent);

	return -1;
}

Handle PrepSDKCall_AllocateLayer(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseAnimatingOverlay::AllocateLayer");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	//priority
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); //return iOpenLayer

	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDK call: CBaseAnimatingOverlay::AllocateLayer");

	return call;
}

int SDKCall_AllocateLayer(int ent, int priority)
{
	if (g_hAllocateLayer)
		return SDKCall(g_hAllocateLayer, ent, priority);

	return -1;
}

Handle PrepSDKCall_ResetSequence(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseAnimating::ResetSequence");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // nSequence

	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDK call: CBaseAnimating::ResetSequence");

	return call;
}

int SDKCall_ResetSequence(int ent, int nSequence)
{
	if (g_hResetSequence)
		return SDKCall(g_hResetSequence, ent, nSequence);

	return -1;
}
