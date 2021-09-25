#include <sourcemod>

Handle timer, timer2;
public void OnPluginStart()
{
    timer = CreateTimer(60.0, PrintHello);
    timer2 = CreateTimer(60.0, PrintHello);

    delete timer2;
}

public Action PrintHello(Handle timer)
{
    LogMessage("Hello World!");
}
