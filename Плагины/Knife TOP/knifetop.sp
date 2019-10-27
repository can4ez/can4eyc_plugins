/*

Description
-----------
	KnifeTop plugin adds knife ranking to the game.
	(http://forums.alliedmods.net/showthread.php?t=91543)
	Usefull for GunGame mod.

Commands and Cvars
------------------
	sm_knifetop_enabled             - Enable plugin.
	sm_knifetop_debug               - Enable debug output to sourcemod error log file.
	sm_knifetop_version             - Plugin version.
	
	sm_knifetop_reset               - Resets knifetop stats.
	sm_knifetop_purge <days>        - Purge players who haven't connected for <days> days.
	sm_knifetop_warmup <seconds>    - Not count knife stats for <seconds> seconds.
	
	say !ktop                       - Show ingame statisctics panel with top 10 knifers.
	say !kbot                       - Show ingame statisctics panel with worst 10 knifers.
	say !kme                        - Show my statisctics.

Requirements
------------
	Counter-Strike: Source
	SourceMod 1.2.0    

Changelog
---------
	1.2.4:
		* Fixed purge to recalculate players total.
		+ Added version cvar update.

	1.2.3:
		+ Added say !kme command.
		
	1.2.2:
		* Minor fix
		
	1.2.1:
		+ Added !kbot command.
		+ Players with no knife kills/deaths are not displayed.
		
	1.2.0:
		+ Added simple AFK detection.
		
	1.1.0:
		+ Added command sm_knifetop_warmup <seconds>.
		
	1.0.1:
		* Redesigned top statistics panel.

Credits
-------
	Thanks to FrostbyteX for SoD Stats plugin 
	(http://forums.alliedmods.net/showthread.php?t=67367).
	KnifeTop is based on its source code.

	Thanks to Liam for GunGame:SM plugin
	(http://forums.alliedmods.net/showthread.php?t=80609).
	KnifeTop's afk detection is based on GunGame:SM's afk management.

TODO
----
	
Issues
------
	es_tools can't work well with sourcemod
	(http://forums.eventscripts.com/viewtopic.php?t=31096)
	
	When i writed knifetop plugin as addon to gungame for eventscripts 
	(http://forums.mattie.info/cs/forums/viewtopic.php?t=30980)
	i hooked player_death and all is work very well. But today i 
	wrote the same plugin for sourcemod. So es_tools works with 
	eventscripts just fine.

	I just issued when writing plugin for sourcemod. 
	I hooked player_death event and i found that player_death 
	event triggered two times for each player death. If i disable 
	es_tools plugin, all is ok.

	I tryed to add est_Hook_Fire 0 to es_tools.cfg, 
	but is has no effect. 

*/

#pragma semicolon 1

#include <sourcemod>
#include <morecolors>
#include "knifetop\include\knifetop.inc"

#define KNIFETOP_VERSION "1.2.4 & Edited by can4eyc | Саша Шеин  - vk.com/can4eyc"

#define MAX_STEAMID_LENGTH     128
#define MAX_WEAPON_NAME_LENGTH 32

new String:g_sql_saveplayer[]   = 
"UPDATE knifetop SET score = %i, kills = %i, deaths = %i, name = '%s', last_connect = current_timestamp WHERE steamid = '%s'";

new String:g_sql_myplace[]   = 
"SELECT COUNT(*) as count FROM knifetop WHERE (kills or deaths) and score > %i";

new String:g_sql_myRank[]   = 
"SELECT COUNT(*) as count FROM knifetop WHERE (kills or deaths) and score > %i";

new String:g_sql_createplayer[] = 
"INSERT INTO knifetop (score, kills, deaths, steamid, name, last_connect) VALUES (0, 0, 0, '%s', '%s', current_timestamp)";

new String:g_sqlite_createtable_players[] = 
"CREATE TABLE IF NOT EXISTS knifetop (id INTEGER PRIMARY KEY AUTOINCREMENT,score int(12) NOT NULL default 0,steamid varchar(255) NOT NULL default '',kills int(12) NOT NULL default 0,deaths int(12) NOT NULL default 0,name varchar(255) NOT NULL default '', last_connect timestamp NOT NULL default CURRENT_TIMESTAMP);";

new String:g_mysql_createtable_players[] = 
"CREATE TABLE IF NOT EXISTS knifetop (id INTEGER PRIMARY KEY AUTO_INCREMENT,score int(12) NOT NULL default 0,steamid varchar(255) NOT NULL default '',kills int(12) NOT NULL default 0,deaths int(12) NOT NULL default 0,name varchar(255) NOT NULL default '', last_connect timestamp NOT NULL default CURRENT_TIMESTAMP);";

new String:g_sql_droptable_players[] = 
"DROP TABLE IF EXISTS 'knifetop'; VACUUM;";

new String:g_sql_playercount[] = 
"SELECT * FROM knifetop WHERE kills OR deaths";

new String:g_name[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:g_steamid[MAXPLAYERS+1][MAX_STEAMID_LENGTH];

#define IDENT_SIZE 16
new String:g_ident[IDENT_SIZE];

#define DBTYPE_MYSQL 1
#define DBTYPE_SQLITE 2
new g_dbtype;

new g_kills[MAXPLAYERS+1];
new g_deaths[MAXPLAYERS+1];
new g_score[MAXPLAYERS+1];

new bool:g_initialized[MAXPLAYERS+1];

new g_player_count;

new Handle:g_henabled;
new Handle:g_hversion;
new g_enabled;

new Handle:g_hwarmup_timer;
new bool:g_iswarmup;

new bool:g_debug;
new Handle:g_hdebug;

new OffsetOrigin;
new Float:PlayerAfk[MAXPLAYERS + 1][3];

#include "knifetop\natives.sp"
#include "knifetop\css.sp"

#include "knifetop\commands\ktop.sp"
#include "knifetop\commands\kme.sp"
#include "knifetop\commands\krank.sp"

public Plugin:myinfo = 
{
	name = "KnifeTop",
	author = "Otstrel.ru Team",
	description = "A simple knife stats and ranking system.",
	version = KNIFETOP_VERSION,
	url = "http://otstrel.ru"
}

public OnPluginStart()
{
	g_hwarmup_timer = INVALID_HANDLE;

	decl String:error[256];
	stats_db = SQL_Connect("storage-local", false, error, sizeof(error));
	
	if(stats_db == INVALID_HANDLE)
	{
		LogError("[KnifeTop] Unable to connect to database (%s)", error);
		return;
	}
	
	SQL_ReadDriver(stats_db, g_ident, IDENT_SIZE);
	if(strcmp(g_ident, "mysql", false) == 0)
	{
		g_dbtype = DBTYPE_MYSQL;
	}
	else if(strcmp(g_ident, "sqlite", false) == 0)
	{
		g_dbtype = DBTYPE_SQLITE;
	}
	else
	{
		LogError("[KnifeTop] Invalid DB-Type");
		return;
	}
	
	SQL_LockDatabase(stats_db);
	
	if((g_dbtype == DBTYPE_MYSQL && !SQL_FastQuery(stats_db, g_mysql_createtable_players)) ||
			(g_dbtype == DBTYPE_SQLITE && !SQL_FastQuery(stats_db, g_sqlite_createtable_players)))
	{
		LogError("[KnifeTop] Could not create players table.");
		return;
	}

	g_player_count = GetPlayerCount();
	SQL_UnlockDatabase(stats_db);
	
	g_henabled = CreateConVar("sm_knifetop_enabled", "1", "Устанавливает, следует ли записывать статистику",FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hdebug = CreateConVar("sm_knifetop_debug", "0", "Включите вывод отладки в файл журнала ошибок sourcemod.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hversion = CreateConVar("sm_knifetop_version", KNIFETOP_VERSION,"KnifeTop version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// KLUGE: Update version cvar if plugin updated on map change.
	SetConVarString(g_hversion, KNIFETOP_VERSION);
	
	HookConVarChange(g_henabled, EnabledCallback);
	HookConVarChange(g_hdebug, DebugCallback);
	g_enabled = GetConVarInt(g_henabled);
	g_debug = !!GetConVarInt(g_hdebug);
	
	if(g_henabled == INVALID_HANDLE || g_hversion == INVALID_HANDLE || g_hdebug == INVALID_HANDLE)
	{
		LogError("[KnifeTop] Could not create knifetop cvar.");
		return;
	}
	
	HookEvents();
	
	RegAdminCmd("sm_knifetop_reset", AdminCmd_ResetStats, ADMFLAG_CONFIG, "Сбрасывает статистику ножа.");
	RegAdminCmd("sm_knifetop_purge", AdminCmd_Purge, ADMFLAG_CONFIG, "sm_knifetop_purge [days] - Очистка игроков, которые не подключались в течение [дней] дней.");
	RegAdminCmd("sm_knifetop_warmup", AdminCmd_Warmup, ADMFLAG_CONFIG, "sm_knifetop_warmup [seconds] - Не считать статистику ножа в течение [секунд] секунд.");
	RegConsoleCmd("say",      ConCmd_Say);
	RegConsoleCmd("say_team", ConCmd_Say);
	
	RegPluginLibrary("knifetop");

	new String:steamid[MAX_STEAMID_LENGTH];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientAuthorized(client))
		{
			GetClientAuthString(client, steamid, MAX_STEAMID_LENGTH);
			OnClientAuthorized(client, steamid);
		}
	}
	
	OffsetOrigin = FindSendPropOffs("CBaseEntity", "m_vecOrigin");

	if(OffsetOrigin == -1)
	{
		decl String:Error[128];
		FormatEx(Error, sizeof(Error), "FATAL ERROR OffsetOrigin [%d]", OffsetOrigin);
		SetFailState(Error);
	}
}

HookEvents()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_CSS_PlayerDeath);
}

UnhookEvents()
{
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("player_death", Event_CSS_PlayerDeath);
}

public OnClientDisconnect(userid)
{
	// Ignore bot disconnects
	if(g_initialized[userid] == true)
	{
		// Save the player stats
		SavePlayer(userid);
		// and uninitialize them
		g_initialized[userid] = false;
		Trace("Client disconnected...");
		Trace(g_steamid[userid]);
	}
}

public OnClientAuthorized(client, const String:steamid[])
{
	//new client = GetClientOfUserId(userid);
	// Don't load bot stats or initialize them
	if(!IsFakeClient(client))
	{
		Format(g_steamid[client], MAX_STEAMID_LENGTH, steamid);
		GetClientName(client, g_name[client], MAX_NAME_LENGTH);
		GetPlayerBySteamId(steamid, LoadPlayerCallback, client);
		Trace("Client authorized...");
		Trace(g_steamid[client]);
	}
}

public EnabledCallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( strcmp(newValue, "0") == 0 )
	{
		if ( g_enabled == 1 )
		{
			g_enabled = 0;
			UnhookEvents();
		}
	}
	else if ( g_enabled == 0 )
	{
		g_enabled = 1;
		HookEvents();
	}
}

public DebugCallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( strcmp(newValue, "0") == 0 )
	{
		g_debug = false;
	}
	else
	{
		g_debug = true;
	}
}

public Action:ConCmd_Say(userid, args)
{
	if(!userid || g_enabled == 0)
	return Plugin_Continue;
	
	decl String:text[192];      // from rockthevote.sp
	if(!GetCmdArgString(text, sizeof(text)))
	return Plugin_Continue;
	
	new startidx = 0;
	
	// Strip quotes from argument
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if( strcmp(text[startidx], "!ktop", false) == 0 || strcmp(text[startidx], "ktop", false) == 0)
	{
		PrintTop(userid);
	return Plugin_Continue;
	}

	if(strcmp(text[startidx], "!kbot", false) == 0 || strcmp(text[startidx], "kbot", false) == 0)
	{
		new start = 0;
		if ( g_player_count < 11 )
		{
			start = 1;
		}
		else
		{
			start = g_player_count - 9;
		}
		PrintTop(userid, start);
	return Plugin_Continue;
	}
	
	if(strcmp(text[startidx], "!kme", false) == 0 || strcmp(text[startidx], "kme", false) == 0)
	{
		PrintMyPlace(userid);
	return Plugin_Continue;
	}
	
	if(strcmp(text[startidx], "!krank", false) == 0 || strcmp(text[startidx], "krank", false) == 0)
	{
		PrintMyRank(userid);
	return Plugin_Continue;
	}

	return Plugin_Continue;
}

public LoadPlayerCallback(const String:name[], const String:steamid[], any:stats[], any:data, error)
{
	new client = data;
	
	if(error == ERROR_PLAYER_NOT_FOUND)
	{
		CreatePlayer(client, g_steamid[client]);
		return;
	}
	
	Format(g_name[client], MAX_NAME_LENGTH, name);
	g_kills[client]       = stats[STAT_KILLS];
	g_deaths[client]      = stats[STAT_DEATHS];
	g_score[client]       = stats[STAT_SCORE];
	
	g_initialized[client] = true;
}

public Action:AdminCmd_ResetStats(client, args)
{
	ResetStats();
	
	return Plugin_Handled;
}

public Action:AdminCmd_Purge(client, args)
{
	Trace("Purge command");
	new argCount = GetCmdArgs();
	
	if(argCount != 1)
	{
		PrintToConsole(client, "KnifeTop: Недопустимое количество аргументов для команды 'sm_knifetop_purge'");
		return Plugin_Handled;
	}
	
	decl String:svDays[192];
	if(!GetCmdArg(1, svDays, 192))
	{
		PrintToConsole(client, "KnifeTop: Недопустимый аргумент для команды sm_knifetop_purge.");
		return Plugin_Handled;
	}
	
	new days = StringToInt(svDays);
	if(days <= 0)
	{
		PrintToConsole(client, "KnifeTop: Недопустимое количество дней.");
		return Plugin_Handled;
	}

	decl String:query[128];
	
	
	switch(g_dbtype)
	{
	case DBTYPE_MYSQL: 
		Format(query, 128, "DELETE FROM knifetop WHERE last_connect < current_timestamp - interval %i day;", days);
	case DBTYPE_SQLITE: 
		Format(query, 128, "DELETE FROM knifetop WHERE last_connect < datetime('now', '-%i days');", days);
	}
	
	SQL_TQuery(stats_db, SQL_PurgeCallback, query, client);
	
	return Plugin_Handled;
}

public Action:AdminCmd_Warmup(client, args)
{
	Trace("Warmup command");
	new argCount = GetCmdArgs();
	
	if(argCount != 1)
	{
		PrintToConsole(client, "KnifeTop: Недопустимое количество аргументов для команды 'sm_knifetop_warmup'");
		return Plugin_Handled;
	}
	
	decl String:svSeconds[192];
	if(!GetCmdArg(1, svSeconds, 192))
	{
		PrintToConsole(client, "KnifeTop: Недопустимые аргументы для sm_knifetop_warmup.");
		return Plugin_Handled;
	}
	
	new Float:seconds = StringToFloat(svSeconds);
	
	if ( g_hwarmup_timer && ( g_hwarmup_timer != INVALID_HANDLE) )
	{
		CloseHandle(g_hwarmup_timer);
		g_hwarmup_timer = INVALID_HANDLE;
	}        

	if(seconds <= 0)
	{
		g_iswarmup = false;
		PrintToConsole(client, "KnifeTop: Разминка отключена.");
		return Plugin_Handled;
	}
	else
	{
		g_iswarmup = true;
		g_hwarmup_timer = CreateTimer(seconds, Timer_DisableWarmup); 
		PrintToConsole(client, "KnifeTop: Разминка включена в %.0f секунд.", seconds);
		return Plugin_Handled;
	}    
}

public Action:Timer_DisableWarmup(Handle:timer)
{
	Trace("Warmup timer closed");
	g_hwarmup_timer = INVALID_HANDLE;
	g_iswarmup = false;
}

public SQL_PurgeCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	Trace("Purge callback");
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL_PurgeCallback: Invalid query (%s).", error);
	}
	else
	{
		PrintToConsole(data, "KnifeTop: Purge successful");
	}
	g_player_count = GetPlayerCount();
}

GetPlayerCount()
{
	new Handle:hquery = SQL_Query(stats_db, g_sql_playercount);
	if(hquery == INVALID_HANDLE)
	{
		LogError("[KnifeTop] Error getting player count.");
		return 0;
	}
	new rows = SQL_GetRowCount(hquery);
	CloseHandle(hquery);
	
	return rows;
}

SavePlayer(const userid)
{
	Trace("Saving player...");
	Trace(g_steamid[userid]);
	if(stats_db == INVALID_HANDLE || g_enabled == 0)
	return false;
	
	GetClientName(userid, g_name[userid], MAX_NAME_LENGTH);
	
	// Make SQL-safe
	new String:safe_name[MAX_NAME_LENGTH];
	SQL_QuoteString(stats_db, g_name[userid], safe_name, sizeof(safe_name));
	
	// save player here
	decl String:query[255];
	Format(query, sizeof(query), g_sql_saveplayer, g_score[userid], 
	g_kills[userid],
	g_deaths[userid], 
	safe_name, 
	g_steamid[userid]);
	SQL_TQuery(stats_db, SQL_SavePlayerCallback, query);
	Trace("Player saved");
	return 0;
}

public SQL_SavePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	LogError("[KnifeTop] Error saving player (%s)", error);
}

CreatePlayer(const userid, const String:steamid[])
{
	decl String:query[255];
	new String:safe_name[MAX_NAME_LENGTH];
	
	SQL_QuoteString(stats_db, g_name[userid], safe_name, sizeof(safe_name));
	Format(query, sizeof(query), g_sql_createplayer, steamid, safe_name);

	SQL_TQuery(stats_db, SQL_CreatePlayerCallback, query, userid);
}

public SQL_CreatePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;
	
	if(hndl != INVALID_HANDLE)
	{
		g_kills[client]       = 0;
		g_deaths[client]      = 0;
		g_score[client]       = 0;
		
		g_initialized[client] = true;
	}
	else
	LogError("[KnifeTop] SQL_CreatePlayerCallback failure: %s", error);
}

public Trace(const String:text[])
{
	if (g_debug)
	{
		LogError("[DEBUG] %s", text);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!client || IsFakeClient(client))
	{
		return;
	}

	GetEntDataVector(client, OffsetOrigin, PlayerAfk[client]);
}

public isPlayerAfk(client)
{
	decl Float:Origin[3];
	GetEntDataVector(client, OffsetOrigin, Origin);

	return PlayerAfk[client][0] == Origin[0] && PlayerAfk[client][1] == Origin[1];
}
