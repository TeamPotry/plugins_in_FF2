#if defined __sapper_work_for_human_included
	#endinput
#endif

#define __sapper_work_for_human_included

enum SapperValueType
{
	Sapper_HP, // NOTE: 새퍼를 회복 하는 기능이 언젠가 나올까?
	Sapper_Owner,
	Sapper_Target,
	Sapper_PropIndex,
	Sapper_Type, // TODO: 절차주의 새퍼 기능 구현
	Sapper_Flags,
	Sapper_LifeTime,
	Sapper_TimerHandle, // This is Private. DO NOT TOUCH.

	SapperValue_Last // NOTE: Keep this at this position.
};

methodmap CustomCTFSapper < ArrayList {
	public CustomCTFSapper(int bulider, int target) {
		CustomCTFSapper array = view_as<CustomCTFSapper>(new ArrayList(4, view_as<int>(SapperValue_Last)));

		for(int loop = 0; loop < view_as<int>(SapperValue_Last); loop++)
		{
			array.Set(loop, 0);
		}

		array.Set(view_as<int>(Sapper_Owner), bulider);
		array.Set(view_as<int>(Sapper_Target), target);

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
			if(this.GetValue(Sapper_TimerHandle) != 0)
				KillTimer(this.GetValue(Sapper_TimerHandle));

			if(lifeTime > 0.0)
			{
				this.SetValue(Sapper_LifeTime, GetGameTime() + lifeTime);

				this.SetValue(Sapper_TimerHandle, CreateTimer(lifeTime, SapperTimeEnd, this, TIMER_FLAG_NO_MAPCHANGE));
			}
		}
	}

    public CustomCTFSapper KillSapper() // @return: always return null.
    {
        Handle timerHandle = view_as<Handle>(this.GetValue(Sapper_TimerHandle));
        if(timerHandle != null)
            KillTimer(timerHandle);

        delete this;
        return null;
    }
}

public Action SapperTimeEnd(Handle timer, any data)
{
	CustomCTFSapper sapper = view_as<CustomCTFSapper>(data);

	sapper.SetValue(Sapper_TimerHandle, 0);

	OnSapperEnd(sapper);
}
