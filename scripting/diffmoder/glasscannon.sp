ConVar  sv_first_aid_heal_amt;
ConVar  sv_health_station_heal_per_tick;


// bool    glassCannon = false;
float   first_aid_heal_default = 30.0;
float 	g_fHealth_station_heal_default = 1.0;


int 	defaultPlayerHealth = 600;
// bool 	bGlasscannonEnabled = false;

bool bGCEnabled=false;

/*
	Cycle Through players setting their max and current health to 1
	Enable Sethealth on player spawn
*/
void InitGlassCannon(bool on = true){

	on?EnableGlasscannon():DisableGlasscannon()
}
public void EnableGlasscannon(){

	for(int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		SetEntityHealth(client, 1);
		SetMaxHealth(client, 1);
	}	

	sv_first_aid_heal_amt.FloatValue 			= 0.0;
	sv_health_station_heal_per_tick.FloatValue 	= 0.0;	

	HookEvent("player_spawn", glasscannon_OnPlayerSpawn);
	bGCEnabled = true;
}
public void DisableGlasscannon(){

	if (!bGCEnabled)
		return;

	for(int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		SetMaxHealth(client, defaultPlayerHealth);
	}	

	sv_first_aid_heal_amt.FloatValue 			= first_aid_heal_default;
	sv_health_station_heal_per_tick.FloatValue 	= g_fHealth_station_heal_default;	
	
	UnhookEvent("player_spawn", glasscannon_OnPlayerSpawn);
	bGCEnabled = false;
}

public void SetMaxHealth(int entityref, int val){

	char functionBuffer[128];
	Format(functionBuffer, sizeof(functionBuffer), "SetMaxHealth(%i)", val);
	RunEntVScript(entityref, functionBuffer, g_iEnt_VscriptProxy);
}
public int GetMaxHealth(int entityref){
    return RunEntVScriptInt(entityref, "GetMaxHealth()", g_iEnt_VscriptProxy);
}


public Action glasscannon_OnPlayerSpawn(Handle event, char[] name, bool dontBroadcast){

	int clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	defaultPlayerHealth = GetMaxHealth(clientId);
	if (clientId != 0 && IsClientInGame(clientId) && IsPlayerAlive(clientId))
	{
		SetEntityHealth(clientId, 1);
		SetMaxHealth(clientId, 1);
	}
	return Plugin_Handled;
}