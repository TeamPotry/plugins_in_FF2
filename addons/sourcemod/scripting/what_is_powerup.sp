#include <sourcemod>
#include <sdktools>

public void OnEntityCreated(int entity, const char[] classname)
{
    if(StrEqual(classname, "item_powerup_rune"))
    {
        AcceptEntityInput(entity, "Kill");
    }
}
