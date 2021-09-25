#include <sourcemod>
#include <sdktools>

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles_u[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(IsFakeClient(client) || !IsPlayerAlive(client))                            return Plugin_Continue;

    static float m_flPreviousAngle[MAXPLAYERS+1], m_flPreviousPos[MAXPLAYERS+1][3];

    char inputText[64], model[PLATFORM_MAX_PATH];
    float pos[3], angles[3], eyeAngles[3], currentModelAngles[3];
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, eyeAngles);

    GetAngleVectors(eyeAngles, angles, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(angles, 5.0);
    angles[0] = 85.0;

    TR_TraceRayFilter(pos, angles, MASK_ALL, RayType_Infinite, TraceFilter_DoNotHitSelf, client);
    if(!TR_DidHit() || TR_GetEntityIndex() != 0)        return Plugin_Continue;

    TR_GetPlaneNormal(null, angles);
    LogMessage("normal: %.1f, %.1f, %.1f", angles[0], angles[1], angles[2]);
    float normalAngle = GetNormalAngle(angles);

    if(m_flPreviousPos[client][2] > pos[2])
        eyeAngles[0] = FloatAbs(normalAngle);
    else if(m_flPreviousPos[client][2] < pos[2])
        eyeAngles[0] = -FloatAbs(normalAngle);
    else if(!(GetEntityFlags(client) & FL_ONGROUND))
    {
        AcceptEntityInput(client, "ClearCustomModelRotation", client);
        AcceptEntityInput(client, "ClearCustomModelRotation", client);
        eyeAngles[0] = 0.0;
    }
    else
    {
        AcceptEntityInput(client, "ClearCustomModelRotation", client);
        AcceptEntityInput(client, "ClearCustomModelRotation", client);

        eyeAngles[0] = 0.0;
    }
/*
    if(eyeAngles[0] > 0.0)
        LogMessage("final normal angle: %.8f", eyeAngles[0]);
*/
    GetEntPropVector(client, Prop_Send, "m_angCustomModelRotation", currentModelAngles);
/*
    if(currentModelAngles[0] > 0.0)
        LogMessage("currentModelAngles[0]: %.8f", currentModelAngles[0]);
*/

    // TODO: SetCustomModelRotation가 가끔 반영이 안되는 것으로 추정됨
    if((eyeAngles[0] != m_flPreviousAngle[client] || (eyeAngles[0] == 0.0 && currentModelAngles[0] != 0.0)))
    {
        GetClientModel(client, model, sizeof(model));
        SetVariantString(model);
        AcceptEntityInput(client, "SetCustomModel", client);

        // SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
        // SetEntPropVector(client, Prop_Send, "m_angCustomModelRotation", eyeAngles);

        SetVariantBool(true);
        AcceptEntityInput(client, "SetCustomModelRotates", client);

        Format(inputText, sizeof(inputText), "%.1f %.1f %.1f", eyeAngles[0], eyeAngles[1], eyeAngles[2]);
        SetVariantString(inputText);
        AcceptEntityInput(client, "SetCustomModelRotation", client);
    }

    RequestFrame(ClassAniTimer, client);

    m_flPreviousAngle[client] = eyeAngles[0];
    for(int loop = 0; loop < 3; loop++)
        m_flPreviousPos[client][loop] = pos[loop];

    return Plugin_Continue;
}


public bool TraceFilter_DoNotHitSelf(int entity, int contentsMask, any data)
{
    return entity != data;
}

public void ClassAniTimer(int client)
{
	if(IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}

}

float GetNormalAngle(float normal[3])
{
    // NOTE:
    // Toward 1 (+): nagetive
    //          (-): positive
    // Toward 2 (+): nagetive
    //          (-): positive

    for(int loop = 0; loop < 2; loop++)
    {
        if(normal[loop] != 0.0)
            return RoundToNearest(RadToDeg(normal[loop])*10.0)*0.1;
    }

    return 0.0;
}
