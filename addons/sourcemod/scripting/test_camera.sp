#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public void OnPluginStart()
{
    RegAdminCmd("camera", Cmd_Test, ADMFLAG_CHEATS);
}

public Action Cmd_Test(int client, int args)
{
    float pos[3], cameraAngles[3], angles[3], goalPos[3];
    char trackTargetName[64], cornerTargetName[64], output[128];

    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, angles);
    GetAngleVectors(angles, angles, NULL_VECTOR, NULL_VECTOR);

    // 목적 좌표
    ScaleVector(angles, 1500.0);
    AddVectors(pos, angles, goalPos);

    // lol
    GetClientEyeAngles(client, cameraAngles);
    GetClientEyeAngles(client, angles);
    NegateVector(angles);

    int camera = CreateEntityByName("point_viewcontrol"),
        corner = CreateEntityByName("path_corner");

    if(!IsValidEntity(camera))      return Plugin_Continue;

    // TODO: configurable
    static float time = 10.0;
    float distance = GetVectorDistance(pos, goalPos), totalDistance = 0.0;

    Format(cornerTargetName, sizeof(cornerTargetName), "corner_target_%i", corner);
    DispatchKeyValue(corner, "targetname", cornerTargetName);

    // TODO: 소수점 연산 정확도 고려
    int previousTrack = corner;
    while(totalDistance < distance)
    {
        int track = CreateEntityByName("path_corner");
        float tempGoalPos[3], dir[3];

        Format(trackTargetName, sizeof(trackTargetName), "track_target_%i", track);
        DispatchKeyValue(track, "targetname", trackTargetName);

        DispatchKeyValue(previousTrack, "target", trackTargetName);

        // 2 : Face this path_track's angles
        // DispatchKeyValue(track, "orientationtype", "2");
        DispatchSpawn(track);

        float remainDistance = distance - totalDistance;
        totalDistance += remainDistance > 180.0 ?
            180.0 : remainDistance;

        GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(dir, totalDistance);
        AddVectors(pos, dir, tempGoalPos);

        TeleportEntity(track, tempGoalPos, NULL_VECTOR, NULL_VECTOR);

        Format(output, sizeof(output), "OnUser1 !self:kill::%.1f:1",
            time + 0.1);
        SetVariantString(output);

        AcceptEntityInput(track, "AddOutput");
        AcceptEntityInput(track, "FireUser1");
    }

    DispatchSpawn(corner);
    TeleportEntity(corner, goalPos, angles, NULL_VECTOR);
    // TeleportEntity(track, goalPos, angles, NULL_VECTOR);

    Format(output, sizeof(output), "OnUser1 !self:kill::%.1f:1",
        time + 0.1);
    SetVariantString(output);

    AcceptEntityInput(corner, "AddOutput");
    AcceptEntityInput(corner, "FireUser1");
/*
    SetVariantString(output);
    AcceptEntityInput(track, "AddOutput");
    AcceptEntityInput(track, "FireUser1");

    AcceptEntityInput(track, "EnablePath", -1, -1, 0);
*/
    // 카메라
    // Format(targetName, sizeof(targetName), "track_target");

    // 플레이어가 대상인 경우
    // DispatchKeyValue(camera, "targetattachment", "head");

    DispatchKeyValue(camera, "target", cornerTargetName);
    DispatchKeyValue(camera, "moveto", cornerTargetName);

    FloatToString(time, output, sizeof(output));
    DispatchKeyValue(camera, "wait", output);

    static float speed = 0.0;
    FloatToString(speed, output, sizeof(output));
    DispatchKeyValue(camera, "speed", output);

    static float acceleration = 3000.0;
    FloatToString(acceleration, output, sizeof(output));
    DispatchKeyValue(camera, "acceleration", output);

    static float deceleration = 3000.0;
    FloatToString(deceleration, output, sizeof(output));
    DispatchKeyValue(camera, "deceleration", output);

    DispatchSpawn(camera);
    TeleportEntity(camera, pos, angles, NULL_VECTOR);

    Format(output, sizeof(output), "OnEndFollow !self:kill::0.1:1");
    SetVariantString(output);
    AcceptEntityInput(camera, "AddOutput");

    AcceptEntityInput(camera, "Enable", client, client, 0);

    return Plugin_Continue;
}
