#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
    AddNormalSoundHook(SoundHook);
}

public Action SoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
	  int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
	  char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    LogMessage("sample = [%s]", sample);
    LogMessage("soundEntry = [%s]", soundEntry);
}
