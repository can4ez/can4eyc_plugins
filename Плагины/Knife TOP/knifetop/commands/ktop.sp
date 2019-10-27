// File:   ktop.sp
// Author: Otstrel.ru Team

#include "knifetop\include\knifetop.inc"

PrintTop(client, start = 1, offset = 10)
{
	new String:header[128];
	new Handle:panel = CreatePanel();
	if (start == 1)
	{
		if ( offset > g_player_count )
		{
			offset = g_player_count;
		}
		Format(header, 128, "KnifeTop: Топ %i из %i игроков", offset, g_player_count);
	}
	else
	{
		Format(header, 128, "KnifeTop: Худший %i из %i игроков", offset, g_player_count);
	}
	DrawPanelText(panel, header);
	DrawPanelText(panel, "---------------------------------");
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, any:panel);
	WritePackCell(pack, client);
	WritePackCell(pack, start);
	KnifeTop_GetTopPlayers(start, offset, TopCallback, any:pack);
}

public TopCallback(const String:name[], const String:steamid[], any:stats[], any:data, index)
{
    new Handle:pack = data;
    ResetPack(pack);
    new Handle:panel = Handle:ReadPackCell(pack);
    new client       = ReadPackCell(pack);
    new start        = ReadPackCell(pack);
    
    if(steamid[0] == 0) // last call
    {
        if ( !g_player_count )
        {
            DrawPanelText(panel, "Игроки не найдены");
        }
        DrawPanelText(panel, "---------------------------------");
        if ( (start == 1) && g_player_count )
        {
            DrawPanelText(panel, "1. Выход");
        }
        else
        {
            DrawPanelItem(panel, "Выход");
        }
        CloseHandle(pack);
        SendPanelToClient(panel, client, TopHandler, 10);
        CloseHandle(panel);
    }
    else
    {
        decl String:text[256];
        if ( (start != 1) || (index > 3) )
        {
            Format(text, sizeof(text), "%i. %s: %i (%i/%i) ", 
                                       start - 1 + index,
                                       name, 
                                       stats[STAT_SCORE],
                                       stats[STAT_KILLS],
                                       stats[STAT_DEATHS]
                                       );
            DrawPanelText(panel, text);
        }
        else
        {
            Format(text, sizeof(text), "%s: %i (%i/%i) ", 
                                       name, 
                                       stats[STAT_SCORE],
                                       stats[STAT_KILLS],
                                       stats[STAT_DEATHS]
                                       );
            DrawPanelItem(panel, text);
        }
    }
}

public TopHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
