public OnPluginStart()
{
    HookUserMessage(view_as<UserMsg>(14), fn_Hook, true);
}

public Action fn_Hook(UserMsg msg_id, Handle bf, const players[], int playersNum, bool reliable, bool init)
{
    PrintToServer("playersNum: %d", playersNum);

    char strRest[256], strRestc[256];
    int curbyte;
    while(BfGetNumBytesLeft(bf))
    {
        curbyte = BfReadByte(bf);
        Format(strRest, sizeof(strRest), "%s%d", strRest, curbyte);
        Format(strRestc, sizeof(strRestc), "%s%c", strRestc, curbyte);
    }
    PrintToServer("USERMSGHOOK: %s ", strRest);
    PrintToServer("USERMSGHOOK: %s ", strRestc);
}
