#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

ConVar g_enabled;
ConVar g_spells_dropchance;
ConVar g_spells_rarechance;
ConVar g_spells_despawntime;

public void OnPluginStart() {
	g_enabled = CreateConVar("sm_spells_enabled", "1", "Enable plugin");
	g_spells_dropchance = CreateConVar("sm_spells_dropchance", "100.0", "Chance for players to drop spell after death", _, true, 0.0, true, 100.0);
	g_spells_rarechance = CreateConVar("sm_spells_rarechance", "0.0", "Chance for rare spell drops", _, true, 0.0, true, 100.0);
	// g_spells_despawntime = CreateConVar("sm_spells_despawntime", "30", "Time until spell disappears (in seconds)", _, true, 0.0);

	HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (CheckRoundState() != 1 || !GetConVarBool(g_enabled))
		return Plugin_Continue;
	if((event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER) > 0 )
		return Plugin_Continue;

	if (GetRandomFloat(0.0, 100.0) < GetConVarFloat(g_spells_dropchance)) {
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		int spell = CreateEntityByName("tf_spell_pickup")
		float playerPos[3];
		GetClientAbsOrigin(victim, playerPos);
		TeleportEntity(spell, playerPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(spell, "Tier", GetRandomFloat(0.0, 100.0) < GetConVarFloat(g_spells_rarechance) ? "1" : "0");
		DispatchKeyValue(spell, "AutoMaterialize", "0");
		DispatchSpawn(spell);

		char temp[128];
		Format(temp, sizeof(temp), "OnUser1 !self:kill::30:1");
		SetVariantString(temp);

		AcceptEntityInput(spell, "AddOutput");
		AcceptEntityInput(spell, "FireUser1");

		Format(temp, sizeof(temp), "OnPlayerTouch !self:kill::0.1:1");
		SetVariantString(temp);
		AcceptEntityInput(spell, "AddOutput");
	}

	return Plugin_Continue;
}

stock int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
}
