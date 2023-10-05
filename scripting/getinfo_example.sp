
#include "diffmoder"

public void OnPluginStart()
{
    RegServerCmd("sm_InfoMod", aInfoMod, "info print mod");
    RegServerCmd("sm_InfoDif", aInfoDif, "info print dif");
    RegServerCmd("sm_InfoCFG", aInfoCFG, "info print cfg");
}

public Action aInfoMod(int args)
{
    PrintToServer("Mod setting: %d", Diffmoder_GetMod());
    return Plugin_Handled;
}
public Action aInfoDif(int args)
{
    PrintToServer("Dif setting: %d", Diffmoder_GetDif());
    return Plugin_Handled;
}
public Action aInfoCFG(int args)
{
    char arg[4];
    GetCmdArg(1, arg, sizeof(arg));
    
    int item = StringToInt(arg)
    int enabled = Diffmoder_GetGameCFG( view_as<GameConf>(item) )

    if (enabled==1)
        PrintToServer("Cfg setting: %d is enabled", view_as<int>(item));
    else if(enabled==-1)
        PrintToServer("Cfg setting: %d is invalid", view_as<int>(item));
    else 
        PrintToServer("Cfg setting: %d is disabled", view_as<int>(item));
    return Plugin_Handled;
}
