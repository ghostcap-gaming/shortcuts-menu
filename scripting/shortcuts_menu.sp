#include <sourcemod>
#include <clientprefs>

#pragma newdecls required
#pragma semicolon 1

#define PREFIX_MENU "[Quick Menu]"
#define PREFIX " \x04"... PREFIX_MENU ..."\x01"

#define TRIGGER_KEY IN_SPEED

// Main Menu
Menu g_ShortcutsMenu;

// Convars
ConVar g_TriggerHoldDuration;

// Cookies
Cookie g_AutoOpenMenu;

// Global variables
int g_TriggerHoldTime[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Shortcuts Menu",
	author = "Natanel 'LuqS'",
	description = "",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

// Events (Plugin)
public void OnPluginStart()
{
	// Check Game
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	g_TriggerHoldDuration = CreateConVar("shortcuts_menu_trigger_hold_duration", "1", "The time the player needs to press the trigger key to open the shortcuts menu", _, true);

	AutoExecConfig();

	g_AutoOpenMenu = new Cookie("shortcuts_menu_auto_open", "when enabled the shortcuts menu will open by a holding a trigger key.", CookieAccess_Private);

	g_AutoOpenMenu.SetPrefabMenu(CookieMenu_OnOff_Int, "Open shortcuts menu by holding the -SHIFT- key.");
	
	for (int current_client = 1; current_client <= MaxClients; current_client++)
	{
		if (AreClientCookiesCached(current_client))
		{
			OnClientCookiesCached(current_client);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	char cookie_value[2];
	g_AutoOpenMenu.Get(client, cookie_value, sizeof(cookie_value));	
	
	if (!cookie_value[0])
	{
		g_AutoOpenMenu.Set(client, "1");	
	}
}

// Events (Server)
public void OnMapStart()
{
	// Delete old
	delete g_ShortcutsMenu;

	// Create new
	g_ShortcutsMenu = new Menu(ShortcutsMenu_Handler, MenuAction_Select);
	g_ShortcutsMenu.SetTitle("Quick Menu\n ");

	// Load KeyValues Config
	KeyValues kv = CreateKeyValues("Shortcuts");
	
	// Find the Config
	char file_path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file_path, sizeof(file_path), "configs/shortcuts_menu.cfg");
	
	// Open file and go directly to the settings, if something doesn't work don't continue.
	if (!kv.ImportFromFile(file_path) || !kv.GotoFirstSubKey(false))
	{
		SetFailState("Couldn't load plugin config.");
	}
	
	char display_name[64], commnad[64];
	do
	{
		// Get display name
		kv.GetSectionName(display_name, sizeof(display_name));

		// Get command to execute
		kv.GetString(NULL_STRING, commnad, sizeof(commnad));
		
		g_ShortcutsMenu.AddItem(commnad, display_name);
	} while (kv.GotoNextKey(false));
	
	// Don't leak handles.
	kv.Close();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (buttons & TRIGGER_KEY)
	{
		if (++g_TriggerHoldTime[client] >= g_TriggerHoldDuration.IntValue)
		{
			char cookie_value[2];
			g_AutoOpenMenu.Get(client, cookie_value, sizeof(cookie_value));	
			
			if (StringToInt(cookie_value) && GetClientMenu(client) == MenuSource_None)
			{
				g_ShortcutsMenu.Display(client, MENU_TIME_FOREVER);
				PrintToChat(client, "%s Turn off menu 'auto-open' from !settings.", PREFIX);
			}
			
			g_TriggerHoldTime[client] = 0;
		}
	}
}

int ShortcutsMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char command[64];
		int client = param1, item_pos = param2;
		
		menu.GetItem(item_pos, command, sizeof(command));
		
		FakeClientCommand(client, command);
	}
}
