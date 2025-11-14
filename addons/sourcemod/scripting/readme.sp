#include <sourcemod>

public void OnPluginStart()
{
    RegAdminCmd("readme", Cmd_Test, ADMFLAG_CHEATS);
}

public Action Cmd_Test(int client, int args)
{
    Address addr = GetEntityAddress(client);
    int value = LoadFromAddress(addr, NumberType_Int32);

    PrintToChat(client, "addr: %X, value: %X", addr, value);
    PrintToChat(client, "client: %d, userid: %d, serial: %d: ref: %X, bred: %X", client, GetClientUserId(client), GetClientSerial(client), EntIndexToEntRef(client), MakeCompatEntRef(EntIndexToEntRef(client)));

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    char classname[32];
    GetEntityClassname(weapon, classname, sizeof(classname));

    PrintToChat(client, "%s", classname);

    return Plugin_Continue;
}
// F1417928
// F1417928 (1111 0001 0100 0001 0111 1001 0010 1000)
// 8016B001 (1000 0000 0001 0110 1011 0000 0000 0001)
