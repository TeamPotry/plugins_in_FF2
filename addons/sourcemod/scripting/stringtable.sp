#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
    RegAdminCmd("table", Cmd_Test, ADMFLAG_CHEATS);
}

public Action Cmd_Test(int client, int args)
{
    PrintToChat(client, "modelprecache: %d", GetModelTableNumStrings());
}

int GetModelTableNumStrings()
{
	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("modelprecache");

    return GetStringTableNumStrings(table);
}
