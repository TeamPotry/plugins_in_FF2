#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2attributes>
#include <tutorial_text>

#include <sappper_work_for_human>

public Plugin myinfo=
{
	name="Sapper work for human.",
	author="Nopied",
	description="",
	version="0.0",
};

CustomCTFSapper c_hClientSapper[MAXPLAYERS+1] = null;

#define SAPPER_FLAG_INVULNERABLE (1<<0)
#define HINTTEXT_CONFIG_NAME "sapper_work_for_human.cfg"

public void OnMapStart()
{
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);
}

//////
//////

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 0; client <= MaxClients; client++)
	{
		if(c_hClientSapper[client] != null)
			c_hClientSapper[client] = c_hClientSapper[client].KillSapper();
	}

	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(c_hClientSapper[client] != null && !(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		c_hClientSapper[client] = c_hClientSapper[client].KillSapper();
}

public void OnClientDisconnect(int client)
{
	if(c_hClientSapper[client] != null)
		c_hClientSapper[client] = c_hClientSapper[client].KillSapper();
}

//////
//////

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &newWeapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		if(IsValidEntity(newWeapon) && IsSapperWeapon(newWeapon))
		{
			TTextEvent event = new TTextEvent();
			ArrayList arrays = new ArrayList();
			float pos[3];
			GetClientEyePosition(client, pos);
			arrays.PushString("4.0"); // TODO: Format

			TT_LoadMessageID(event, HINTTEXT_CONFIG_NAME, "sapper_you_can_do_it");

			// event.FollowEntity = newWeapon;
			event.SetPosition(pos);
			event.ChangeTextLanguage(HINTTEXT_CONFIG_NAME, "sapper_you_can_do_it", client, arrays);
			event.FireTutorialText(HINTTEXT_CONFIG_NAME, "sapper_you_can_do_it", client);
			delete arrays;
		}

		int target = -1;

		int currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(currentWeapon) && IsSapperWeapon(currentWeapon)
		&& IsValidClient((target = GetClientInSapperRange(client))))
		{
			bool cloaked = TF2_IsPlayerInCondition(client, TFCond_Cloaked) ? true : GetEntProp(client, Prop_Send, "m_bFeignDeathReady") ? true : false;

			if(buttons & IN_ATTACK && !cloaked
			&& !TF2_IsPlayerInCondition(client, TFCond_Dazed)
			&& TF2_GetClientTeam(target) != TF2_GetClientTeam(client))
			{
				TF2_RemoveWeaponSlot(client, 1);
				SwitchToOtherWeapon(client);
				c_hClientSapper[target] = CreateSapper(client, target);
				TF2_StunPlayer(target, 4.0, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
				TF2_AddCondition(target, TFCond_Sapped, 4.0, client);
			}
		}
	}

	return Plugin_Continue;
}

int GetClientInSapperRange(int client)
{
	float clientPos[3], clientAngles[3];
	float fwd[3], endPos[3];
	int endEntity = -1;

	GetClientEyePosition(client, clientPos);
	GetClientEyeAngles(client, clientAngles);

	GetAngleVectors(clientAngles, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 128.0);
	AddVectors(clientPos, fwd, endPos);

	// PrintToChat(client, "%.3f %.3f %.3f", endPos[0], endPos[1], endPos[2]);

	Handle traceRay = TR_TraceRayFilterEx(clientPos, endPos, MASK_SHOT, RayType_EndPoint, TracePlayer, client);
	if(TR_DidHit(traceRay))
	{
		endEntity = TR_GetEntityIndex(traceRay);
	}

	delete traceRay;

	return endEntity;
}

CustomCTFSapper CreateSapper(int client, int target, float lifeTime = 4.0, int flags = 0)
{
	CustomCTFSapper sapper = new CustomCTFSapper(client, target);
	// int validCheckInteger = -1;

	sapper.HP = 100;
	// sapper.PropIndex = IsValidEntity((validCheckInteger = CreateSapperProp(client, target)));
	// sapper.Type ?
	sapper.Flags = flags;
	sapper.LifeTime = lifeTime;

	// SDKHook(target, SDKHook_OnTakeDamage, SapperDamageCheck);

	return sapper;
}

/*
public Action SapperDamageCheck(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(IsValidClient(attacker) && IsValidEntity(weapon)) // NOTE: NOT WORKING
	{
		if(GetClientTeam(victim) == GetClientTeam(attacker) && !(c_hClientSapper[victim].Flags & SAPPER_FLAG_INVULNERABLE))
		{
			Address address = TF2Attrib_GetByName(weapon, "damage applies to sappers");
			if(address != Address_Null && TF2Attrib_GetValue(address) > 0.0)
			{
				c_hClientSapper[victim].HP -= RoundFloat(damage);

				if(c_hClientSapper[victim].HP <= 0)
				{
					TF2_RemoveCondition(victim, TFCond_Dazed);
					TF2_RemoveCondition(victim, TFCond_Sapped);
					c_hClientSapper[victim].KillSapper();
				}
			}
		}
		else if(GetClientTeam(victim) != GetClientTeam(attacker))
		{
			damage *= 0.7;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}
*/

void OnSapperEnd(CustomCTFSapper sapper)
{
	int client = sapper.GetValue(Sapper_Target);
	c_hClientSapper[client] = c_hClientSapper[client].KillSapper();

	// PrintToChatAll("성공적으로 새퍼를 제거하였음.");
}

// int CreateSapperProp(int bulider, int target) // TODO: Only prop.

/*
int CreateSapperProp(int bulider, int target) // TODO: 3.0
{
	int sapperProp = CreateEntityByName("obj_attachment_sapper");
	if(IsValidEntity(sapperProp))
	{
		float clientPos[3];
		GetClientEyePosition(target, clientPos);

		SetEntPropEnt(sapperProp, Prop_Send, "m_hOwnerEntity", bulider);
		SetEntPropEnt(sapperProp, Prop_Send, "m_hBuilder", bulider);
		SetEntPropEnt(sapperProp, Prop_Send, "m_hBuiltOnEntity", target);
		SetEntProp(sapperProp, Prop_Send, "m_bHasSapper", 1);

		DispatchSpawn(sapperProp);

		TeleportEntity(sapperProp, clientPos, NULL_VECTOR, NULL_VECTOR);
		return sapperProp;
	}

	return -1;
}
*/

public bool TracePlayer(int entity, int contentsMask, any data)
{
	if(entity == data)
	{
		return false;
	}

	return true;
}

bool IsSapperWeapon(int weapon)
{
	char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));

	if((StrEqual(classname, "tf_weapon_builder")
	&& (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 735 || GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 736))
	|| (StrContains(classname, "tf_weapon_sapper") != -1)
	)   return true;

	return false;
}

stock void SwitchToOtherWeapon(int client)
{
	int	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int ammo = GetAmmo(client, weapon);
	int clip = (IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);

	if (!(ammo == 0 && clip <= 0))
	{
	    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	else
	{
	    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
	}
}

stock int GetAmmo(int client, int weapon)
{
	if (IsValidEntity(weapon))
	{
	    int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1); // * 4;

	    if (iOffset < 0)
	    {
	        return -1;
	    }

	    return GetEntProp(client, Prop_Send, "m_iAmmo", _, iOffset);
	}

	return -1;
}
/*
stock int GetSlotAmmo(int client, int slot)
{
    if (!IsValidClient(client)) return -1;

    int weapon = GetPlayerWeaponSlot(client, slot);

    if (IsValidEntity(weapon))
    {
        int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1); // * 4;

        if (iOffset < 0)
        {
            return -1;
        }

        return GetEntProp(client, Prop_Send, "m_iAmmo", _, iOffset);
    }

    return -1;
}
*/

stock bool IsValidClient(int client)
{
    return (0 < client && client <= MaxClients && IsClientInGame(client));
}
