#include <sourcemod>
#include <sdktools>

public void OnEntityCreated(int entity, const char[] classname)
{
    PrintToChatAll("%d (%s)", entity, classname);
}
