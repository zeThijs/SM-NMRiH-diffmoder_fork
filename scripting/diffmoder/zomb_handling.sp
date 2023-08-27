

/**
 * Function:    CNMRiH_BaseZombie::BecomeRunner
 * Signature:   void CNMRiH_BaseZombie::BecomeRunner()
 * Description: Turns this zombie into a runner.
 *
 * @return     true on success, false otherwise
 */
/**
 * Function:    CNMRiH_BaseZombie::BecomeCrawler
 * Signature:   void CNMRiH_BaseZombie::BecomeCrawler()
 * Description: Turns this zombie into a crawler.
 *
 * @return     true on success, false otherwise
 */

/**
 * Function:    CNMRiH_BaseZombie::IsCrawler
 * Signature:   bool CNMRiH_BaseZombie::IsCrawler()
 * Description: Returns true if this zombie is a crawler.
 *
 * @return     true on success, false otherwise
 */

/**
 * Function:    CNMRiH_BaseZombie::IsRunner
 * Signature:   bool CNMRiH_BaseZombie::IsRunner()
 * Description: Returns true if this zombie is a runner.
 *
 * @return     true on success, false otherwise
 */


// Function:    CNMRiH_BaseZombie::IsRunner
// Signature:   bool CNMRiH_BaseZombie::IsRunner()
// Description: Returns true if this zombie is a runner.

// Function:    CNMRiH_BaseZombie::IsTurned
// Signature:   bool CNMRiH_BaseZombie::IsTurned()
// Description: Returns true if this zombie is a turned player.

#include "vscript_proxy"

int g_iEnt_VscriptProxy;

ArrayList g_zombie_speeds;

//zombie speeds
ConVar 	g_cvar_zombie_speeds_enabled, 
 		g_cvar_crawler_speed,
 		g_cvar_crawler_speed_plusminus;
 		// g_cvar_kid_speed,
 		// g_cvar_kid_speed_plusminus,
 		// g_cvar_shambler_speed,
 		// g_cvar_shambler_speed_plusminus,
 		// g_cvar_runner_speed,
 		// g_cvar_runner_speed_plusminus;

Handle g_dhook_change_zombie_ground_speed;
Handle g_dhook_change_zombie_playback_speed;
Handle g_sdkcall_get_sequence_name;


#define CASE_SENSITIVE true
#define CASE_INSENSITIVE false

bool g_is_linux;
//int g_offset_is_crawler;


/**
 * Sets up a vscript proxy entity
 * 
 * @return     Entity sm reference id on success, -1 on fail
 */
void SetupVscriptProxy(){
	g_iEnt_VscriptProxy = CreateVscriptProxy();
	if (g_iEnt_VscriptProxy == -1){
		LogError("---DiffModer--- Unable to setup vscript proxy.");
	}
}

int CreateVscriptProxy(){
	int proxy = CreateEntityByName("logic_script_proxy");
	if (proxy == -1) {
		ThrowError("---DiffModer--- Failed to create VScript proxy entity.");
	}
	//DispatchSpawn(proxy);
	return proxy;
}


void BecomeCrawler(int entityref){
    RunEntVScript(entityref, "BecomeCrawler()", g_iEnt_VscriptProxy);
}


void BecomeRunner(int entityref){
    RunEntVScript(entityref, "BecomeRunner()", g_iEnt_VscriptProxy);
}


bool IsValidShamblerzombie(int zombie)
{
    if ((zombie <= MaxClients))
        return false;
	if( !IsValidEntity(zombie) ) 
        return false;

    //Fix bosses being tranformed: targetname check
    decl String:sName[4];
    GetEntPropString(zombie, Prop_Data, "m_iName", sName, sizeof(sName)); 
    
    if ( !StrEqual(sName, "", false)){
        PrintToServer("Has name, skipping..");
        return false;
    }

    //classname check broke, something is fucky, accidental whitespace?
	decl String:classname[8];   //purposely omit trailing classname substring
	GetEntityClassname(zombie, classname, sizeof(classname));

	return StrEqual(classname, "npc_nmrih_shambler", false);
}

//transform shamblers to specials, and -not implemented yet- crawlers
//fastest would be to hook zombie speed in here to prevent unnecessary checks
public void SDKHookCB_ZombieSpawnPost(int zombie)
{
	if(!g_bEnable || !IsValidEntity(zombie) || !IsValidShamblerzombie(zombie))
		SDKUnhook(zombie, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);

	float orgin[3];
	GetEntPropVector(zombie, Prop_Send, "m_vecOrigin", orgin);
    

	switch(Game_GetMod())	{
		case GameMod_Runner:		
            {
            //BecomeRunner(EntIndexToEntRef(zombie))          ; //disabling as this mod works TOO well: too many runners spawn for players
            ShamblerToRunnerFromPosion(zombie, orgin, false);
            }
		case GameMod_Kid:			ShamblerToRunnerFromPosion(zombie, orgin, true) ; 
		case GameMod_AnkleBiters: {
            BecomeCrawler(EntIndexToEntRef(zombie));
            DataPack data = CreateDataPack();
            data.WriteCell(zombie);
            RequestFrame(CB_CrawlerSpeed, data);
		}
	}
	SDKUnhook(zombie, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
}


public void CB_CrawlerSpeed(DataPack data)
{
    data.Reset();
    int zombie = EntRefToEntIndex(data.ReadCell());
    if (zombie<1 /*&& !IsValidShamblerzombie(zombie)*/ ){          //is zombie still alive?     -- TODO isvalidzombie needed? -> there aleady is a reference check..
        return;
    }
    //PrintToServer("Hello, I am crawler");
    DHookEntity(g_dhook_change_zombie_ground_speed, true, zombie);
    DHookEntity(g_dhook_change_zombie_playback_speed, true, zombie);
    g_zombie_speeds.Set(zombie, RandomSpeedScalar(g_cvar_crawler_speed, g_cvar_crawler_speed_plusminus));
}


void Game_ShamblerToRunner(const GameMod mod)
{
	int MaxEnt = GetMaxEntities();
	for(int zombie = MaxClients + 1; zombie <= MaxEnt; zombie++){
		if(!IsValidShamblerzombie(zombie)) continue;
		float orgin[3];
		GetEntPropVector(zombie, Prop_Send, "m_vecOrigin", orgin);
		switch(mod){
			case GameMod_Runner:	BecomeRunner(EntIndexToEntRef(zombie));
			case GameMod_Kid:		ShamblerToRunnerFromPosion(zombie, orgin, true);
		}
	}
}

int FastZombie_Create(float orgin[3], bool isKid = false)
{
	int zombie = -1;
	zombie = CreateEntityByName(isKid ? "npc_nmrih_kidzombie" : "npc_nmrih_turnedzombie");
	if(!IsValidEntity(zombie)) return -1;

	if(DispatchSpawn(zombie)) TeleportEntity(zombie, orgin, NULL_VECTOR, NULL_VECTOR);

	return zombie;
}


int ShamblerToRunnerFromPosion(int shamblerrunner, float pos[3], bool isKid = false)
{
	AcceptEntityInput(shamblerrunner, "kill");
	RemoveEdict(shamblerrunner);
	return FastZombie_Create(pos, isKid);
}









/*
    setup zombie speeds
*/
void zombiespeeds_init(){    
	g_zombie_speeds = new ArrayList(1, GetMaxEntities());

    g_cvar_zombie_speeds_enabled = CreateConVar("sm_zombie_speeds_enabled", "1", "1 = Enable plugin. 0 = Disable plugin.");

    g_cvar_crawler_speed = CreateConVar("sm_crawler_speed", "1.0",
        "Amount to scale crawlers' movement speed by. E.g. 1.0 means move at normal speed.");

    g_cvar_crawler_speed_plusminus = CreateConVar("sm_crawler_speed_plusminus", "0.05",
        "Set the range of random variation in crawlers' movement speed.");

    // Game data is necesary for our DHooks.
    Handle gameconf = LoadGameConfigFile("zombiespeeds.games");
    if (!gameconf) 
    {
        SetFailState("Failed to load zombiespeeds game data.");
    }

    g_is_linux = GameConfGetOffsetOrFail(gameconf, "IsLinux") != 0;

    StartPrepSDKCall(SDKCall_Entity);
    GameConfPrepSDKCallSignatureOrFail(gameconf, "CBaseAnimating::GetSequenceName");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);  // sequence
    PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
    g_sdkcall_get_sequence_name = EndPrepSDKCall();

    //
    // Changing movement speed
    //
    int offset = GameConfGetOffsetOrFail(gameconf, "CBaseAnimating::GetSequenceGroundSpeed");

    g_dhook_change_zombie_ground_speed = DHookCreate(offset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHook_ChangeZombieGroundSpeed);
    DHookAddParam(g_dhook_change_zombie_ground_speed, HookParamType_ObjectPtr); // CStudioHdr *
    DHookAddParam(g_dhook_change_zombie_ground_speed, HookParamType_Int); // sequence

    //
    // Changing playback speed
    //
    offset = GameConfGetOffsetOrFail(gameconf, "CAI_BaseNPC::NPC_TranslateActivity");

    g_dhook_change_zombie_playback_speed = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, DHook_ChangeZombiePlaybackSpeed);
    DHookAddParam(g_dhook_change_zombie_playback_speed, HookParamType_Int); // Activity

    AutoExecConfig(true);
}


public void DHookZombie(int entity){
	DHookEntity(g_dhook_change_zombie_ground_speed, true, entity);
	DHookEntity(g_dhook_change_zombie_playback_speed, true, entity);
}


//------------------------------------------------------
//------------------------------------------------------
//----------------zombie speed helpers------------------

public MRESReturn DHook_ChangeZombieGroundSpeed(int zombie, Handle return_handle, Handle params)
{
    MRESReturn result = MRES_Ignored;

    if (g_cvar_zombie_speeds_enabled.BoolValue)
    {
        int sequence = DHookGetParam(params, 2);
        char sequence_name[32];
        SDKCall(g_sdkcall_get_sequence_name, zombie, sequence_name, sizeof(sequence_name), sequence);

        if (IsMoveSequence(sequence_name))
        {
            float speed = DHookGetReturn(return_handle);
            float scalar = g_zombie_speeds.Get(zombie);
            DHookSetReturn(return_handle, speed * scalar);
            result = MRES_Override;
        }
    }

    return result;
}

public MRESReturn DHook_ChangeZombiePlaybackSpeed(int zombie, Handle return_handle, Handle params)
{
    if (g_cvar_zombie_speeds_enabled.BoolValue)
    {
        SetEntPropFloat(zombie, Prop_Data, "m_flPlaybackRate", g_zombie_speeds.Get(zombie));
    }
    return MRES_Ignored;
}

bool IsMoveSequence(const char[] name)
{
    // on linux, crawler sequence is "crawl"
    static const char CRAWLER_CRAWL_LINUX[] = "crawl";
    static const char CRAWLER_CRAWL_WINDOWS[] = "ACT_CRAWL";

    // on linux, kid uses sequence "run"
    //static const char KID_RUN_LINUX[] = "Run"; // can ignore kid sequence because it's named the same as the runner's
    static const char KID_RUN_WINDOWS[] = "ACT_WALK";

    // on linux, runner uses sequence "run"
    static const char RUNNER_RUN_LINUX[] = "Run";
    static const char RUNNER_RUN_WINDOWS[] = "ACT_RUN";

    // on linux, shambler sequence is walk1, walk2, walk3, etc.
    // on windows, shambler sequence is ACT_WALK, ACT_WALK_2, ACT_WALK_3, etc.
    static const char SHAMBLER_WALK_LINUX[] = "walk";
    static const char SHAMBLER_WALK_WINDOWS[] = "ACT_WALK";

    if (g_is_linux)
    {
        return !strncmp(name, SHAMBLER_WALK_LINUX, sizeof(SHAMBLER_WALK_LINUX) - 1) ||
            StrEqual(name, RUNNER_RUN_LINUX) ||
            //StrEqual(name, KID_RUN_LINUX) ||
            StrEqual(name, CRAWLER_CRAWL_LINUX);
    }

    return !strncmp(name, SHAMBLER_WALK_WINDOWS, sizeof(SHAMBLER_WALK_WINDOWS) - 1) ||
        StrEqual(name, RUNNER_RUN_WINDOWS) ||
        StrEqual(name, KID_RUN_WINDOWS) ||
        StrEqual(name, CRAWLER_CRAWL_WINDOWS);
}

// /**
//  * Check if a shambler is also a crawler.
//  */
// bool IsCrawler(int shamblerdef)
// {
//     return GetEntData(shamblerdef, g_offset_is_crawler, 1) != 0;
// }


/**
 * Compute a random speed in range (base - plusminus) to (base + plusminus).
 */
float RandomSpeedScalar(ConVar base, ConVar plusminus)
{
    float scalar = base.FloatValue;
    float range = FloatAbs(plusminus.FloatValue);
    if (range > 0.0)
    {
        scalar += (GetURandomFloat() - 0.5) * 2.0 * range;
    }
    return scalar;
}

/**
 * Retrieve an offset from a game conf or abort the plugin.
 */
int GameConfGetOffsetOrFail(Handle gameconf, const char[] key)
{
    int offset = GameConfGetOffset(gameconf, key);
    if (offset == -1)
    {
        CloseHandle(gameconf);
        SetFailState("Failed to read gamedata offset of %s", key);
    }
    return offset;
}

/**
* Prep SDKCall from signature or abort.
*/
void GameConfPrepSDKCallSignatureOrFail(Handle gameconf, const char[] key)
{
    if (!PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, key))
    {
        CloseHandle(gameconf);
        SetFailState("Failed to retrieve signature for gamedata key %s", key);
    }
}

//---------------zombie speed helpers end---------------
//------------------------------------------------------
//------------------------------------------------------