#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool g_bCanVoice[MAXPLAYERS + 1];

int g_iPlayerPrevButtons[MAXPLAYERS + 1];
int iCounter[MAXPLAYERS + 1];
bool g_OnceStopped[MAXPLAYERS + 1];
Handle resetTmr[MAXPLAYERS + 1] = null;
bool bAdminVoiceChat[MAXPLAYERS + 1];

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Admin Voice", 
	author = "can4eyc | Саша Шеин  - vk.com/can4eyc", 
	description = "", 
	version = "1.2 Beta Release", 
	url = "vk.com/sahapro33"
};

public void OnPluginStart()
{
	HookEventEx("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool br)
{
	g_bCanVoice[GetClientOfUserId(event.GetInt("userid"))] = true;
	UpdateListenOverride();
}

public Action Event_PlayerDeath(Event event, const char[] name, bool br)
{
	int iUserID = event.GetInt("userid");
	CreateTimer(10.0, Timer_, iUserID);
	iUserID = GetClientOfUserId(iUserID);
	PrintToChat(iUserID, "[Свобода] У вас есть 10 секунд, чтобы дать инфу.");
	UpdateListenOverride();
}

public Action Timer_(Handle hTimer, any iUserID) {
	if (!(iUserID = GetClientOfUserId(iUserID))) {
		return Plugin_Stop;
	}
	
	g_bCanVoice[iUserID] = false;
	PrintToChat(iUserID, "[Свобода] Теперь живые вас не слышат.");
	UpdateListenOverride();
	
	return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
	g_bCanVoice[client] = false;
	bAdminVoiceChat[client] = false; 
	UpdateListenOverride();
}

void UpdateListenOverride()
{
	bool bAdmin[2],
	bAlive[2];
	ListenOverride iListen = Listen_Default;
	int iSender, iReceiver;
	
	for (iSender = 1; iSender <= MaxClients; iSender++)
	{
		if (IsClientInGame(iSender)) // Есть такой говорящий
		{
			bAlive[0] = IsPlayerAlive(iSender);
			bAdmin[0] = view_as<bool>(GetUserFlagBits(iSender) & ADMFLAG_GENERIC);
			
			for (iReceiver = 1; iReceiver <= MaxClients; iReceiver++)
			{
				if (iReceiver != iSender && IsClientInGame(iReceiver))
				{
					bAlive[1] = IsPlayerAlive(iReceiver);
					bAdmin[1] = view_as<bool>(GetUserFlagBits(iReceiver) & ADMFLAG_GENERIC);
					iListen = Listen_No;
					
					// Один из собеседников - Админ, а админ слышит всех и все его слышат
					/*if (bAdmin[0] || bAdmin[1]) {
						iListen = Listen_Yes;
					} 
					else {*/
					if (bAlive[0] == bAlive[1] || g_bCanVoice[iSender]) {  // Оба игрока живы или оба мертвы , или говориящий умер и еще не прошло 10 секунд
						iListen = Listen_Yes;
					}
					else {  // Кто-то один мертв 
						iListen = Listen_No;
					}
					//}
					
					
					if (bAdminVoiceChat[iSender] && bAdmin[1]) {
						iListen = Listen_Yes;
					}
					
					
					SetListenOverride(iReceiver, iSender, iListen);
				}
			}
			
		}
	}
}




/* Admin Private Chat */

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	
	//On first E press
	if (!(g_iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE) {
		
		//Counter
		iCounter[client]++;
		if (iCounter[client] == 2)
			TriggerAdminVoiceChat(client);
		
		//Kill reset timer
		if (resetTmr[client] != null && resetTmr[client] != INVALID_HANDLE)
		{
			KillTimer(resetTmr[client]);
			resetTmr[client] = null;
		}
		resetTmr[client] = CreateTimer(0.3, ResetCounter, GetClientUserId(client));
		
		g_OnceStopped[client] = true;
	}
	
	//Still holding E
	else if (iButtons & IN_USE) {
		
	}
	
	//Stops pressing E
	else if (g_OnceStopped[client]) {
		
		//Remove message faster
		if (!bAdminVoiceChat[client])
			PrintHintText(client, " ");
		
		g_OnceStopped[client] = false;
	}
	
	g_iPlayerPrevButtons[client] = iButtons;
	
	
	//Display message
	bool ImSpeaking = false;
	bool othersSpeaking = false;
	for (int i = 1; i < MaxClients; i++)
	{
		if (bAdminVoiceChat[i] && i == client)
			ImSpeaking = true;
		
		else if (bAdminVoiceChat[i] && i != client)
			othersSpeaking = true;
	}
	
	if (ImSpeaking || (othersSpeaking && HasPermission(client, "b")))
	{
		PrintHintText(
			client, 
			"<pre><font face=''>Мой голос: \t\t<font color='#%s'>%s</font>\nДругой админ: \t<font color='#%s'>%s</font></font></pre>", 
			((ImSpeaking) ? "2CDA37" : "E30C0C"), 
			((ImSpeaking) ? "вкл" : "выкл"), 
			((othersSpeaking) ? "2CDA37" : "E30C0C"), 
			((othersSpeaking) ? "вкл" : "выкл")
			);
	}
	
	
}
 

void TriggerAdminVoiceChat(int client)
{
	if (HasPermission(client, "b"))
	{
		bAdminVoiceChat[client] = (bAdminVoiceChat[client]) ? false : true;
		
		if (bAdminVoiceChat[client]) {
			
			//Set listening flags
			for (int i = 1; i < MaxClients; i++)
			if (IsClientInGame(i))
				SetListenOverride(i, client, (HasPermission(i, "b") ? Listen_Yes : Listen_No));
			
		} else {
			
			//Set default listening flags
			for (int i = 1; i < MaxClients; i++)
			if (IsClientInGame(i))
				SetListenOverride(i, client, Listen_Default);
			
		}
	}
}

public Action ResetCounter(Handle tmr, any userID)
{
	int client = GetClientOfUserId(userID);
	if (client > 0)
	{
		iCounter[client] = 0;
		resetTmr[client] = null;
	}
}

stock bool HasPermission(int iClient, char[] flagString)
{
	if (StrEqual(flagString, ""))
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++)
		{
			if (flags & (1 << i))
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>(i)))
				{
					found++;
				}
			}
		}
		
		if (count == found) {
			return true;
		}
	}
	
	return false;
} 