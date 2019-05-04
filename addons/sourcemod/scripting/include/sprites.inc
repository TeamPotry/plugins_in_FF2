#if defined _sprites_included
 #endinput
#endif
#define _sprites_included

// First, you meed #include sdktools before this.
/*
    영원히 지속하는 Sprite를 만들 수 있습니다.
    0.12초마다 갱신됩니다.
*/

methodmap Sprite {
    public static Sprite Init(const char[] model, int parent, float scale, int brightness)
    {
        /*
            NOTE: Recommend: size = 1.0, brightness = 255

            @model .vmt
        */
        int entity = CreateEntityByName("env_sprite_oriented");
        float pos[3];

        DispatchKeyValue(entity, "spawnflags", "1");
        DispatchKeyValue(entity, "classname", "env_sprite_oriented");
        DispatchKeyValue(entity, "scale", "0.1"); // ?
        DispatchKeyValue(entity, "model", model);
        DispatchKeyValue(entity, "rendermode", "1");
        DispatchKeyValue(entity, "rendercolor", "255 255 255");
        DispatchKeyValue(entity, "framerate", "5");
        DispatchKeyValue(entity, "targetname", "sprite_temp");

        if(IsValidEntity(parent))
        {
            SetVariantString("!activator");
            AcceptEntityInput(entity, "SetParent", parent);

            GetEntPropVector(parent, Prop_Send, "m_vecOrigin", pos);
            TeleportEntity(parent, pos, NULL_VECTOR, NULL_VECTOR);
        }

        DispatchSpawn(entity);

        SetVariantFloat(scale);
        AcceptEntityInput(entity, "SetScale");

        SetEntProp(entity, Prop_Send, "m_nBrightness", brightness);

        return view_as<Sprite>(entity);
    }

    property float Size {
        public get() {
            return GetEntPropFloat(view_as<int>(this), Prop_Send, "m_flSpriteScale");
        }
        public set(float size) {
            SetVariantFloat(size);
            AcceptEntityInput(view_as<int>(this), "SetScale");
        }
    }

    property int Brightness {
        public get() {
            return GetEntProp(view_as<int>(this), Prop_Send, "m_nBrightness");
        }
        public set(int brightness) {
            SetEntProp(view_as<int>(this), Prop_Send, "m_nBrightness", brightness);
        }
    }

    public void GetPos(float pos[3])
    {
        GetEntPropVector(view_as<int>(this), Prop_Send, "m_vecOrigin", pos);
    }

    public void SetPos(const float pos[3])
    {
        TeleportEntity(view_as<int>(this), pos, NULL_VECTOR, NULL_VECTOR);
    }

    public void Show()
    {
        AcceptEntityInput(view_as<int>(this), "ShowSprite");
        AcceptEntityInput(view_as<int>(this), "ToggleSprite");
    }

    public void Hide()
    {
        AcceptEntityInput(view_as<int>(this), "HideSprite");
    }

    public void Kill()
    {
        AcceptEntityInput(view_as<int>(this), "Kill");
    }
}
/*
methodmap PlayerSprites < ArrayList {
    public static PlayerSprites Init(int client, int maxsize)
    {
        PlayerSprites array = view_as<PlayerSprites>(new ArrayList(64, maxsize + 1));

        for(int loop = 0; loop < maxsize + 1; loop++)
        {
            if(loop == maxsize)
                array.Set(loop, client);
            else
                array.Set(loop, view_as<PlayerSprites>(null));
        }
        return array;
    }

    property int Owner {
        public get() {
            return this.Get(this.Length - 1);
        }
    }

    public void Start()
    {
        this.Set(Sprite_Timer, CreateTimer(0.1, SpriteUpdateTimer, this, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE));
    }

    // NOTE: MUST USE THIS FUNCTION FOR STOP TIMER BEFORE DELETE THIS.
    public void Stop()
    {
        Handle timer = this.Get(Sprite_Timer);
        if(timer != null)
            KillTimer(timer);
    }
}

public Action PlayerSpriteUpdateTimer(Handle timer, Sprite sprite) {

}
*/
