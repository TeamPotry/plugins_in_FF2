#if defined _sprites_included
 #endinput
#endif
#define _sprites_included

// First, you meed #include sdktools before this.
/*
    영원히 지속하는 Sprite를 만들 수 있습니다.
    0.12초마다 갱신됩니다.
*/

enum
{
    Sprite_Name,
    Sprite_ModelIndex,
    Sprite_Size,
    Sprite_Brightness,
    Sprite_Time,
    Sprite_Timer,
    Sprite_Parent,

    Sprite_PosX,
    Sprite_PosY,
    Sprite_PosZ,

    SpriteItem_MaxCount
};

methodmap Sprite < ArrayList {
    public static Sprite Init(const char[] name, int modelIndex)
    {
        Sprite array = view_as<Sprite>(new ArrayList(128, SpriteItem_MaxCount));

        array.SetString(Sprite_Name, name);
        array.Set(Sprite_ModelIndex, modelIndex);

        array.Set(Sprite_Timer, view_as<Handle>(null));

        return array;
    }

    property int ModelIndex {
        public get() {
            return this.Get(Sprite_ModelIndex);
        }
    }

    property float Size {
        public get() {
            return this.Get(Sprite_Size);
        }
        public set(float size) {
            this.Set(Sprite_Size, size);
        }
    }

    property int Parent {
        public get() {
            return this.Get(Sprite_Parent);
        }
        public set(int entity) {
            this.Set(Sprite_Parent, entity);
        }
    }

    property int Brightness {
        public get() {
            return this.Get(Sprite_Brightness);
        }
        public set(int brightness) {
            this.Set(Sprite_Brightness, brightness);
        }
    }

    property float Time {
        public get() {
            return this.Get(Sprite_Time);
        }
        public set(float time) {
            this.Set(Sprite_Time, time);
        }
    }

    property Handle Timer {
        public get() {
            return this.Get(Sprite_Timer);
        }
    }

    public void GetPos(float pos[3])
    {
        pos[0] = this.Get(Sprite_PosX);
        pos[1] = this.Get(Sprite_PosY);
        pos[2] = this.Get(Sprite_PosZ);
    }

    public void SetPos(const float pos[3])
    {
         this.Set(Sprite_PosX, pos[0]);
         this.Set(Sprite_PosY, pos[1]);
         this.Set(Sprite_PosZ, pos[2]);
    }

    public void Fire(bool looping = false)
    {
        // NOTE: Recommend: size = 1.0, brightness = 255
        float entPos[3], pos[3];
        this.GetPos(pos);

        if(IsValidEntity(this.Parent)) {
            GetEntPropVector(this.Parent, Prop_Send, "m_vecOrigin", entPos);
            AddPosVectors(entPos, pos, pos);
            TE_SetupGlowSprite(pos, this.ModelIndex, 0.11, this.Size, this.Brightness);

            if(!looping && this.Timer == null) {
                CreateTimer(0.1, UpdateParentSprite, this, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }

        }
        else {
            TE_SetupGlowSprite(pos, this.ModelIndex, this.Time, this.Size, this.Brightness);
        }

        TE_SendToAll();
    }
}

public Action UpdateParentSprite(Handle timer, Sprite sprite)
{
    if(sprite.Time <= 0.0) {
        sprite.Set(Sprite_Timer, view_as<Handle>(null));
        return Plugin_Stop;
    }

    sprite.Time -= 0.1;
    sprite.Fire(true);

    return Plugin_Continue;
}

public void AddPosVectors(const float pos[3], const float pos2[3], float[] added)
{
    for(int loop = 0; loop < 3; loop++) {
        added[loop] = pos[loop] + pos2[loop];
    }
}
