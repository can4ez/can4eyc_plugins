 // File:   ktop.sp
// Author: Otstrel.ru Team

#include "knifetop\include\knifetop.inc"
int g_iTemp[MAXPLAYERS + 1];
PrintTop(client, start = 1, offset = 5)
{
	new String:header[128];
	new Handle:panel = CreatePanel();
	
	if (start <= 0)
	{
		g_iTemp[client] = 0;
		if (offset > g_player_count)
		{
			offset = g_player_count;
		}
		Format(header, 128, "-Ножевой ТОП- Всего игроков %i", g_player_count);
	}
	else
	{
		Format(header, 128, "-Ножевой ТОП- Всего игроков %i", g_player_count);
	}
	DrawPanelText(panel, header);
	DrawPanelText(panel, "---------------------------------");
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, any:panel);
	WritePackCell(pack, client);
	WritePackCell(pack, g_iTemp[client] * offset); 
	KnifeTop_GetTopPlayers(g_iTemp[client] * offset, offset, TopCallback, any:pack);
}

public TopCallback(const String:name[], const String:steamid[], any:stats[], any:data, index)
{
	new Handle:pack = data;
	ResetPack(pack);
	new Handle:panel = Handle:ReadPackCell(pack);
	new client = ReadPackCell(pack);
	new start = ReadPackCell(pack);
	static bLast = false;
	
	if (steamid[0] == 0) // last call
	{
		if (!g_player_count)
		{
			DrawPanelText(panel, "Игроки не найдены");
		}
		
		DrawPanelText(panel, "---------------------------------");
		DrawPanelItem(panel, "Назад", (start > 0) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		DrawPanelItem(panel, "Далее", (bLast) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		DrawPanelItem(panel, "Выход");
		
		CloseHandle(pack);
		SendPanelToClient(panel, client, TopHandler, 10);
		CloseHandle(panel);
	}
	else
	{
		decl String:text[256];
		strcopy(text, sizeof(text), (name[0] == '\0') ? "unnamed" : name);
		bLast = (start + index >= g_player_count);
		
		Format(text, sizeof(text), "%i. %s: - У(%i) / С(%i) ", 
			start + index, 
			text, 
			stats[STAT_KILLS], 
			stats[STAT_DEATHS]
			);
		DrawPanelText(panel, text); 
	}
}

public TopHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (param2 == 1) {
		PrintTop(param1, --g_iTemp[param1], 5);
	} else if (param2 == 2) {
		PrintTop(param1, ++g_iTemp[param1], 5);
	} else {
		g_iTemp[param1] = 0;
	}
}
