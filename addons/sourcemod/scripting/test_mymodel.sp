#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <studio_hdr>
#include <CBaseAnimatingOverlay>
#include <dhooks>

Handle g_hStudioFrameAdvance;
Handle g_hAllocateLayer;
Handle g_hResetSequence;

public void OnPluginStart()
{
    RegAdminCmd("mymodel", Cmd_Test, ADMFLAG_CHEATS);

    GameData gamedata = new GameData("potry");
    if (gamedata)
    {
        g_hStudioFrameAdvance = PrepSDKCall_StudioFrameAdvance(gamedata);
        g_hAllocateLayer = PrepSDKCall_AllocateLayer(gamedata);
        g_hResetSequence = PrepSDKCall_ResetSequence(gamedata);

        delete gamedata;
    }
    else
    {
        SetFailState("Could not find potry gamedata");
    }
}

public Action Cmd_Test(int client, int args)
{
    char model[PLATFORM_MAX_PATH], name[64];

    GetClientModel(client, model, PLATFORM_MAX_PATH);

    StudioHdr hdr = GetEntityStudioHdr(client);
    // StudioHdr(model);

    LogMessage("model: ''%s''", model);

    // View pose parameters
    for(int loop = 0; loop < hdr.numlocalposeparameters; loop++)
    {
        PoseParameter pose = hdr.GetPoseParameter(loop);

        pose.GetName(name, sizeof(name));

        LogMessage("[%i]: Pose Name: %s\n ㄴ flags: %d\n ㄴ start: %.1f\n ㄴ end: %.1f\n ㄴ loop: %.1f",
            loop, name, pose.flags, pose.start, pose.end, pose.loop);
    }

    for(int loop = 0; loop < hdr.numlocalanim; loop++)
    {
        Animation animation = hdr.GetAnimation(loop);

        animation.GetName(name, sizeof(name));

        LogMessage("[%i]: Animation Name: %s\n ㄴ flags: %d\n ㄴ animindex: %d\n ㄴ fps: %.1f",
            loop, name, animation.flags, animation.animindex, animation.fps);
    }

    for(int loop = 0; loop < hdr.numlocalseq; loop++)
    {
        Sequence sequence = hdr.GetSequence(loop);

        sequence.GetLabelName(name, sizeof(name));

        float paramindex[2], paramstart[2], paramend[2];
        sequence.get_paramindex(paramindex);
        sequence.get_paramstart(paramstart);
        sequence.get_paramend(paramend);

        LogMessage("[%i]: Sequence Name: %s\n ㄴ flags: %d\n ㄴ animindexindex: %d\n ㄴ paramindex: %.1f, %.1f\nㄴ paramstart: %.1f, %.1f\n ㄴ paramend: %.1f, %.1f",
            loop, name, sequence.flags, sequence.animindexindex, paramindex[0], paramindex[1], paramstart[0], paramstart[1], paramend[0], paramend[1]);
    }

    // SetEntProp(client, Prop_Send, "m_nSequence", 184);

    SetEntityRenderMode(client, RENDER_NONE);

    CBaseAnimatingOverlay overlay = CBaseAnimatingOverlay(client);

    for (int i = 0; i <= 12; i++)
    	SDKCall(g_hAllocateLayer, client, 0);

    SDKCall(g_hResetSequence, client, 184);

    for (int i = 0; i <= 12; i++)
    {
        CAnimationLayer layer = overlay.GetLayer(i);

        if(!(layer.IsActive()))
        	continue;

        LogMessage("CBaseAnimatingOverlay[%i]: m_fFlags: %d\n ㄴ m_bSequenceFinished: %d\n ㄴ m_bLooping: %d\n ㄴ m_nSequence: %d\n ㄴ m_flCycle: %.1f\n ㄴ m_flPrevCycle: %.1f\n ㄴ m_flWeight: %.1f\n ㄴ m_flPlaybackRate: %.1f\n ㄴ m_flBlendIn: %.1f\n ㄴ m_flBlendOut: %.1f\n ㄴ m_flLayerAnimtime: %.1f\n ㄴ m_flLayerFadeOuttime: %.1f\n ㄴ m_nActivity: %d\n ㄴ m_nPriority: %d\n ㄴ m_nOrder: %d",
            i, layer.Get(m_fFlags), layer.Get(m_bSequenceFinished), layer.Get(m_bLooping), layer.Get(m_nSequence), layer.Get(m_flCycle), layer.Get(m_flPrevCycle), layer.Get(m_flWeight), layer.Get(m_flPlaybackRate), layer.Get(m_flBlendIn), layer.Get(m_flBlendOut), layer.Get(m_flLayerAnimtime), layer.Get(m_flLayerFadeOuttime),
            layer.Get(m_nActivity), layer.Get(m_nPriority), layer.Get(m_nOrder));


        // layer.Set(m_flKillRate, 		0.0);
        // layer.Set(m_flKillDelay, 		50000000000.0);
    }

    SetEntityRenderMode(client, RENDER_NORMAL);
    SDKCall(g_hStudioFrameAdvance, client);

    return Plugin_Continue;
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
/*
int SDKCall_StudioFrameAdvance(int ent)
{
	if (g_hAllocateLayer)
		return SDKCall(g_hAllocateLayer, ent);

	return -1;
}
*/
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
