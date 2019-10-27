// File:   kme.sp
// Author: Otstrel.ru Team

#include "knifetop\include\knifetop.inc"

new g_place[MAXPLAYERS+1];

PrintMyPlace(client)
{
	GetPlayerPlace(client, GetPlayerPlaceCallback);
}

public GetPlayerPlace(client, StatsCallback:callback)
{
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, _:callback);
	WritePackCell(pack, client);
	
	new String:query[192];    
	Format(query, sizeof(query), g_sql_myplace, g_score[client]);
	SQL_TQuery(stats_db, SQL_MyPlaceCallback, query, pack);
}

public SQL_MyPlaceCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new Handle:pack = data;
	ResetPack(pack);
	new StatsCallback:callback = StatsCallback:ReadPackCell(pack);
	new client = ReadPackCell(pack);
	CloseHandle(pack);

	if(hndl == INVALID_HANDLE)
	{
		g_place[client] = 0;
		return;
	}
    
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_place[client] = SQL_FetchInt(hndl, 0) + 1;
	}

	new stats[MAX_STATS];
	CallStatsCallback("", "", stats, callback, client, 0);
}
public GetPlayerPlaceCallback(const String:name[], const String:steamid[], any:stats[], any:data, error)
{
	new client = data;
	new Handle:panel = CreatePanel();
	DrawPanelText(panel, "KnifeTop: My statistics");
	DrawPanelText(panel, "---------------------------------");
	new String:text[256];
	if ( g_kills[client] || g_deaths[client] )
	{
		Format(text, sizeof(text), "%s: %i (%i/%i) ", 
								   g_name[client], 
								   g_score[client],
								   g_kills[client],
								   g_deaths[client]
								   );
		DrawPanelText(panel, text);
		Format(text, sizeof(text), "Your place: %i of %i.", g_place[client], g_player_count);
		DrawPanelText(panel, text);
	}
	else
	{
		DrawPanelText(panel, "You have not ranked yet.");
		Format(text, sizeof(text), "Total players ranked: %i.", g_player_count);
		DrawPanelText(panel, text);
	}
	DrawPanelText(panel, "---------------------------------");
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, MyPlaceHandler, 10);
	CloseHandle(panel);
}

public MyPlaceHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
