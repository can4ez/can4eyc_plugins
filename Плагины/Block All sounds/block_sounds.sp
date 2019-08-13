#pragma semicolon 1 

#define PL_NAME 	"BlockSounds"
#define PL_VERSION 	"1.0.0"

#include <sourcemod> 
#include <sdktools> 

#pragma newdecls required

public Plugin myinfo =  {
	name = PL_NAME, 
	author = "can4eyc | Саша Шеин  - vk.com/can4eyc", 
	description = "", 
	version = PL_VERSION, 
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	
	RegPluginLibrary(PL_NAME...PL_VERSION);
	
	return APLRes_Success;
	
}

public void OnPluginStart() {
	
	AddNormalSoundHook(OnNormalSound);
	
}

public void OnPluginEnd() {
	
	
	
}

public void OnMapStart() {
	
	
	
}

public Action OnNormalSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed) {
	if (StrContains(soundEntry, "Step") == -1) {
		for (int x = 0; x < numClients; x++) {
			PrintToConsole(clients[x], "clients[x]>> %i", clients[x]);
			PrintToConsole(clients[x], "sample>> %s", sample);
			PrintToConsole(clients[x], "soundEntry>> %s", soundEntry);
			PrintToConsole(clients[x], "numClients>> %i", numClients);
			PrintToConsole(clients[x], "entity>> %i", entity);
			PrintToConsole(clients[x], "channel>> %i", channel);
			PrintToConsole(clients[x], "volume>> %f", volume);
			PrintToConsole(clients[x], "level>> %i", level);
			PrintToConsole(clients[x], "pitch>> %i", pitch);
			PrintToConsole(clients[x], "flags>> %i", flags);
			PrintToConsole(clients[x], "seed>> %i", seed);
		}
	}
	if (StrContains(soundEntry, "Music.") != -1) {
		
		EmitSoundEntry(clients, numClients, "Music.StopAllMusic", "common/null.wav", entity);
		/*	soundEntry>> Music.GG_Dominating
numClients>> 1
entity>> 3
channel>> 2
volume>> 1065353216
level>> 75
pitch>> 100
flags>> 0
seed>> 52*/
		
		volume = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
} 