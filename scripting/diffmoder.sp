/*
*
*	01-22:Found bug: setting difficulty in console doesnt change difficulty, reverts to last used in GameDif
*
*
*	01-22:
*		add cooldown timer for switching to casual mode, after a casual mode switch has recently been made.
*			this is to prevent free respawn abuse by switching to casual mode then back to another.
*			change cooldown timer with g_cfg_casual_cooldown
*		add doublejump configuration for the lols
*		
*
*
*	09-21:
*		add timer to revert back to default mode after a time.
*		add crawlerhell mode.
*
*	05-04-22
*		Many bugfixes. Change shambler-to-crawler and shambler-to-runner methods to use ingame BecomeCrawler and BecomeShambler entity functions. This is achieved by using a vscript proxy.
*/


#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <string>
#include <dhooks>

#include "diffmoder/menus_voting.sp"
#include "diffmoder/zomb_handling.sp"
#include "diffmoder/consts.sp"

float	g_fRunner_chance_default;
float	g_fRunner_chance_max_default;
float	g_fCrawler_chance_default;
float	g_fRunner_kid_chance_default;

int 	sv_crawler_health_default;
float 	g_fSpawn_regen_target_default = 0.6;




bool    glassCannon = false;
float   first_aid_heal_default = 30.0;
float 	g_fHealth_station_heal_default = 1.0;

ConVar  sv_first_aid_heal_amt;
ConVar  sv_health_station_heal_per_tick;
ConVar  sv_spawn_regen_target;
ConVar  sv_challenge;

Handle 	g_hDiffMod_Timer;

GameMod	g_eGameMode;	//int
GameDif g_eGameDiff;

int 	g_eGameCFG[sizeof(sConfItem)];	//array of individual conf items enabled or not

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Mostten, Rogue Garlicbread|Thijs",
	description	= "Allow player to enable the change difficult and mod by ballot.",
	version		= "2.4.1",
	url			= "https://forums.alliedmods.net/showthread.php?t=301322"
}

public void OnPluginStart()
{
	AutoExecConfig();
	zombiespeeds_init();

	LoadTranslations("nmrih.diffmoder.phrases");

	//npc spawn rates
	ov_runner_chance 			= FindConVar("ov_runner_chance");
	ov_runner_kid_chance 		= FindConVar("ov_runner_kid_chance");
	sv_max_runner_chance 		= FindConVar("sv_max_runner_chance");
	sv_zombie_crawler_health 	= FindConVar("sv_zombie_crawler_health");
	g_fShambler_crawler_chance 	= FindConVar("sv_zombie_shambler_crawler_chance");

	//Get Defaults
	g_fRunner_chance_default 	 = ov_runner_chance.FloatValue;
	g_fRunner_chance_max_default = sv_max_runner_chance.FloatValue;
	g_fRunner_kid_chance_default = ov_runner_kid_chance.FloatValue;
	sv_crawler_health_default	 = sv_zombie_crawler_health.IntValue;
	g_fCrawler_chance_default 	 = g_fShambler_crawler_chance.FloatValue;

	sv_spawn_regen_target 			= FindConVar("sv_spawn_regen_target");
	g_fSpawn_regen_target_default 	= GetConVarFloat(sv_spawn_regen_target);

	sv_zombie_moan_freq		= FindConVar("sv_zombie_moan_freq");
	phys_pushscale 			= FindConVar("phys_pushscale");

	sv_realism 				= FindConVar("sv_realism");
	sv_difficulty 			= FindConVar("sv_difficulty");
	(mp_friendlyfire 		= FindConVar("mp_friendlyfire")).AddChangeHook(OnConVarChanged);
	sv_hardcore_survival 	= FindConVar("sv_hardcore_survival");


	//glass cannon related cvars and defaults
	sv_first_aid_heal_amt 	= FindConVar("sv_first_aid_heal_amt");
	first_aid_heal_default 	= GetConVarFloat(sv_first_aid_heal_amt);
	sv_health_station_heal_per_tick = FindConVar("sv_health_station_heal_per_tick");
	g_fHealth_station_heal_default 	= GetConVarFloat(sv_health_station_heal_per_tick);

	sv_challenge = FindConVar("sv_challenge");

	(g_cfg_doublejump 		= CreateConVar("g_cfg_doublejump_enabled", "0", "Double Jump: 0 - disabled, 1 - enabled", 0, true, 0.0, true, 1.0)).AddChangeHook(OnConVarChanged);
	(g_cfg_diffmoder 		= CreateConVar("diffmoder", "1", "Enable/Disable plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(OnConVarChanged);
	g_cfg_infinity 			= CreateConVar("diffmoder_infinity_default", "0", "0 Normal ammo/clip, 1 Infinite ammo, 2 Infinite clip.", 0, true, 0.0, true, 1.0);
	g_cfg_gamemode 			= CreateConVar("diffmoder_gamemode_default", "0", "0 No gamemod, 1 Runners, 2 - All kids, 3 - Crawlers", 0, true, 0.0, true, 3.0);
	g_cfg_friendly 			= CreateConVar("diffmoder_friendly_default", "0", "Friendly fire: 0 - off, 1 - on", 0, true, 0.0, true, 1.0);
	g_cfg_realism 			= CreateConVar("diffmoder_realism_default", "0", "Realism: 0 - off, 1 - on", 0, true, 0.0, true, 1.0);
	g_cfg_hardcore 			= CreateConVar("diffmoder_hardcore_default", "0", "Hardcore survival: 0 - off, 1 - on", 0, true, 0.0, true, 1.0);
	g_cfg_glasscannon 		= CreateConVar("diffmoder_glasscannon_default", "0", "0 - off, 1 on", 0, true, 0.0, true, 1.0);

	g_cfg_difficulty 		= CreateConVar("diffmoder_difficulty_default", "classic", "Difficulty: classic, casual, nightmare");
	g_cfg_casual_cooldown 	= CreateConVar("diffmoder_casual_cooldown", "300", "Casual switch refractory period. Locks untill cooldown finished");
	g_cfg_autodefault_timer = CreateConVar("diffmoder_autodefault_timer", "1200.0", "Time until diffmoder revert to default gamemode.");
	g_cfg_modeswitch_map	= CreateConVar("diffmoder_mapchange_default", "0", "0: off, 1: on. Change the diffmode to default after map change.");
	g_cfg_modeswitch_time	= CreateConVar("diffmoder_modeswitch_time", "0", "-1: Never allow - 0:Always allow >1 - Time after roundstart during which people are allowed to change game settings.");	//not implemented atm
	g_cfg_switch_cooldown	= CreateConVar("diffmoder_modeswitch_cooldown", "60", "Delay after a vote before another may be started again.");
	g_cfg_diffs_enabled		= CreateConVar("diffmoder_difficulties", "casual classic nightmare default", "Enabled difficulties, those not in this list cannot be selected.");
	g_cfg_mods_enabled		= CreateConVar("diffmoder_mods", "runner kid crawler default", "Enabled mods, those not in this list cannot be selected.");
	g_cfg_configs_enabled	= CreateConVar("diffmoder_configs", "realism hardcore doublejump glasscannon default", "Enabled configs, those not in this list cannot be selected.");


	//Init zombiespeeds
	g_zombie_speeds				= new ArrayList(1,GetMaxEntities());
	g_crawler_speed				= CreateConVar("sm_crawler_speed", "1.0", "Amount to scale crawlers' movement speed by. E.g. 1.0 means move at normal speed.");
	g_crawler_speed_plusminus	= CreateConVar("sm_crawler_speed_plusminus", "0.05", "Set the range of random variation in crawlers' movement speed.");

	PrintToServer("Starting diffmoder..");
	g_bEnable 						= g_cfg_diffmoder.BoolValue;


	GetEnabledDiffs();
	GetEnabledMods();
	GetEnabledConfigs();
	
	//Register Commands
	RegConsoleCmd("sm_dif", Cmd_MenuTop);
	RegConsoleCmd("sm_difshow", Cmd_InfoShow);

	//Events
	HookEvent("nmrih_round_begin", Event_RoundBegin);
	HookEvent("nmrih_reset_map", Event_Reset_Map);
	HookEvent("player_spawn", Event_Spawn);
	//setup vscript proxy
	if (g_bEnable && g_iEnt_VscriptProxy == -1)
        SetupVscriptProxy();

	if (g_hDiffMod_Timer != INVALID_HANDLE){
		delete g_hDiffMod_Timer;
		g_hDiffMod_Timer = INVALID_HANDLE;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Diffmoder_GetMod", Native_GetMod);
	CreateNative("Diffmoder_GetDif", Native_GetDif);
	CreateNative("Diffmoder_GetGameCFG", Native_GetGameCFG);
	return APLRes_Success;
}



/*
    Natives returning current diffmoder status
    Useful for stat plugins
*/
public int Native_GetMod(Handle Plugin, int numParams)
{
    return view_as<int>(Game_GetMod());	//Cannot return custom types, cast into int
}
public int Native_GetDif(Handle Plugin, int numParams)
{
    return view_as<int>(Game_GetDif());
}
public int Native_GetGameCFG(Handle Plugin, int numParams)
{
	int item = GetNativeCell(1);
	return view_as<int>(Game_GetCFG(item));
}


public void Event_Reset_Map(Event event, const char[] name, bool dontBroadcast){
    //re-create a VscriptProxy entity as it is deleted on map reset
    if(g_bEnable)
        SetupVscriptProxy();
}

public void OnMapStart(){
	if (g_cfg_modeswitch_map.IntValue)	//revert to default mode 
		GameMod_Init();
    
	//add mutator stuff here
	if(g_bEnable)	//create VscriptProxy
        SetupVscriptProxy();
}


public void OnConVarChanged(ConVar CVar, const char[] oldValue, const char[] newValue)
{

	if(CVar == g_cfg_diffmoder)	
	{
		g_bEnable = StringToInt(newValue) > 0;
		if(g_bEnable) HookEvent("nmrih_round_begin", Event_RoundBegin);
		else UnhookEvent("nmrih_round_begin", Event_RoundBegin);
	}
	else if (CVar == mp_friendlyfire)
	{
		g_eGameCFG[GameConf_Friendly] = mp_friendlyfire.IntValue;
	}
	else if (CVar == g_cfg_doublejump)
	{
		g_eGameCFG[GameConf_DoubleJump] = g_cfg_doublejump.IntValue;
	}
	
}


//-----------------------------------------
//--------auto_difficulty_default----------
//automatically revert difficulty and mod to default
//when server has been empty for 30 minutes
public void OnClientDisconnect_Post()
{
	int playercount = GetClientCount();

	#if defined DEBUG
	Format(buff, 256, "Found %d", playercount);
	PrintToServer(buff);
	#endif
	if ( playercount < 1 && g_hDiffMod_Timer == INVALID_HANDLE ){
		PrintToServer("Going to sleep, bye!");
		g_hDiffMod_Timer = CreateTimer( g_cfg_autodefault_timer.FloatValue, Timertest );
	}
}

public Action Timertest(Handle timer)
{
	#if defined DEBUG
	PrintToServer("Auto Difficulty Timer completed");
	#endif
	int playercount = GetClientCount();
	if ( playercount > 0 )
	{
		PrintToServer("auto_difficulty_default_timer fired but people are on the server; returning without setting default inits");	
		g_hDiffMod_Timer = INVALID_HANDLE;
		return Plugin_Continue;
	}
	else
	{
		GameMod_Init();
		g_hDiffMod_Timer = INVALID_HANDLE;
		return Plugin_Continue;
	}
}
	

//player_join_game event instead of OnClientConnected as clients may 
//disconnect before actually joining the game.
public void OnClientConnected()
{
	if( g_hDiffMod_Timer != INVALID_HANDLE ){	//stop timer
		delete g_hDiffMod_Timer;				
		g_hDiffMod_Timer = INVALID_HANDLE;
	}
}
//-----------------------------------------
///////////////////////////////////////////



void GameMod_Init(){
	GameMod_Enable(view_as<GameMod>(g_cfg_gamemode.IntValue));
	GameDiff_Enable(view_as<GameDif>(g_cfg_difficulty.IntValue));
	GameConfig_Def();
}

public void OnPluginEnd(){
	GameMod_Init();
	delete g_hDiffMod_Timer;
	g_hDiffMod_Timer = INVALID_HANDLE;
}


public void OnEntityCreated(int entity, const char[] classname)
{
	// PrintToServer("Gamemod: %d, %s", view_as<int>(Game_GetMod()), sModItem[view_as<int>(Game_GetMod())]);
	// if(!g_bEnable || !( entity > MaxClients) || Game_GetMod() == GameMod_NoMod || !IsValidShamblerzombie(entity) ) 
	// {
	// 	// PrintToServer("Skipping sdkhook spawnpost..");
	// 	return;
	// }

	if(!g_bEnable ||  entity <= MaxClients || Game_GetMod() == GameMod_NoMod || !IsValidShamblerzombie(entity)) 
	{
		return;
	}

	SDKHook(entity, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
}


//why is this here? not needed..
public void OnEntityDestroyed(int entity){
	if(g_bEnable && IsValidShamblerzombie(entity)) SDKUnhook(entity, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
}





public void Event_RoundBegin(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable) GameInfo_ShowToAll();
	else UnhookEvent("nmrih_round_begin", Event_RoundBegin);
}

void GameConfig_Enable(GameConf conf, bool on = true)
{
	g_eGameCFG[conf] = on?1:0;
	switch(conf)
	{
		case GameConf_Realism:		sv_realism.BoolValue = on;
		case GameConf_Friendly:		mp_friendlyfire.BoolValue = on;
		case GameConf_Hardcore:		sv_hardcore_survival.BoolValue = on;
		case GameConf_Infinity: 	ServerCommand("sm_inf_ammo %d", (on?1:0) );
		case GameConf_DoubleJump: 	g_cfg_doublejump.IntValue = on;
		case GameConf_GlassCannon:	InitGlassCannon(on);
		case GameConf_Challenge:	sv_challenge.BoolValue = on;
		case GameConf_Default:		GameConfig_Def();
	}
}

void GameConfig_Def()
{
	GameConfig_Enable(GameConf_Realism, g_cfg_realism.IntValue?true:false);
	GameConfig_Enable(GameConf_Hardcore, g_cfg_hardcore.IntValue?true:false);
	GameConfig_Enable(GameConf_Infinity, g_cfg_infinity.IntValue?true:false);
	GameConfig_Enable(GameConf_Friendly, g_cfg_friendly.IntValue?true:false);
	GameConfig_Enable(GameConf_DoubleJump, g_cfg_doublejump.IntValue?true:false); //sets double jump twice but eh whatever and i want to save the config
	GameConfig_Enable(GameConf_GlassCannon, g_cfg_glasscannon.IntValue?true:false);
}


int defaultPlayerHealth;

/*
	Cycle Through players setting their max and current health to 1
	Enable Sethealth on player spawn
*/
void InitGlassCannon(bool on = true)
{
	glassCannon = on;
	FixGlassCannonHealths();
}

void FixGlassCannonHealths()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (glassCannon)
			{
				if (!defaultPlayerHealth)
					defaultPlayerHealth = GetMaxHealth(client);

				SetEntityHealth(client, 1);
				SetMaxHealth(client, 1);
				
			}
			else
				SetMaxHealth(client, defaultPlayerHealth);
		}
	}
	//ConVars
	if (glassCannon)
	{
		sv_first_aid_heal_amt.FloatValue 			= 0.0;
		sv_health_station_heal_per_tick.FloatValue 	= 0.0;
		sv_spawn_regen_target.FloatValue 			= 0.0;			
	}
	else
	{
		defaultPlayerHealth = 0;
		sv_first_aid_heal_amt.FloatValue 			= first_aid_heal_default;
		sv_health_station_heal_per_tick.FloatValue 	= g_fHealth_station_heal_default;
		sv_spawn_regen_target.FloatValue 			= g_fSpawn_regen_target_default;		
	}
}


void SetMaxHealth(int entityref, int val){
	char functionBuffer[128];
	Format(functionBuffer, sizeof(functionBuffer), "SetMaxHealth(%i)", val);
	RunEntVScript(entityref, functionBuffer, g_iEnt_VscriptProxy);
}
int GetMaxHealth(int entityref){
    return RunEntVScriptInt(entityref, "GetMaxHealth()", g_iEnt_VscriptProxy);
}


public Action Event_Spawn(Handle event, char[] name, bool dontBroadcast)
{
	if (!glassCannon)
		return Plugin_Continue;
		
	int clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	if (clientId != 0 && IsClientInGame(clientId) && IsPlayerAlive(clientId))
	{
		SetEntityHealth(clientId, 1);
		SetMaxHealth(clientId, 1);
	}
	return Plugin_Handled;
}



void GameMod_Enable(GameMod mod)
{
	//save info
	g_eGameMode = mod;
	
	//set mode
	switch(g_eGameMode)
	{
		case GameMod_Runner:
		{
			sv_max_runner_chance.FloatValue = ov_runner_chance.FloatValue = 1.0;
			ov_runner_kid_chance.FloatValue = g_fRunner_kid_chance_default;
			sv_spawn_regen_target.FloatValue = 0.0;
			ConVarCrawler(false);
			Game_ShamblerToRunner(GameMod_Runner);
		}
		case GameMod_Kid:
		{
			ov_runner_chance.FloatValue 	= g_fRunner_chance_default;
			sv_max_runner_chance.FloatValue = g_fRunner_chance_max_default;
			ov_runner_kid_chance.FloatValue = 1.0;
			sv_spawn_regen_target.FloatValue = 0.0;
			ConVarCrawler(false);
			Game_ShamblerToRunner(GameMod_Kid);
		}
		case GameMod_Crawler: 
		{
			ConVarCrawler(true);
			sv_spawn_regen_target.FloatValue = g_fSpawn_regen_target_default;
		}
		case GameMod_NoMod:
		{
			ov_runner_chance.FloatValue 	= g_fRunner_chance_default;
			sv_max_runner_chance.FloatValue = g_fRunner_chance_max_default;
			ov_runner_kid_chance.FloatValue = g_fRunner_kid_chance_default;
			sv_spawn_regen_target.FloatValue = g_fSpawn_regen_target_default;
			ConVarCrawler(false);
		}
	}
}


void ConVarCrawler(bool on)
{
	if(on)
	{
		sv_max_runner_chance.FloatValue = 0.01;
		ov_runner_kid_chance.FloatValue = 0.2;
		phys_pushscale.IntValue = PUSHSCALE_ANKLE;
		g_crawler_speed.IntValue = CRAWLERSPEED;
		sv_zombie_crawler_health.IntValue = CRAWLERHEALTH_ANKLE;
		g_fShambler_crawler_chance.FloatValue = CRAWLERCHANCE;		
		sv_zombie_moan_freq.IntValue=3;
	}
	else
	{
		phys_pushscale.IntValue=1;
		sv_zombie_moan_freq.IntValue=1;
		g_crawler_speed.IntValue=1;
		sv_zombie_crawler_health.IntValue = sv_crawler_health_default;
		g_fShambler_crawler_chance.FloatValue = g_fCrawler_chance_default;
	}
}


void GameDiff_Enable(GameDif dif)
{	
	if (!g_eGameDiff)	//if default gamemod, save def gamemod's value instead of 0
		g_eGameDiff = view_as<GameDif>(g_cfg_difficulty.IntValue);
	else	
		g_eGameDiff = dif;
	switch(dif)
	{
		case GameDif_Classic:	{sv_difficulty.SetString("classic");}
		case GameDif_Casual:	{sv_difficulty.SetString("casual");}
		case GameDif_Nightmare: {sv_difficulty.SetString("nightmare");}
		case GameDif_Default:	
		{
			char buff[128];
			g_cfg_difficulty.GetString(buff, sizeof(buff));
			sv_difficulty.SetString(buff);
		}
	}
}

GameMod Game_GetMod(){
	return g_eGameMode;
}

GameDif Game_GetDif(){
	return g_eGameDiff;
}

int Game_GetCFG(int index){
	if ( index < 0 || index>=sizeof(sConfItem) )
		return -1;
	return g_eGameCFG[index];
}

public Action Cmd_InfoShow(int client, int args)
{
	if(!g_bEnable) PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "ModDisable", client);
	else GameInfo_ShowToClient(client);

	return Plugin_Handled;
}