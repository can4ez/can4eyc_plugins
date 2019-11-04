#include "knifetop\include\knifetop.inc"

new g_Rank[MAXPLAYERS+1];

PrintMyRank(client)
{
	GetPlayerRank(client, GetPlayerRankCallback);
}

public GetPlayerRank(client, StatsCallback:callback)
{
	DataPack pack = new DataPack();
	pack.WriteFunction(callback);
	pack.WriteCell(client);
	
	new String:query[192];    
	Format(query, sizeof(query), g_sql_myRank, g_score[client]);
	SQL_TQuery(stats_db, SQL_MyRankCallback, query, pack);
}

public SQL_MyRankCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	DataPack pack = data;
	ResetPack(pack);
	new StatsCallback:callback = view_as<StatsCallback>(pack.ReadFunction());
	new client = ReadPackCell(pack);
	CloseHandle(pack);

	if(hndl == INVALID_HANDLE)
	{
		g_Rank[client] = 0;
		return;
	}
    
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_Rank[client] = SQL_FetchInt(hndl, 0) + 1;
	}

	new stats[MAX_STATS];
	CallStatsCallback("", "", stats, callback, client, 0);
}
public GetPlayerRankCallback(const String:name[], const String:steamid[], any:stats[], any:data, error)
{ 
	new client = data;
	CPrintToChat(client, "{DeepSkyBlue}[Название сервера]{GREEN} Ваша позиция в {ivory}ТОП {Aqua} [%i] {GREEN}из {Aqua}[%i]", g_Rank[client], g_player_count);
}