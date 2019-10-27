#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgo_colors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Admin Voice", 
	author = "can4eyc | Саша Шеин  - vk.com/can4eyc", 
	description = "", 
	version = "1.3 Beta Release", 
	url = "vk.com/sahapro33"
};

public void OnPluginStart()
{
	g_bRoundStarted = false;
	
	HookEventEx("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
	HookEventEx("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		
		if (IsClientInGame(iClient)) {
			OnClientPostAdminCheck(iClient);
		}
		
	}
}


public void OnClientPostAdminCheck(int iClient) {
	
}

public void Event_PlayerSpawn(Event hEvent, const char[] szName, bool br) {
	
} 

public void Event_PlayerDeath(Event hEvent, const char[] szName, bool br) {
	int iUserID = hEvent.GetInt("userid");
	int iClient = GetClientOfUserId(iUserID);
} 
 
