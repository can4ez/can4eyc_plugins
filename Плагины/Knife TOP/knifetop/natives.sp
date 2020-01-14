/* Plugin Template generated by Pawn Studio */

new String:g_sql_loadplayer[] = 
"SELECT name, steamid, score, kills, deaths FROM knifetop WHERE steamid = '%s'";

new String:g_sql_top[] = 
"SELECT name, steamid, score, kills, deaths FROM knifetop WHERE (kills OR deaths) AND (name != '') ORDER BY score DESC LIMIT %i OFFSET %i";

public Native_KnifeTop_GetTopPlayers(Handle:plugin, numParams)
{
	new rank = GetNativeCell(1);
	new count = GetNativeCell(2);
	new StatsCallback:callback = GetNativeCell(3);
	new any:data = GetNativeCell(4);
	
	DataPack pack = new DataPack();
	
	pack.WriteFunction(callback);
	pack.WriteCell(data);
	
	new String:query[192];
	
	Format(query, sizeof(query), g_sql_top, count, rank); 
	SQL_TQuery(stats_db, SQL_TopCallback, query, pack);
}

public SQL_TopCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	DataPack pack = data;
	ResetPack(pack);
	new StatsCallback:callback = view_as<StatsCallback>(pack.ReadFunction());
	new any:args = ReadPackCell(pack);
	CloseHandle(pack);
	
	decl String:name[MAX_NAME_LENGTH];
	decl String:steamid[MAX_STEAMID_LENGTH];
	
	new stats[MAX_STATS];
	new index = 0;
	
	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			index++;
			SQL_FetchString(hndl, 0, name, sizeof(name));
			SQL_FetchString(hndl, 1, steamid, sizeof(steamid));
			stats[STAT_SCORE] = SQL_FetchInt(hndl, 2);
			stats[STAT_KILLS] = SQL_FetchInt(hndl, 3);
			stats[STAT_DEATHS] = SQL_FetchInt(hndl, 4);
			
			CallStatsCallback(name, steamid, stats, callback, args, index);
		}
	}
	CallStatsCallback("", "", stats, callback, args, 0);
}

public SQL_LoadPlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	DataPack pack = data;
	ResetPack(pack);
	new StatsCallback:callback = view_as<StatsCallback>(pack.ReadFunction());
	new any:args = ReadPackCell(pack);
	CloseHandle(pack);
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("[KnifeTop] SQL_LoadPlayerCallback failure: %s", error);
		return;
	}
	
	new stats[MAX_STATS];
	new String:name[MAX_NAME_LENGTH];
	new String:steamid[MAX_STEAMID_LENGTH];
	new callback_error = ERROR_PLAYER_NOT_FOUND;
	
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, name, sizeof(name));
		SQL_FetchString(hndl, 1, steamid, sizeof(steamid));
		stats[STAT_SCORE] = SQL_FetchInt(hndl, 2);
		stats[STAT_KILLS] = SQL_FetchInt(hndl, 3);
		stats[STAT_DEATHS] = SQL_FetchInt(hndl, 4);
		callback_error = 0;
	}
	
	CallStatsCallback(name, steamid, stats, callback, args, callback_error);
}

ResetStats()
{
	if (stats_db == INVALID_HANDLE)
	{
		LogError("[KnifeTop] Error: Invalid database handle");
		return;
	}
	
	SQL_LockDatabase(stats_db);
	
	SQL_FastQuery(stats_db, g_sql_droptable_players);
	switch (g_dbtype)
	{
		case DBTYPE_MYSQL:
		SQL_FastQuery(stats_db, g_mysql_createtable_players);
		case DBTYPE_SQLITE:
		SQL_FastQuery(stats_db, g_sqlite_createtable_players);
	}
	
	g_player_count = 0;
	
	SQL_UnlockDatabase(stats_db);
	
	new max_clients = MAXPLAYERS + 1;
	
	for (new i = 1; i < max_clients; i++)
	{
		if (g_initialized[i])
		{
			g_kills[i] = 0;
			g_deaths[i] = 0;
			g_score[i] = 0;
			
			CreatePlayer(i, g_steamid[i]);
		}
	}
}

CallStatsCallback(const String:name[], const String:steamid[], stats[], StatsCallback:callback, any:data, retval)
{
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushString(name);
	Call_PushString(steamid);
	Call_PushArray(stats, MAX_STATS);
	Call_PushCell(data);
	Call_PushCell(retval);
	Call_Finish();
}

GetPlayerBySteamId(const String:steamid[], StatsCallback:callback, any:data)
{
	new String:query[192];
	
	DataPack pack = new DataPack();
	
	pack.WriteFunction(callback);
	pack.WriteCell(data);
	
	Format(query, sizeof(query), g_sql_loadplayer, steamid);
	SQL_TQuery(stats_db, SQL_LoadPlayerCallback, query, pack);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[])
{
	CreateNative("KnifeTop_GetTopPlayers", Native_KnifeTop_GetTopPlayers);
	
	return APLRes_Success;
}
