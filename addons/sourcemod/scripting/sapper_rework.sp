#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin myinfo=
{
	name="Sapper's Special ability",
	author="Nopied",
	description="",
	version="0.0",
};

enum SapperValueType
{
	Sapper_HP, // NOTE: 새퍼를 회복 하는 기능이 언젠가 나올까?
	Sapper_Owner,
	Sapper_Target,
	Sapper_PropIndex,
	Sapper_Type, // TODO: 절차주의 새퍼 기능 구현
	Sapper_Flags,
	Sapper_LifeTime
	Sapper_TimerHandle // This is Private. DO NOT TOUCH.

	SapperValue_Last // NOTE: Keep this at this position.
};

methodmap CustomCTFSapper < ArrayList {
	public CustomCTFSapper(int bulider, int target) {
		CustomCTFSapper array = view_as<CustomCTFSapper>(new ArrayList(4, view_as<int>(SapperValue_Last)));

		for(int loop = 0; loop < view_as<int>(SapperValue_Last); loop++)
		{
			array.Set(loop, null);
		}

		array.SetValue(Sapper_Owner, bulider);
		array.SetValue(Sapper_Target, target);

		return array;
	}

	public any GetValue(SapperValueType valueType)
	{
		return this.Get(view_as<int>(valueType));
	}

	public void SetValue(SapperValueType valueType, any value)
	{
		this.Set(view_as<int>(valueType), value);
	}


	property int HP {
		public get()
		{
			return this.GetValue(Sapper_HP);
		}

		public set(const int healthPoint)
		{
			this.SetValue(Sapper_HP, healthPoint);
		}
	}

	property int Owner {
		public get()
		{
			return this.GetValue(Sapper_Owner);
		}

		/*
		public set(const int ownerIndex)
		{
			this.SetValue(Sapper_Owner, ownerIndex);
		}
		*/
	}

	property int Target {
		public get()
		{
			return this.GetValue(Sapper_Target);
		}

		/*
		public set(const int targetIndex)
		{
			this.SetValue(Sapper_Target, ownerIndex);
		}
		*/
	}

	property int PropIndex {
		public get()
		{
			return this.GetValue(Sapper_PropIndex);
		}

		public set(const int propIndex)
		{
			this.SetValue(Sapper_PropIndex, propIndex);
		}
	}

	property int Type {
		public get()
		{
			return this.GetValue(Sapper_Type);
		}

		public set(const int type)
		{
			this.SetValue(Sapper_Type, type);
		}
	}

	property int Flags {
		public get()
		{
			return this.GetValue(Sapper_Flags);
		}

		public set(const int flags)
		{
			this.SetValue(Sapper_Flags, flags);
		}
	}

	property float LifeTime {
		public get()
		{
			return this.GetValue(Sapper_LifeTime) - GetGameTime();
		}

		public set(const float lifeTime)
		{
			if(this.GetValue(Sapper_TimerHandle) != null)
				KillTimer(this.GetValue(Sapper_TimerHandle));

			if(lifeTime > 0.0)
			{
				this.SetValue(Sapper_LifeTime, GetGameTime() + lifeTime);

				this.SetValue(Sapper_TimerHandle, CreateTimer(lifeTime, SapperTimeEnd, this, TIMER_FLAG_NO_MAPCHANGE));
			}
		}
	}
}

public Action SapperTimeEnd(Handle timer, any data)
{
	CustomCTFSapper sapper = view_as<CustomCTFSapper>(data);

	this.SetValue(Sapper_TimerHandle, null);
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

CustomCTFSapper c_hClientSapper[MAXPLAYERS+1] = null;

public void OnMapStart()
{
	HookEvent("teamplay_round_start", OnRoundStart);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 0; client <= MaxClients; client++)
	{
		if(c_hClientSapper[client] != null)
			delete c_hClientSapper[client];
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if(c_hClientSapper[client] != null)
		delete c_hClientSapper[client];
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &newWeapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int target = -1;
		int currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(currentWeapon) && IsSapperWeapon(currentWeapon)
		&& IsValidClient((target = GetClientInSapperRange(client))))
		{
			bool cloaked = TF2_IsPlayerInCondition(client, TFCond_Cloaked) ? true : GetEntProp(client, Prop_Send, "m_bFeignDeathReady") ? true : false;
			if(buttons & IN_ATTACK && !cloaked
			&& !TF2_IsPlayerInCondition(client, TFCond_Dazed))
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
	int validCheckInteger = -1;

	sapper.HP = 100;
	// sapper.PropIndex = IsValidEntity((validCheckInteger = CreateSapperProp(client, target)));
	// sapper.Type ?
	sapper.Flags = flags;
	sapper.LifeTime = 4.0;

	return sapper;
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
