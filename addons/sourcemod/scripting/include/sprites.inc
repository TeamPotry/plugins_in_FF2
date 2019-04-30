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
            return this.Set(Sprite_Size, size);
        }
    }

    property int Brightness {
        public get() {
            return this.Get(Sprite_Brightness);
        }
        public set(int brightness) {
            return this.Set(Sprite_Brightness, brightness);
        }
    }

    property float Time {
        public get() {
            return this.Get(Sprite_Time);
        }
        public set(float time) {
            return this.Set(Sprite_Time, time);
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

    public void Fire()
    {
        // NOTE: Recommend: size = 1.0, brightness = 255
        float pos[3];
        this.GetPos(pos);
        TE_SetupGlowSprite(pos, this.ModelIndex, this.Time, this.Size, this.Brightness);
        TE_SendToAll();
    }
}