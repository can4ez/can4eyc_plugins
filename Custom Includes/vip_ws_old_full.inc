#if defined _wS_vip_included
	#endinput
#endif
#define _wS_vip_included

new const MAX_ITEMINFO_LENGTH = 100;

enum eServerType
{
	ST_Unknown = 0,
	ST_v34,
	ST_v75orHigher,
	ST_CSGO
}

// Авторизован ли игрок (forward VIP_OnClientAuthorized)
native bool:VIP_IsClientAuthorized(client);

// Есть ли VIP доступ
native bool:VIP_IsVipPlayer(client);

// Возвращает время VIP доступа в секундах, или:
// -2 нет vip доступа
// -1 постоянный
native VIP_GetAccessSeconds(client);

// Получить имя группы VIP игрока (делать VIP_IsVipPlayer не нужно, maxlength 50)
native bool:VIP_GetGroupName(client, String:buffer[], maxlength);

// Существует ли VIP группа
native bool:VIP_IsValidGroup(const String:GroupName[]);

// Открыть VIP меню
native VIP_ShowMenu(client);

/**
 * Создать VIP функцию (опцию в !vip меню)
 *
 * ItemName			- уникальное имя, например "hp"
 *                    используется для перевода, поэтому пропишите его в vip.phrases.txt
 * toggle			- если true,  то нажимая на опцию, игрок будет вкл/откл функцию
 * selectable		- если false, то опция белая (нельзя нажать)
 *
 * Возвращает ItemID
 * Если < 1, то не удалось создать
**/
native VIP_RegisterItem(const String:ItemName[], bool:toggle, bool:selectable);

/**
 * Удалить VIP функцию из !vip меню
**/
native VIP_UnRegisterItem(const String:ItemName[]);

/**
 * Например, если было VIP_RegisterItem("hp" ..
 * А в VIP группе прописано hp: 150
 * То функция вернет true и в ItemInfo будет "150"
 * Если вернет false, то у игрока нет доступа к функции
**/
native bool:VIP_GetClientItemInfo(client, const String:ItemName[], String:ItemInfo[]);

// Берет значение из кэша
// Статус функции, включена (true) или отключена (false)
// Если true, то это не значит, что у игрока есть доступ к функции, используйте VIP_GetClientItemInfo
native bool:VIP_GetItemToggledStatus(client, const String:ItemName[]);

// Возвращает Handle:kv (KeyValues), в котором хранятся личные настройки игрока (перед возвращением делается KvRewind)
// Или INVALID_HANDLE
native Handle:VIP_GetClientCacheHandle(client);

// Вернет true, если функция отключена на текущей карте (sm_vipdisable)
native bool:VIP_ItemDisabled(const String:ItemName[]);

// Версия сервера
native eServerType:VIP_GetServerType();


///


/**
 * Игрок авторизовался (не бот)
 *
 * vip				- true, сли это VIP игрок
 * group			- группа VIP игрока, или "", если это не VIP
**/
forward VIP_OnClientAuthorized(client, const String:steamid[], bool:vip, const String:group[]);

/**
 * Игрок лишился VIP доступа
 *
 * client			- индекс игрока (если < 1, то не на сервере)
 * steamid			- стим вип игрока (будет верным всегда)
 * reason			- причина: "time is up", "admin: server", "admin: wS, STEAM_0:0:17233444"
**/
forward VIP_OnRemoved(client, const String:steamid[], const String:reason[]);

/**
 * Игрок получил VIP доступ
 *
 * client			- индекс игрока (если < 1, то успел покинуть сервер, wtf)
 * steamid			- стим вип игрока (будет верным всегда)
 * group			- вип группа игрока
 * min				- на сколько минут получил VIP (0 = навсегда)
 * admin_steamid	- стим админа или "server"
**/
forward VIP_OnAdded(client, const String:steamid[], const String:group[], min, const String:admin_steamid[]);

/**
 * Группа VIP игрока изменена
 *
 * client			- индекс вип игрока (будет верным всегда)
 * steamid			- стим вип игрока (будет верным всегда)
 * OldGroup			- в какой группе был
 * NewGroup			- в какой теперь
**/
forward VIP_OnGroupChanged(client, const String:steamid[], const String:OldGroup[], const String:NewGroup[]);

/**
 * Игрок успешно использовал ключ
**/
forward VIP_OnKeyWasUsed(client, const String:steamid[], const String:key[]);

/**
 * VIP игрок включил/отключил функцию через меню (VIP_OnVipItemPressed не вызывается)
 *
 * enabled			- если true, то включил
 * ItemName			- уникальное имя, например "hp"
 * ItemInfo			- если в VIP группе было прописано hp: 150, то это "150"
**/
forward VIP_OnVipItemToggled(client, ItemID, const String:ItemName[], const String:ItemInfo[], bool:enabled);

/**
 * VIP игрок выбрал опцию в меню (VIP_OnVipItemToggled не вызывается)
**/
forward VIP_OnVipItemPressed(client, ItemID, const String:ItemName[], const String:ItemInfo[]);

/**
 * Игрок родился (он точно жив и team > 1)
**/
forward VIP_OnPlayerSpawn(client, team, bool:bot, bool:vip, const String:steamid[], const String:group[]);
