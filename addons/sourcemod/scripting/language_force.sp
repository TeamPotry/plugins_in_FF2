#include <sourcemod>

public OnClientPostAdminCheck(int client)
{
    int languageId = GetClientLanguage(client);
    int enid = GetLanguageByCode("en");
    char languageCode[4];

    GetLanguageInfo(languageId, languageCode, sizeof(languageCode));
    if(!StrEqual("en", languageCode)
    && !StrEqual("ko", languageCode))
        SetClientLanguage(client, enid);
}
