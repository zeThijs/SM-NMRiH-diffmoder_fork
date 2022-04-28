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

//#include "diffmoder/consts.sp"
#include "diffmoder/menus_voting.sp"
#include "diffmoder/zomb_handling.sp"
#include "diffmoder/consts.sp"
float	g_fCrawler_chance_default;

int sv_zombie_crawler_health_default;
//int	phys_pushscale_default;


int speedflag[4]={0,0,0,0};
enum speedflag_enum{
	shambler,
	crawler,
	runner,
	kid
};

Handle g_hDiffMod_Timer;

GameMod g_eGameMode;	//int
GameDif g_eGamediff;	

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Mostten, Rogue Garlicbread",
	description	= "Allow player to enable the change difficult and mod by ballot.",
	version		= "2.3",
	url			= "https://forums.alliedmods.net/showthread.php?t=301322"
}

public void OnPluginStart()
{

	zombiespeeds_init();

	LoadTranslations("nmrih.diffmoder.phrases");

	(sv_max_runner_chance = FindConVar("sv_max_runner_chance")).AddChangeHook(OnConVarChanged);
//	g_fMax_runner_chance_default = sv_max_runner_chance.FloatValue;
	(ov_runner_chance = FindConVar("ov_runner_chance")).AddChangeHook(OnConVarChanged);
	(ov_runner_kid_chance = FindConVar("ov_runner_kid_chance")).AddChangeHook(OnConVarChanged);
//	g_fRunner_kid_chance_default = ov_runner_kid_chance.FloatValue;
	(sv_zombie_shambler_crawler_chance = FindConVar("sv_zombie_shambler_crawler_chance")).AddChangeHook(OnConVarChanged);
	g_fCrawler_chance_default = sv_zombie_shambler_crawler_chance.FloatValue;
	(sv_zombie_crawler_health = FindConVar("sv_zombie_crawler_health")).AddChangeHook(OnConVarChanged);
	sv_zombie_crawler_health_default=sv_zombie_crawler_health.IntValue;
	(phys_pushscale = FindConVar("phys_pushscale")).AddChangeHook(OnConVarChanged);
	//phys_pushscale_default = phys_pushscale.IntValue;
	(sv_spawn_density = FindConVar("sv_spawn_density")).AddChangeHook(OnConVarChanged);
	(sv_zombie_moan_freq = FindConVar("sv_zombie_moan_freq")).AddChangeHook(OnConVarChanged);


	(sv_realism = FindConVar("sv_realism")).AddChangeHook(OnConVarChanged);
	(mp_friendlyfire = FindConVar("mp_friendlyfire")).AddChangeHook(OnConVarChanged);
	(sv_hardcore_survival = FindConVar("sv_hardcore_survival")).AddChangeHook(OnConVarChanged);
	(sv_difficulty = FindConVar("sv_difficulty")).AddChangeHook(OnConVarChanged);
	
	(g_cfg_diffmoder = CreateConVar("nmrih_diffmoder", "1", "Enable/Disable plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(OnConVarChanged);
	sv_current_diffmode = CreateConVar("sv_current_diffmode", "0", "Current diffmode.");
	g_bEnable = g_cfg_diffmoder.BoolValue;
	g_cfg_infinity = CreateConVar("nmrih_diffmoder_infinity_default", "0", "0 - Normal ammo/clip, 1 - Infinite ammo, 2 -  Infinite clip.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cfg_doublejump = CreateConVar("g_cfg_doublejump_enabled.IntValue", "0", "Double Jump: 0 - disabled, 1 - enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cfg_gamemode = CreateConVar("nmrih_diffmoder_gamemode_default", "0", "0 - default gamemode, 1 - All runners, 2 - All kids, 3 - Crawlers", 0, true, 0.0, true, 2.0);
	g_cfg_friendly = CreateConVar("nmrih_diffmoder_friendly_default", "0", "Friendly fire: 0 - off, 1 - on", 0, true, 0.0, true, 1.0);
	g_cfg_realism = CreateConVar("nmrih_diffmoder_realism_default", "0", "Realism: 0 - off, 1 - on", 0, true, 0.0, true, 1.0);
	g_cfg_hardcore = CreateConVar("nmrih_diffmoder_hardcore_default", "0", "Hardcore survival: 0 - off, 1 - on", 0, true, 0.0, true, 1.0);
	g_cfg_difficulty = CreateConVar("nmrih_diffmoder_difficulty_default", "classic", "Difficulty: classic, casual, nightmare");
	g_cfg_casual_cooldown = CreateConVar("nmrih_diffmoder_casual_cooldown", "300", "Cooldown time after a casual switch, before a casual switch can be voted again.");
	g_cfg_autodefault_timer = CreateConVar("nmrih_autodefault_timer", "1200.0", "Time until difmoder revert to default gamemode.");
	AutoExecConfig();
	
	//Reg Cmd
	RegConsoleCmd("sm_dif", Cmd_MenuTop);
	RegConsoleCmd("sm_difshow", Cmd_InfoShow);

	//events
	HookEvent("nmrih_round_begin", Event_RoundBegin);
	HookEvent("nmrih_reset_map", Event_Reset_Map);
	//setup vscript proxy
    if(g_bEnable && g_iEnt_VscriptProxy == -1)
        SetupVscriptProxy();

	GameMod_Init();
	if (g_hDiffMod_Timer != INVALID_HANDLE){
		delete g_hDiffMod_Timer;
		g_hDiffMod_Timer = INVALID_HANDLE;
	}
}



public void Event_Reset_Map(Event event, const char[] name, bool dontBroadcast){
    //re-create a VscriptProxy entity as it is deleted on map reset
    if(g_bEnable)
        SetupVscriptProxy();
}
public void OnMapStart(){
    //create VscriptProxy
    if(g_bEnable)
        SetupVscriptProxy();
}


public void OnConVarChanged(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	GameMod mod = Game_GetMod();
	GameDif dif = Game_GetDif();
	
	if(CVar == sv_max_runner_chance)		GameMod_Enable(mod);
	else if(CVar == ov_runner_chance)		GameMod_Enable(mod);
	else if(CVar == ov_runner_kid_chance)	GameMod_Enable(mod);
	else if(CVar == sv_zombie_shambler_crawler_chance)	GameMod_Enable(mod);
	else if(CVar == sv_difficulty){
		
		GameDiff_Enable(dif);
	}
	else if(CVar == g_cfg_diffmoder)	
	{
		g_bEnable = StringToInt(newValue) > 0;
		if(g_bEnable) HookEvent("nmrih_round_begin", Event_RoundBegin);
		else UnhookEvent("nmrih_round_begin", Event_RoundBegin);
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
	PrintToServer("Auto Difficulty Timer completed");
	int playercount = GetClientCount();
	if ( playercount > 0 ){
		PrintToServer("auto_difficulty_default_timer fired but people are on the server; returning without setting default inits");	
		g_hDiffMod_Timer = INVALID_HANDLE;
		return;
	}
	ConVars_InitDefault();
	g_hDiffMod_Timer = INVALID_HANDLE;
}

//player_join_game event instead of OnClientConnected as clients may 
//disconnect before actually joining the game.
public void OnClientConnected()
{
	if( g_hDiffMod_Timer != INVALID_HANDLE ){
		delete g_hDiffMod_Timer;				//stop timer
		g_hDiffMod_Timer = INVALID_HANDLE;
		PrintToServer("Stopped auto_difficulty_default timer.");
	}
}
//-----------------------------------------
///////////////////////////////////////////



void GameMod_Init(){
	GameMod_Enable(GameMod_Default);
	GameDiff_Enable(GameDif_Default);
}

void ConVars_InitDefault(){
	GameMod_Def();
	GameDiff_Def();
	GameConfig_Def();
}

public void OnConfigsExecuted(){
	ConVars_InitDefault();
}

public void OnPluginEnd(){
	ConVars_InitDefault();
	delete g_hDiffMod_Timer;
	g_hDiffMod_Timer = INVALID_HANDLE;
}


public void OnEntityCreated(int entity, const char[] classname)
{
	if(!g_bEnable) return;

	if((entity > MaxClients) && IsValidEntity(entity)
	&& StrEqual(classname, "npc_nmrih_shamblerzombie", false)){
		SDKHook(entity, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
	}
}

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
	switch(conf)
	{
		case GameConf_Realism:		sv_realism.BoolValue = on;
		case GameConf_Friendly:		mp_friendlyfire.BoolValue = on;
		case GameConf_Hardcore:		sv_hardcore_survival.BoolValue = on;
		case GameConf_Infinity: 	ServerCommand("sm_inf_ammo %d", on);
		case GameConf_DoubleJump: 	ServerCommand("sm_doublejump_enabled %d", on);
		case GameConf_Default:		GameConfig_Def();
	}
}

void GameConfig_Def()
{
	sv_realism.BoolValue = g_cfg_realism.BoolValue;
	mp_friendlyfire.BoolValue = g_cfg_friendly.BoolValue;
	sv_hardcore_survival.BoolValue = g_cfg_hardcore.BoolValue;
	ServerCommand("sm_inf_ammo %d", g_cfg_infinity.IntValue);
	ServerCommand("sm_doublejump_enabled %d", g_cfg_doublejump.IntValue);
}

void GameMod_Enable(GameMod mod)
{
	SetConVarInt(sv_current_diffmode, (view_as<int>(mod)));
	g_eGameMode = mod;
	switch(mod)
	{
		case GameMod_Runner:
		{
			sv_max_runner_chance.FloatValue = ov_runner_chance.FloatValue = 1.0;
			ov_runner_kid_chance.FloatValue = 0.0;
			phys_pushscale.IntValue = 1;
		}
		case GameMod_Kid:
		{
			sv_max_runner_chance.FloatValue = ov_runner_chance.FloatValue = 0.0;
			ov_runner_kid_chance.FloatValue = 1.0;
			phys_pushscale.IntValue = 1;
		}
		case GameMod_AnkleBiters:
		{
			sv_max_runner_chance.FloatValue = 0.01;
			ov_runner_kid_chance.FloatValue = 0.2;
			sv_zombie_shambler_crawler_chance.FloatValue = CRAWLERCHANCE;

			g_cvar_crawler_speed.IntValue = CRAWLERSPEED;

			sv_zombie_crawler_health.IntValue = CRAWLERHEALTH_ANKLE;
			phys_pushscale.IntValue = PUSHSCALE_ANKLE;
			sv_spawn_density.FloatValue = SPAWNDENSITY_ANKLE;
		}
		case GameMod_Default: GameMod_Def();
	}
}

void GameMod_Def()
{	
	SetConVarInt(sv_current_diffmode, (view_as<int>(g_cfg_gamemode.IntValue)));
	g_eGameMode = view_as<GameMod>(g_cfg_gamemode.IntValue);
	switch(g_eGameMode)
	{
		case GameMod_Runner:{GameMod_Enable(GameMod_Runner);}
		case GameMod_Kid:{GameMod_Enable(GameMod_Kid);}
		case GameMod_AnkleBiters:{GameMod_Enable(GameMod_AnkleBiters);}
		default:
		{
			sv_max_runner_chance.FloatValue = 0.2;
			ov_runner_chance.FloatValue = 0.075;
			ov_runner_kid_chance.FloatValue = 0.3;
			sv_zombie_shambler_crawler_chance.FloatValue = g_fCrawler_chance_default;

			speedflag[crawler]=0;
			g_cvar_crawler_speed.IntValue=1;
			sv_zombie_crawler_health.IntValue = sv_zombie_crawler_health_default;
			phys_pushscale.IntValue=1;
			sv_spawn_density.FloatValue=1.0;
			sv_zombie_moan_freq.IntValue=1;
		}
	}
}



void GameDiff_Enable(GameDif dif)
{	
	g_eGamediff = dif;
	switch(dif)
	{
		case GameDif_Classic:	{sv_difficulty.SetString("classic");}
		case GameDif_Casual:	{sv_difficulty.SetString("casual");}
		case GameDif_Nightmare:	{
		sv_difficulty.SetString("nightmare");
		SetConVarInt(sv_current_diffmode, 2);
		}
		case GameDif_Default:	GameDiff_Def();
	}
}

void GameDiff_Def()
{
	char difficult[32];
	g_cfg_difficulty.GetString(difficult, sizeof(difficult));
	sv_difficulty.SetString(difficult);
}

GameMod Game_GetMod(){
	return g_eGameMode;
}

GameDif Game_GetDif(){
	return g_eGamediff;
}

public Action Cmd_InfoShow(int client, int args)
{
	if(!g_bEnable) PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "ModDisable", client);
	else GameInfo_ShowToClient(client);

	return Plugin_Handled;
}