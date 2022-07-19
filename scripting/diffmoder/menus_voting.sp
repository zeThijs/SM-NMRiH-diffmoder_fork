
static const float	VOTE_LIMIT			= 0.6;
static const int	MENUDISPLAY_TIME	= 20;


char	sModItem[][] =
{
	"ModMenuItemDefault",
	"ModMenuItemRunner",
	"ModMenuItemKid",
	"ModMenuItemAnkleBiters"
};
char	sDifItem[][] =
{
	"DifMenuItemDefault",
	"DifMenuItemClassic",
	"DifMenuItemCasual",
	"DifMenuItemNightmare"
};


char sModVote[][] = {
	"ModMenuDefVote",
	"ModMenuRunerVote",
	"ModMenuKidVote",
	"ModMenuAnkleBitersVote"
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
	"ConfMenuItemDoubleJump"
},
	sConfItem[][] =
{
	"ConfMenuItemDefault",
	"ConfMenuItemRealism",
	"ConfMenuItemFriendly",
	"ConfMenuItemHardcore",
	"ConfMenuItemInfinity",
	"ConfMenuItemDoubleJump"
};



enum GameMod{
	GameMod_Default,
	GameMod_Runner,
	GameMod_Kid,
	GameMod_AnkleBiters
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
	GameConf_DoubleJump
};

ConVar sv_max_runner_chance,
	sv_zombie_shambler_crawler_chance,
	ov_runner_chance,
	ov_runner_kid_chance,
	sv_realism, mp_friendlyfire,
	sv_hardcore_survival,
	sv_difficulty,

	sv_zombie_crawler_health,

	phys_pushscale,
	sv_spawn_density,
	sv_zombie_moan_freq,
	sv_current_diffmode,
	g_cfg_diffmoder,
	g_cfg_infinity,
	g_cfg_gamemode,
	g_cfg_friendly,
	g_cfg_realism,
	g_cfg_hardcore,
	g_cfg_difficulty,
	g_cfg_doublejump,

	g_cfg_casual_cooldown,
	g_cfg_autodefault_timer,
	g_cfg_modeswitch_time,
	g_cfg_modeswitch_cooldown;

    bool g_bEnable;


//#include "diffmoder/consts.sp"

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
	PrintToChat(client, "\x04%T \x01%T \x04%T \x01%T\n\x04%T \x01%T \x04%T \x01%T\n\x04%T \x01%T",
		"ModFlag", client,		sModItem[view_as<int>(Game_GetMod())], client,
		"DifFlag", client,		sDifItem[view_as<int>(Game_GetDif())], client,
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
	
	Format(item, sizeof(item), "%d", GameMod_Runner);
	Format(buffer, sizeof(buffer), "%T", sModItem[view_as<int>(GameMod_Runner)], client);
	menu.AddItem(item, buffer);

	Format(item, sizeof(item), "%d", GameMod_Kid);
	Format(buffer, sizeof(buffer), "%T", sModItem[view_as<int>(GameMod_Kid)], client);
	menu.AddItem(item, buffer);

	Format(item, sizeof(item), "%d", GameMod_AnkleBiters);
	Format(buffer, sizeof(buffer), "%T", sModItem[view_as<int>(GameMod_AnkleBiters)], client);
	menu.AddItem(item, buffer);

	Format(item, sizeof(item), "%d", GameMod_Default);
	Format(buffer, sizeof(buffer), "%T", sModItem[view_as<int>(GameMod_Default)], client);
	menu.AddItem(item, buffer);

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

	if (delay > g_cfg_modeswitch_cooldown.IntValue) PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteDelayMinutes", client, RoundToNearest(delay / g_cfg_modeswitch_cooldown.IntValue));
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
	
	Format(item, sizeof(item), "%d", GameDif_Classic);
	Format(buffer, sizeof(buffer), "%T", sDifItem[view_as<int>(GameDif_Classic)], client);
	menu.AddItem(item, buffer);
	
	Format(item, sizeof(item), "%d", GameDif_Casual);
	Format(buffer, sizeof(buffer), "%T", sDifItem[view_as<int>(GameDif_Casual)], client);
	menu.AddItem(item, buffer);
	
	Format(item, sizeof(item), "%d", GameDif_Nightmare);
	Format(buffer, sizeof(buffer), "%T", sDifItem[view_as<int>(GameDif_Nightmare)], client);
	menu.AddItem(item, buffer);
	
	Format(item, sizeof(item), "%d", GameDif_Default);
	Format(buffer, sizeof(buffer), "%T", sDifItem[view_as<int>(GameDif_Default)], client);
	menu.AddItem(item, buffer);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
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


//Handle t_casualswitch_cooldown = INVALID_HANDLE;
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
	
	Format(item, sizeof(item), "%d", GameConf_Realism);
	Format(buffer, sizeof(buffer), "%T", sConfItem[view_as<int>(GameConf_Realism)], client);
	menu.AddItem(item, buffer);
	
	Format(item, sizeof(item), "%d", GameConf_Friendly);
	Format(buffer, sizeof(buffer), "%T", sConfItem[view_as<int>(GameConf_Friendly)], client);
	menu.AddItem(item, buffer);
	
	Format(item, sizeof(item), "%d", GameConf_Hardcore);
	Format(buffer, sizeof(buffer), "%T", sConfItem[view_as<int>(GameConf_Hardcore)], client);
	menu.AddItem(item, buffer);
	
	Format(item, sizeof(item), "%d", GameConf_Infinity);
	Format(buffer, sizeof(buffer), "%T", sConfItem[view_as<int>(GameConf_Infinity)], client);
	menu.AddItem(item, buffer);

	Format(item, sizeof(item), "%d", GameConf_DoubleJump);
	Format(buffer, sizeof(buffer), "%T", sConfItem[view_as<int>(GameConf_DoubleJump)], client);
	menu.AddItem(item, buffer);

	Format(item, sizeof(item), "%d", GameConf_Default);
	Format(buffer, sizeof(buffer), "%T", sConfItem[view_as<int>(GameConf_Default)], client);
	menu.AddItem(item, buffer);
	
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