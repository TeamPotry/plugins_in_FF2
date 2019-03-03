#if defined _aimbot_included
 #endinput
#endif
#define _aimbot_included

enum AimBotType
{
    Aim_AimType = 0,
    Aim_AutoShoot,
    Aim_MedicPriority,
    Aim_SlientAim,
    Aim_BunnyHop,
    Aim_OnlyHeadshots,
    Aim_AutoBackstab,
    Aim_ForceFOV
};

native int AimBot_GetState(int client, AimBotType type);

native void AimBot_SetState(int client, AimBotType type, int value);
