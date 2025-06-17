
static const float	VOTE_LIMIT			= 0.6;
static const int	MENUDISPLAY_TIME	= 20;


char sModItem[][] =
{
	"ModMenuItemDefault",
	"ModMenuItemRunner",
	"ModMenuItemKid",
	"ModMenuItemCrawler"
};
char sDifItem[][] =
{
	"DifMenuItemDefault",
	"DifMenuItemClassic",
	"DifMenuItemCasual",
	"DifMenuItemNightmare"
};
char DifStrings[][] =		//used when parsing diffenabled convar
{
	"Default",
	"Classic",
	"Casual",
	"Nightmare"
};
char ModStrings[][] =		//used when parsing modenabled convar
{
	"Default",
	"Runner",
	"Kid",
	"Crawler"
};
char ConfigsStrings[][] = 
{
	"Default",
	"Realism",
	"Friendly",
	"Hardcore",
	"Infinity",
	"DoubleJump",
	"GlassCannon",
	"Challenge Timer"
};

bool DifsEnabled[sizeof(DifStrings)];
bool ModsEnabled[sizeof(ModStrings)];
bool ConfigsEnabled[sizeof(ConfigsStrings)];

char sModVote[][] = 
{
	"ModMenuDefVote",
	"ModMenuRunerVote",
	"ModMenuKidVote",
	"ModMenuCrawlerVote"
};
char sDifVote[][] =
{
	"DifMenuDefVote",
	"DifMenuClassicVote",
	"DifMenuCasualVote",
	"DifMenuNightmareVote"
},
	sConfVote[][] =
{
	"ConfMenuDefaultVote",
	"ConfMenuRealismVote",
	"ConfMenuFriendlyVote",
	"ConfMenuHardcoreVote",
	"ConfMenuInfinityVote",
	"ConfMenuItemDoubleJump",
	"ConfMenuItemGlassCannon",
	"ConfMenuItemChallenge",
},
	sConfItem[][] =
{
	"ConfMenuItemDefault",
	"ConfMenuItemRealism",
	"ConfMenuItemFriendly",
	"ConfMenuItemHardcore",
	"ConfMenuItemInfinity",
	"ConfMenuItemDoubleJump",
	"ConfMenuItemGlassCannon",
	"ConfMenuItemChallenge"
};



enum GameMod{
	GameMod_NoMod,
	GameMod_Runner,
	GameMod_Kid,
	GameMod_Crawler
};
enum GameDif{
	GameDif_Default,
	GameDif_Classic,
	GameDif_Casual,
	GameDif_Nightmare
};

enum GameConf{
	GameConf_Default,
	GameConf_Realism,
	GameConf_Friendly,
	GameConf_Hardcore,
	GameConf_Infinity,
	GameConf_DoubleJump,
	GameConf_GlassCannon,
	GameConf_Challenge,
};

ConVar sv_max_runner_chance, ov_runner_chance,	
	ov_runner_kid_chance,
	g_fShambler_crawler_chance,
	sv_realism, sv_hardcore_survival, sv_difficulty,
	sv_zombie_crawler_health,
	sv_zombie_moan_freq,
	sv_spawn_density,
	phys_pushscale,	mp_friendlyfire,

	g_cfg_diffmoder,
	g_cfg_infinity,
	g_cfg_gamemode,
	g_cfg_friendly,
	g_cfg_realism,
	g_cfg_hardcore,
	g_cfg_glasscannon,
	g_cfg_difficulty,
	g_cfg_doublejump,
	g_cfg_casual_cooldown,
	g_cfg_autodefault_timer,
	g_cfg_modeswitch_time,
	g_cfg_modeswitch_map,
	g_cfg_switch_cooldown,
	//game config ConVars

	g_cfg_diffs_enabled,
	g_cfg_mods_enabled,
	g_cfg_configs_enabled;

ConVar  g_cfg_density_enabled;
ConVar  g_cfg_mutators;
ConVar  sv_mutators;
bool g_bEnable;


GameMod	g_eGameMode;	//int
GameDif g_eGameDiff;



//////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------- Menu and voting -----------------------------------------//

void GameInfo_ShowToAll()
{
	for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i)) GameInfo_ShowToClient(i);
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

void GameInfo_ShowToClient(const int client)
{
	//move to variable for debug reason
	int moditem = view_as<int>(Game_GetMod());
	int difitem = view_as<int>(Game_GetDif);
		
	PrintToChat(client, "\x04%T \x01%T \x04%T \x01%T\n\x04%T \x01%T \x04%T \x01%T\n\x04%T \x01%T",
		"ModFlag", client,		sModItem[moditem], client,
		"DifFlag", client,		sDifItem[difitem], client,
		"RealismFlag", client,	sv_realism.BoolValue ? "On" : "Off", client,
		"HardcoreFlag", client,	sv_hardcore_survival.BoolValue ? "On" : "Off", client,
		"FriendlyFlag", client,	mp_friendlyfire.BoolValue ? "On" : "Off", client);
}

public Action Cmd_MenuTop(int client, int args)
{
	if(Game_CanEnable(client)) TopMenu_ShowToClient(client);

	return Plugin_Handled;
}

void TopMenu_ShowToClient(const int client)
{
	char buffer[128];
	Menu menu = new Menu(MenuHandler_TopMenu);
	menu.SetTitle("%T", "TopMenuTitle", client);
	Format(buffer, sizeof(buffer), "%T", "TopMenuItemMod", client);
	menu.AddItem("0", buffer);
	Format(buffer, sizeof(buffer), "%T", "TopMenuItemDifficult", client);
	menu.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%T", "TopMenuItemConfig", client);
	menu.AddItem("2", buffer);
	if (g_cfg_density_enabled.BoolValue)
	{
		Format(buffer, sizeof(buffer), "%T", "TopMenuDensity", client);
		menu.AddItem("3", buffer);
	}

	char mutators[512];
	g_cfg_mutators.GetString(mutators, 256);	
	if ( !StrEqual(mutators, "", false) )
	{
		char mutators_single[16][32];
		int nMutators = ExplodeString(mutators, " ", mutators_single, 16, 32, false);
		if (nMutators<=1)
		{
			nMutators = ExplodeString(mutators, ",", mutators_single, 16, 32, false);
			if (nMutators<=1)
			{
				nMutators = ExplodeString(mutators, ", ", mutators_single, 16, 32, false);
			}
		}
		for (int i = 0; i<nMutators; i++)
		{
			char buff[8];
			IntToString(i+3, buff, sizeof(buff));
			menu.AddItem( buff, mutators_single[i] );
		}
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}



public int MenuHandler_TopMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			if(!Game_CanEnable(client)) return 0;

			switch(param2)
			{
				case 0: ModMenu_ShowToClient(client);
				case 1: DifMenu_ShowToClient(client);
				case 2: ConfMenu_ShowToClient(client);
				case 3: DensityMenu_ShowToClient(client);
				default:	//Handle Mutators
				{
				char mutator[32];
				char junk[1]; //cant retrieve displaybuffer without retrieving infobuffer..  ¯\_(ツ)_/¯
				GetMenuItem(menu, param2, junk,sizeof(junk), _, mutator, sizeof(mutator), client);
				Mutator_Vote(client, mutator);	
				}
			}

		}
	}
	return 0;
}


void Mutator_Vote(const int client, char[] conf)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "On", client);
	Format(item_no, sizeof(item_no), "%T", "Off", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", conf);
	Format(item_no_flag, sizeof(item_no_flag), "Off,%d", conf);


	Menu menu = new Menu(MenuHandler_MutatorVote, MENU_ACTIONS_ALL);
	menu.SetTitle(conf, client, name, conf);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
    
	return;
}

public int MenuHandler_MutatorVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%T", "On", param1);
			Format(item_no, sizeof(item_no), "%T", "Off", param1);
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{



			//get chosen mutator
			char title[64];
			menu.GetTitle(title, sizeof(title));
			//get all active mutators
			char mutators[512];
			sv_mutators.GetString(mutators, 256);	

			char mutators_single[16][32];
			int nMutators = ExplodeString(mutators, " ", mutators_single, 16, 32, false);
			if (nMutators<=1)
			{
				nMutators = ExplodeString(mutators, ",", mutators_single, 16, 32, false);
				if (nMutators<=1)
				{
					nMutators = ExplodeString(mutators, ", ", mutators_single, 16, 32, false);
				}
			}

			bool bActive = false;
			int iActive = 0;
			//check mutator already active, skip
			for (int i = 0; i<nMutators; i++)
			{
				if (StrEqual(mutators_single[i], title))
				{
					iActive=i;
					bActive=true;
					break;
				}
			}

			char item[64];
			
			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item));
			bool isOff = StrContains(item, "Off") == 0;
			


			GameConf conf;
			if(isOff)
			{
				char item_no[2][32];
				ExplodeString(item, ",", item_no, 2, 32);
				conf = view_as<GameConf>(StringToInt(item_no[StrEqual(item_no[0], "Off") ? 1 : 0]));
			}
			else conf = view_as<GameConf>(StringToInt(item));
			if(!isOff && param1 == 1) votes = totalVotes - votes;
			if((!isOff && FloatCompare(GetVotePercent(votes, totalVotes),VOTE_LIMIT) < 0 && !param1)
			|| (isOff && param1 == 1))
			{
				
				if(conf == GameConf_Default) 
					PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
				else
				{
					//Vote switch to off
					if (!bActive)
					{
						PrintToChatAll("\x04%t\x01 %s %t, but is already off", "ChatFlag", title, "VoteFinishToOff");
						return 0;
					}
					else
					{	
						Format(mutators_single[iActive], 32, "");
						char newMutators[512]
						ImplodeStrings(mutators_single, nMutators-1, ",", newMutators, sizeof(newMutators))
						sv_mutators.SetString(newMutators);
						PrintToChatAll("\x04%t\x01 %s %t", "ChatFlag", title, "VoteFinishToOff");
					}

				}
				return 0;
			}

			//Vote switch to on
			if (bActive)
			{
				PrintToChatAll("\x04%t\x01 %s %t, but it is already active", "ChatFlag", title , conf == GameConf_Default ? "VoteFinish" : "VoteFinishToOn");
				return 0;
			}
			else
			{
				PrintToChatAll("\x04%t\x01 %s %t", "ChatFlag", title , conf == GameConf_Default ? "VoteFinish" : "VoteFinishToOn");
				char newMutators[512]
				Format(newMutators, sizeof(newMutators), "%s, %s", mutators, title);
				sv_mutators.SetString(newMutators);
			}
			
		}
	}
	return 0;
}



bool Game_CanEnable(const int client)
{
	if(!g_bEnable)
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "ModDisable", client);
		return false;
	}
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteByAlive", client);
		return false;
	}
	return true;
}

void ModMenu_ShowToClient(const int client)
{
	char buffer[128], item[32];
	Menu menu = new Menu(MenuHandler_ModMenu);
	menu.SetTitle("%T", "ModMenuTitle", client);
	
	for ( int mod=0; mod < sizeof(ModStrings); mod++ )	{
		if(!ModsEnabled[mod])
			continue;
		Format(item, sizeof(item), "%d", mod);
		Format(buffer, sizeof(buffer), "%T", sModItem[view_as<int>(mod)], client);
		menu.AddItem(item, buffer);
	}	

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}



public int MenuHandler_ModMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	delete menu;
		case MenuAction_Cancel:	TopMenu_ShowToClient(client);
		case MenuAction_Select:	
		{
			if(Game_CanEnable(client))
			{
				char gamemode[32];
				menu.GetItem(param2, gamemode, sizeof(gamemode));
				ModMenu_Vote(client, view_as<GameMod>(StringToInt(gamemode)));
			}
		}
	}
	return 0;
}


bool TestVoteDelay(int client)
{
	int delay = CheckVoteDelay();
	if(!delay) return true;

	if (delay > g_cfg_switch_cooldown.FloatValue) PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteDelayMinutes", client, RoundToNearest(delay / g_cfg_switch_cooldown.FloatValue));
	else PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteDelaySeconds", client, delay);
	return false;
}

float GetVotePercent(int votes, int totalVotes)
{
	return float(votes) / float(totalVotes);
}

void ModMenu_Vote(const int client, GameMod mod)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "Yes", client);
	Format(item_no, sizeof(item_no), "%T", "No", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", mod);
	Format(item_no_flag, sizeof(item_no_flag), "no,%d", mod);
	Menu menu = new Menu(MenuHandler_ModVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", sModVote[view_as<int>(mod)], client, name);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
	return;
}



public int MenuHandler_ModVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%t", "On");
			Format(item_no, sizeof(item_no), "%t", "Off");
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{
			char item[64], display[64];
			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
			bool isNo = StrContains(item, "no") == 0;
			if(!isNo && param1 == 1) votes = totalVotes - votes;
			if((!isNo && FloatCompare(GetVotePercent(votes, totalVotes), VOTE_LIMIT) < 0 && !param1)
			|| (isNo && param1 == 1))
			{
				PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
				return 0;
			}
			GameMod mod;
			if(isNo)
			{
				char item_no[2][32];
				ExplodeString(item, ",", item_no, 2, 32);
				if(StrEqual(item_no[0], "no"))
					mod = view_as<GameMod>(StringToInt(item_no[1]));
				else mod = view_as<GameMod>(StringToInt(item_no[0]));
			}
			else mod = view_as<GameMod>(StringToInt(item));
			GameMod_Enable(mod);
			Game_ShamblerToRunner(mod);
			PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinish");
		}
	}
	return 0;
}



void DifMenu_ShowToClient(const int client)
{
	char buffer[128], item[32];
	Menu menu = new Menu(MenuHandler_DifMenu);
	menu.SetTitle("%T", "DifMenuTitle", client);
	
	for ( int gamedif=0; gamedif < sizeof(DifStrings); gamedif++ )	{
		if(!DifsEnabled[gamedif])
			continue;
		Format(item, sizeof(item), "%d", gamedif);
		Format(buffer, sizeof(buffer), "%T", sDifItem[view_as<int>(gamedif)], client);
		menu.AddItem(item, buffer);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}


void GetEnabledDiffs()
{
	char buff[128];
	char buff2[16][32];
	g_cfg_diffs_enabled.GetString(buff, sizeof(buff));
	int nDiffsEnabled = ExplodeString(buff, " ", buff2, 16, 32, false);
	
	for (int i = 0; i < nDiffsEnabled; i++)
	{
		for ( int n=0; n < sizeof( DifStrings); n++   )
		{
			if 	(StrEqual(DifStrings[n], buff2[i], false))
				DifsEnabled[n] = true;
		}
	}
}
void GetEnabledMods()
{
	char buff[128];
	char buff2[16][32];
	g_cfg_mods_enabled.GetString(buff, sizeof(buff));
	int nModsEnabled = ExplodeString(buff, " ", buff2, 16, 32, false);
	
	for (int i = 0; i < nModsEnabled; i++)
	{
		for ( int n=0; n < sizeof( ModStrings); n++   )
		{
			if 	(StrEqual(ModStrings[n], buff2[i], false))
				ModsEnabled[n] = true;
		}
	}
}
void GetEnabledConfigs()
{
	char buff[256];
	char buff2[16][32];
	g_cfg_configs_enabled.GetString(buff, sizeof(buff));
	int nConfigsEnabled = ExplodeString(buff, " ", buff2, 16, 32, false);
	for (int i = 0; i < nConfigsEnabled; i++)
	{
		for ( int n=0; n < sizeof( ConfigsStrings); n++   )
		{
			if 	(StrEqual(ConfigsStrings[n], buff2[i], false))
				ConfigsEnabled[n] = true;
		}
	}
}

public int MenuHandler_DifMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	delete menu;
		case MenuAction_Cancel:	TopMenu_ShowToClient(client);
		case MenuAction_Select:
		{
			if(Game_CanEnable(client))
			{
				char gamedif[32];
				menu.GetItem(param2, gamedif, sizeof(gamedif));
				int selection = StringToInt(gamedif);
				DifMenu_Vote(client, view_as<GameDif>(selection));
			}
		}
	}
	return 0;
}


bool f_casualswitch_cooldown = false;
int timercount = 0;
public Action Timer_Casualswitch(Handle timer){
	timercount -= 10;
	if ( timercount <= 0 )	
	{
		timercount = 0;
		f_casualswitch_cooldown = false;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


void DifMenu_Vote(const int client, GameDif dif)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;
	int selection = view_as<int>(dif);
	if ( selection == view_as<int>(GameDif_Casual) && f_casualswitch_cooldown ) {
		PrintToChat(client, "You must wait < %d seconds before changing to casual again.", timercount);
		return;
	}
	else if ( selection == view_as<int>(GameDif_Casual) )
	{
		CreateTimer(10.0, Timer_Casualswitch, _, TIMER_REPEAT);
		timercount = g_cfg_casual_cooldown.IntValue;
		f_casualswitch_cooldown = true;
	}

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "Yes", client);
	Format(item_no, sizeof(item_no), "%T", "No", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", dif);
	Format(item_no_flag, sizeof(item_no_flag), "no,%d", dif);
	Menu menu = new Menu(MenuHandler_DifVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", sDifVote[view_as<int>(dif)], client, name);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
}

public int MenuHandler_DifVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%t", "On");
			Format(item_no, sizeof(item_no), "%t", "Off");
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{
			char item[64], display[64];
			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
			bool isNo = StrContains(item, "no") == 0;
			if(!isNo && param1 == 1) votes = totalVotes - votes;
			if((!isNo && FloatCompare(GetVotePercent(votes, totalVotes),VOTE_LIMIT) < 0 && param1 == 0)
			|| (isNo && param1 == 1))
			{
				PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
				return 0;
			}
			GameDif dif;
			if(isNo)
			{
				char item_no[2][32];
				ExplodeString(item, ",", item_no, 2, 32);
				dif = view_as<GameDif>(StringToInt(item_no[StrEqual(item_no[0], "no") ? 1 : 0]));
			}
			else dif = view_as<GameDif>(StringToInt(item));
			GameDiff_Enable(dif);
			PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinish");
		}
	}
	return 0;
}

void ConfMenu_ShowToClient(const int client)
{
	char buffer[128], item[32];
	Menu menu = new Menu(MenuHandler_ConfMenu);
	menu.SetTitle("%T", "ConfMenuTitle", client);


	for ( int gameconfig=0; gameconfig < sizeof(ConfigsStrings); gameconfig++ )	{
		if(!ConfigsEnabled[gameconfig])
			continue;
		Format(item, sizeof(item), "%d", gameconfig);
		Format(buffer, sizeof(buffer), "%T", sConfItem[view_as<int>(gameconfig)], client);
		menu.AddItem(item, buffer);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ConfMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	delete menu;
		case MenuAction_Cancel:	TopMenu_ShowToClient(client);
		case MenuAction_Select:
		{
			if(Game_CanEnable(client))
			{
				char gameconf[32];
				menu.GetItem(param2, gameconf, sizeof(gameconf));
				ConfMenu_Vote(client, view_as<GameConf>(StringToInt(gameconf)));
			}
		}
	}
	return 0;
}

void ConfMenu_Vote(const int client, GameConf conf)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "On", client);
	Format(item_no, sizeof(item_no), "%T", "Off", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", conf);
	Format(item_no_flag, sizeof(item_no_flag), "Off,%d", conf);
	Menu menu = new Menu(MenuHandler_ConfVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", sConfVote[view_as<int>(conf)], client, name);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
	return;
}

public int MenuHandler_ConfVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%T", "On", param1);
			Format(item_no, sizeof(item_no), "%T", "Off", param1);
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{
			char item[64];
			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item));
			bool isOff = StrContains(item, "Off") == 0;
			GameConf conf;
			if(isOff)
			{
				char item_no[2][32];
				ExplodeString(item, ",", item_no, 2, 32);
				conf = view_as<GameConf>(StringToInt(item_no[StrEqual(item_no[0], "Off") ? 1 : 0]));
			}
			else conf = view_as<GameConf>(StringToInt(item));
			if(!isOff && param1 == 1) votes = totalVotes - votes;
			if((!isOff && FloatCompare(GetVotePercent(votes, totalVotes),VOTE_LIMIT) < 0 && !param1)
			|| (isOff && param1 == 1))
			{
				if(conf == GameConf_Default) PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
				else
				{
					GameConfig_Enable(conf, false);
					PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinishToOff");
				}
				return 0;
			}
			GameConfig_Enable(conf, true);
			PrintToChatAll("\x04%t\x01 %t", "ChatFlag", conf == GameConf_Default ? "VoteFinish" : "VoteFinishToOn");
		}
	}
	return 0;
}











void DensityMenu_ShowToClient(const int client)
{
	Menu menu = new Menu(MenuHandler_DensityMenu);
	menu.SetTitle("Density", client);


    menu.AddItem("1", "x1");
    menu.AddItem("2", "x2");
    menu.AddItem("4", "x4");
    menu.AddItem("8", "x8");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DensityMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	delete menu;
		case MenuAction_Cancel:	TopMenu_ShowToClient(client);
		case MenuAction_Select:
		{
			if(Game_CanEnable(client))
			{
				char density[32];
				menu.GetItem(param2, density, sizeof(density));
				DensityMenu_Vote(client, density);
			}
		}
	}
	return 0;
}

 
void DensityMenu_Vote(const int client, char[] conf)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "On", client);
	Format(item_no, sizeof(item_no), "%T", "Off", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", conf);
	Format(item_no_flag, sizeof(item_no_flag), "Off,%d", conf);


	Menu menu = new Menu(MenuHandler_DisplayVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", "DensityMenuVote", client, name, conf);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
    
	return;
}

public int MenuHandler_DisplayVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%T", "On", param1);
			Format(item_no, sizeof(item_no), "%T", "Off", param1);
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{
			//param1: 1 is no, 0 is yes

			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);

			char item[8];
			menu.GetItem(param1, item, sizeof(item));

			//I do not know why sourcemod is saving this string number as its unicode representation and then not passing it correctly here...
			// queue convolutely converting this dickhead value..

			char val = view_as<char>(StringToInt(item, 10));
			Format(item, sizeof(item), "%c", val);
			int realvalue = StringToInt(item, 10);

			if (realvalue>10)
			{
				realvalue = 10;
			}

			if(param1 == 1) 
				votes = totalVotes - votes;
			if((FloatCompare(GetVotePercent(votes, totalVotes), VOTE_LIMIT) < 0 && !param1) || param1 == 1)
			{
				PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
			}
			else
			{
				PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinishToOn");
				PrintToChatAll("Setting Density to x%i", realvalue);
				sv_spawn_density.IntValue = realvalue;
			}
			return 0;	
		}
	}
	return 0;
}