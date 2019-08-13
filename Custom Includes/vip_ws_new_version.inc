#if defined _wS_vip_included
	#endinput
#endif
#define _wS_vip_included

// Инструкция по созданию модулей:
// http://world-source.ru/forum/141-4848-1

#define STEAMID_LENGTH				32
#define GROUP_LENGTH				40
#define ITEM_NAME_LENGTH			40	// ItemName 'speed'
#define ITEM_INFO_LENGTH			100	// ItemValue '0.5'
#define DESCRIPTION_LENGTH			320 // public bool:VIP_Description

#define PLAY_SELECT_SOUND(%0)		ClientCommand(%0, "playgamesound buttons/button14.wav")
#define PLAY_EXIT_SOUND(%0)			ClientCommand(%0, "playgamesound buttons/combine_button7.wav")
#define PLAY_EXIT_BACK_SOUND(%0)	ClientCommand(%0, "playgamesound buttons/combine_button7.wav")
#define PLAY_WARNING_SOUND(%0)		ClientCommand(%0, "playgamesound resource/warning.wav")

//

// Используется в 'public VipGiveAction:VIP_GiveAccess'
#define CURRENT_ACCESS_NO			0 // У игрока нет фактического доступа к функции (возможно это авто-выдача доступа по флагу -> settings.txt -> "_ACCESS_BY_FLAG")
#define CURRENT_ACCESS_YES			1 // Фактический доступ есть
#define CURRENT_ACCESS_YES_GROUP	2 // Фактический доступ есть + это VIP игрок и у его VIP группы тоже есть доступ

enum VipGiveAction
{
	VGA_Continue = 0,		// Разрешить/продолжить нормальное выполнение
	VGA_Stop,				// Запретить (без причины)
	VGA_ValueNotSpecified,	// Запретить (значение не указано)
	VGA_BadValue,			// Запретить (значение указано неверно)
	VGA_SameValue,			// Запретить (значение равно тому, что сейчас у игрока)
	VGA_AlreadyEnabled,		// Запретить (функция уже включена)
	VGA_Paused				// Запретить (игрок отключил функцию и мы не хотим принудительно её включать) - в некоторых случаях, чтобы это обойти, нужно указать любое [ItemValue].
};

//

enum VIP_EVENT
{
	VE_Authorized = 0,		// public CallBack(client, const String:steamid[], bool:vip);
	VE_Spawn,				// public CallBack(client, team);
	VE_Added,				// public CallBack(client, const String:steamid[], const String:group[], min, const String:admin[]);
	VE_Removed,				// public CallBack(client, const String:steamid[], const String:reason[]); "time is up", "server", "wS, STEAM_0:0:xxxxxxx"
	VE_GroupChanged,		// public CallBack(client, const String:steamid[], const String:OldGroup[], const String:NewGroup[]);
	VE_KeyActivated,		// public CallBack(client, const String:steamid[], const String:key[], const String:group[], min, const String:cmd[], bool:TimeChanged, bool:GroupChanged);
	VE_Sql,					// public CallBack(Handle:hSQL);			- INVALID_HANDLE = соединение разорвано, иначе восстановлено.
	VE_FreeTime,			// public CallBack(bool:started);			- бесплатный VIP в определённое время суток
	VE_FreeGive,			// public Action:CallBack(client);			- игрок получает бесплатный VIP (Plugin_Stop или Plugin_Handled = запретить)
	VE_HolidayPre,			// public Action:CallBack(client, &min);	- игрок берёт отпуск (если min укажете < 1, будет изменено на 1)
	VE_HolidayPost,			// public CallBack(client, min);			- взял отпуск
	VE_HolidayEnd,			// public CallBack(client, sec);			- отпуск завершён/отменён (sec = сколько секунд он длился)
	VE_ItemStatusChanged,	// public CallBack(client, const String:ItemName[], bool:enabled, const String:ItemValue[]); - enabled true = функция включена/изменена (выбрал другой скин например), false = отключена. ItemValue = установленное значение (TrimString уже сделано).
	VE_ModuleLoaded,		// public bool:CallBack(ItemID, const String:ItemName[]); - VIP зарегистрировал модуль (VIP_RegisterItem). return false = принудительно ставится флаг VIP_ITEM_MAPDISABLED). return true = если нет флага VIP_ITEM_MAPDISABLED, то функция сразу же включается у всех игроков, у которых есть доступ.
	VE_ModuleUnloaded		// public CallBack(ItemID, const String:ItemName[]); - Модуль выгружен (VIP_UnRegisterItem или unload/краш)
};

native VIP_HookEvent(VIP_EVENT:event, Function:CallBack);

//

/**
 * Если функция была отключена/включена/изменена, то можно (в конце, после всех действий) отправить уведомление для VE_ItemStatusChanged.
 * ItemValue полезен при bool:enabled true, чтобы могли узнать установленное игроку значение.
 * Например, админ сменил игроку скорость на 0.3, вот в ItemValue мы и передадим "0.3".
 * После отправки уведомления, VE_ItemStatusChanged будет вызван через 0.1 сек.
 **/
native VIP_NotifyItemStatusChanged(client, const String:ItemName[], bool:enabled, const String:ItemValue[] = "", ItemValueSize = 0);

//

#define VCF_AUTHORIZED			(1 << 0)	// Проверки доступа завершены (авторизован) 'if (VIP_GetFlags(client) & VCF_AUTHORIZED)'
#define VCF_VIP					(1 << 1)	// VIP игрок находится в SQL базе или он VCF_VIPFREE/VCF_VIPTEMPORARY.
#define VCF_VIPFREE				(1 << 2)	// VIP права выданы функцией 'бесплатный VIP в определенное время' (VE_FreeTime, VE_FreeGive) (вместе с этим флагом игроку ставится и VCF_VIPTEMPORARY)
#define VCF_VIPTEMPORARY		(1 << 3)	// VIP права выданы функцией VIP_SetTemporaryGroup (возможно игрок прописан в vips.txt)
#define VCF_VIPPAUSE			(1 << 4)	// Игрок воспользовался функцией "Отключить всё (перезаход = вкл)", при этом у него забирается флаг VCF_AUTHORIZED.
#define VCF_CHATHOOK			(1 << 5)	// Игрок (скорее всего админ) должен ввести какое-то значение в чат и сообщение будет заблокировано.
#define VCF_MENUAUTOOPEN		(1 << 6)	// Меню отправляется игроку снова и снова (TIMER_REPEAT), пока он его не покинет.
#define VCF_SAVECACHE			(1 << 7)	// Личные настройки игрока (cfg/vip/cache/) должны быть сохранены при выходе.
#define VCF_HOLIDAY				(1 << 8)	// В отпуске (при этом у него есть флаг VCF_AUTHORIZED).
#define VCF_VIPTEST				(1 << 9)	// VIP права получены через функцию sm_viptest
#define VCF_VIPBYFLAG			(1 << 10)	// Есть функции, доступ к которым был получен по флагу.
#define VCF_VIPMENUACCESS		(1 << 11)	// Есть ли доступ к какой-либо функции. Если есть, то она доступна игроку в !vip меню (неважно VIP он или нет).

native VIP_GetFlags(client);

//

#define VIP_ITEM_TOGGLE			(1 << 0)	// Игрок может вкл/откл функцию. Вызываются VIP_GiveAccess/VIP_TakeAccess
#define VIP_ITEM_SELECT			(1 << 1)	// При нажатии вызывается VIP_MenuSelect (полезно, если нужно показать игроку своё меню)
#define VIP_ITEM_DISABLED		(1 << 2)	// Это ITEMDRAW_DISABLED - белая некликабельная опция
#define VIP_ITEM_MAPDISABLED	(1 << 3)	// Функция отключена на текущей карте (но админ может включить её любому игроку)
#define VIP_ITEM_HIDDEN			(1 << 4)	// Опция скрыта (не отображается в !vip меню)

native VIP_GetItemFlags(ItemID);

/**
 * Если указать VIP_ITEM_TOGGLE:
 * 		Функция будет вкл/откл на первой странице !vip меню или на странице с описанием функции.
 * 		Описание добавляется с помощью public bool:VIP_Description и vip_modules_description.phrases.txt
 * 		Когда игрок включает функцию, то вызывается VIP_GiveAccess и в кэш записывается "ItemName" "1".
 * 		Отключает: вызывается VIP_TakeAccess и "ItemName" удаляется из кэша.
 * 
 * Возвращает уникальный ItemID от 1 и выше (0 = ошибка).
**/
native VIP_RegisterItem(const String:ItemName[], VIP_ITEM_FLAGS);

/**
 * Удалить функцию из !vip меню.
 * Для каждого VIP_RegisterItem можно сделать VIP_UnRegisterItem.
 * Но VIP теперь видит выгрузку/перезагрузку/краш плагинов и он сам всё удалит.
 * Это может быть полезно только если нужно удалить функцию во время работы плагина, а не перед его отключением.
**/
native VIP_UnRegisterItem(const String:ItemName[]);				

/**
 * Плагин, который сделал VIP_RegisterItem, может использовать следующие необязательные функции.
 * Более подробно в уроке: http://world-source.ru/forum/141-4848-1
 * 
 * public VipGiveAction:VIP_GiveAccess(client, ItemID, String:ItemValue[ITEM_INFO_LENGTH], bool:bCallAfterAdminAction, CURRENT_ACCESS, Handle:kv)
 * {
 * }
 * 
 * public VIP_TakeAccess(client, ItemID, bool:bToggledByClient)
 * {
 * }
 * 
 * public VIP_MenuSelect(client, ItemID)
 * {
 * }
 * 
 * public bool:VIP_CurrentItemValue(client, ItemID, String:ItemValue[], ItemValueSize)
 * {
 * }
 * 
 * public bool:VIP_Description(client, ItemID, String:ItemValue[ITEM_INFO_LENGTH], String:description[], description_size)
 * {
 *	Это только для VIP_ITEM_TOGGLE функций.
 * 	Можно добавить описание функции и она будет вкл/откл не на главной странице !vip меню, а на странице с описанием.
 * 	Если используете перевод, то добавьте его в vip_modules_description.phrases.txt
 * }
**/

native VIP_GetServerType();					// 1  = csgo, 2 = css, 3 = css v34
native VIP_GetSeconds(client);				// -2 = нет VIP прав, -1 = вечный VIP доступ, x = оставшиеся секунды VIP доступа
native VIP_ShowMenu(client, bool:bSmallDelay = false); // Если bSmallDelay true, то меню будет показано через 0.1 сек.
native VIP_GetItemID(const String:ItemName[]);

/**
 * Можно использовать на любом игроке (неважно есть у него VIP или нет), т.к. функция может быть выдана любому не-бот игроку.
 * Например, игроку добавлена скорость 0.5 (в группе это прописывается так -> 'speed : 0.5')
 * Чтобы узнать текущее значение скорости игрока (а оно может меняться в любой момент админом/sm_vipsetitemstatus/сам включил/отключил), то делаем так:
 * 
 * decl String:ItemValue[16]; // Зачем использовать ITEM_INFO_LENGTH, если мы знаем что значение состоит из нескольких символов.
 * if (VIP_GetCurrentItemValue(client, "speed", ItemValue, sizeof(ItemValue)))
 *     PrintToServer("Текущая скорость: '%s'", ItemValue);
 * else
 *     PrintToServer("Или модуль не реализовал функцию 'VIP_CurrentItemValue', или вернул false.");
 * 
 * Чтобы это сработало, модуль должен добавить публичную функцию и реализовать её:
 * public bool:VIP_CurrentItemValue(client, ItemID, String:ItemValue[], ItemValueSize);
 * Смотрите модуль speed или инструкцию (http://world-source.ru/forum/141-4848-1) чтобы узнать больше.
 * 
 * Ещё текущее значение можно узнать с помощью VE_ItemStatusChanged, но только если модуль реализовал 'VIP_NotifyItemStatusChanged'.
**/
native bool:VIP_GetCurrentItemValue(client, const String:ItemName[], String:ItemValue[], ItemValueSize);

native bool:VIP_GetItemName (ItemID, String:buffer[], maxlength = ITEM_NAME_LENGTH);
native bool:VIP_GetGroupName(client, String:buffer[], maxlength = GROUP_LENGTH);
native bool:VIP_GetGroupItemValue(const String:group[], const String:ItemName[], String:buffer[], maxlength = ITEM_INFO_LENGTH); // true = у группы есть доступ к ItemName
native bool:VIP_IsValidGroup(const String:group[]);
native bool:VIP_IsVipFreeTime();

/**
 * Возвращает timestamp, когда игрок брал отпуск в последний раз.
 * 0 = еще не брал отпуск
**/
native VIP_GetLastHolidayTime(client);

/**
 * Возвращает Handle:kv (KeyValues) с личными настройками игрока (перед возвращением делается KvRewind).
 * Можно использовать на ЛЮБЫХ игроках.
 * Даже если у игрока нет KV файла, это вернёт пустую KeyValues группу "settings" {}
 * INVALID_HANDLE = игрок не авторизован или какая-то другая ошибка.
**/
native Handle:VIP_GetClientCache(client);

/**
 * Сохранить личные настройки игрока в cfg/vip/cache.
 * Можно использовать на ЛЮБЫХ игроках.
 * Пригодится, если вы делали VIP_GetClientCache и что-то изменили в KV, или просто не хотите ждать, пока игрок выйдет с сервера.
 * Старайтесь сохранять KV лишь тех игроков, у которых есть доступ. Чем меньше файлов, тем лучше.
 * immediately - если true, то прямо сейчас, false - в момент выхода с сервера.
**/
native VIP_SaveClientCache(client, bool:immediately);

/**
 * Есть ли у игрока (неважно VIP он или нет) доступ к функции.
 * Доступ к функциям может в любой момент меняться через управление модулями в админке или VIP_SetItemStatus/sm_vipsetitemstatus.
 * Чтобы узнать выдан ли этот доступ по флагу:
 * new bool:bAccessByFlag;
 * if (VIP_HaveAccessToItem(client, ItemID, bAccessByFlag))
 *     PrintToServer("Доступ есть (по флагу: %s)", bAccessByFlag ? "да" : "нет");
**/
native bool:VIP_HaveAccessToItem(client, ItemID, &bool:bAccessByFlag = false);

/**
 * Возвращает количество функций, доступных игроку (размер hAr), или 0, если нет доступа ни к одной функции.
 * 
 * decl Handle:hAr, index;
 * if ((index = VIP_GetClientItemList(client, hAr)))
 * {
 *		decl info[2], String:ItemName[ITEM_NAME_LENGTH];
 *		while (--index > -1)
 *		{
 *			GetArrayArray(hAr, index, info, sizeof(info));
 *			ItemName[0] = 0;
 *			VIP_GetItemName(info[0], ItemName, ITEM_NAME_LENGTH);
 *			PrintToChat(client, "Есть доступ к ItemID %d (%s) (по флагу: %s)", info[0], ItemName, info[1] ? "да" : "нет");
 *		}
 *		CloseHandle(hAr); // Не забудьте закрыть.
 * }
**/
native VIP_GetClientItemList(client, &Handle:hArray);

/**
 * Это работает так же, как и RCON команда:
 * sm_vipsetitemstatus <ItemName/all> <1=on|0=off> [UserID] [ItemValue]
 * Если ItemID < 1, то это "all", т.е. действие на всех функциях, а не на одной.
**/
native VIP_SetItemStatus(ItemID, bool:enabled, client = 0, const String:ItemValue[] = "");

/**
 * Если нет связи с MYSQL/SQLite, вернёт INVALID_HANDLE.
 * Таблицы/поля есть в VIP теме (http://world-source.ru/forum/134-2543-1)
**/
native Handle:VIP_GetSqlHandle();

/**
 * new Handle:hArray = INVALID_HANDLE;
 * VIP_GetItemList(hArray);
 * if (hArray != INVALID_HANDLE)
 * {
 *		new index = GetArraySize(hArray);
 * 		if (index > 0)
 * 		{
 *			decl String:ItemName[ITEM_NAME_LENGTH];
 *			while (--index > -1)
 *			{
 *				GetArrayString(hArray, index, ItemName, ITEM_NAME_LENGTH);
 *				PrintToServer(ItemName);
 *			}
 *		}
 *		CloseHandle(hArray); // Не забудьте закрыть
 * }
**/
native VIP_GetItemList (&Handle:hArray); // список созданных модулями функций
native VIP_GetGroupList(&Handle:hArray); // список созданных групп

/**
 * Если в вашем плагине есть меню, можно следить чтобы игрок не слишком часто его использовал.
 * Время настраивается в vip.cfg (vip_menu_flood "0.1")
**/
native bool:VIP_MenuFlood(client, bool:bWarningSound = true);

/**
 * Можно использовать лишь на авторизованных не-VIP игроках.
 * В SQL базу игрок не добавляется.
 * Устанавливает игроку указанную VIP группу и игрок становится VIP игроком.
 * Время устанавливается в 0 (доступ навсегда). После выхода с сервера, доступ пропадает.
 * Если игрок не был в VIP группе, доступ будет выдан, сработает VIP_EVENT_ADDED и функция вернёт true.
 * Если игрок уже во временной VIP группе и group с ней не совпадает, доступ будет изменён, сработает VIP_EVENT_GROUPCHANGED и функция вернёт true.
**/
native bool:VIP_SetTemporaryGroup(client, const String:group[]);

/**
 * Отнять VIP доступ, который был выдан с помощью VIP_SetTemporaryGroup.
 * Если вернёт true, то доступ был отобран и сработал VIP_EVENT_REMOVED с reason "VIP_UnSetTemporaryGroup".
 * Не нужно использовать в OnClientDisconnect, т.к. это сделает сам VIP плагин (VIP_EVENT_REMOVED вызван не будет).
**/
native bool:VIP_UnSetTemporaryGroup(client);

public SharedPlugin:__pl_vip = 
{
	name = "vip",
	file = "vip.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_vip_SetNTVOptional()
{
	MarkNativeAsOptional("VIP_HookEvent");
	MarkNativeAsOptional("VIP_NotifyItemStatusChanged");
	MarkNativeAsOptional("VIP_GetCurrentItemValue");
	MarkNativeAsOptional("VIP_GetFlags");
	MarkNativeAsOptional("VIP_GetItemFlags");
	MarkNativeAsOptional("VIP_RegisterItem");
	MarkNativeAsOptional("VIP_UnRegisterItem");
	MarkNativeAsOptional("VIP_GetServerType");
	MarkNativeAsOptional("VIP_GetSeconds");
	MarkNativeAsOptional("VIP_ShowMenu");
	MarkNativeAsOptional("VIP_GetItemID");
	MarkNativeAsOptional("VIP_GetItemName");
	MarkNativeAsOptional("VIP_GetGroupName");
	MarkNativeAsOptional("VIP_GetGroupItemValue");
	MarkNativeAsOptional("VIP_IsValidGroup");
	MarkNativeAsOptional("VIP_IsVipFreeTime");
	MarkNativeAsOptional("VIP_GetClientCache");
	MarkNativeAsOptional("VIP_SaveClientCache");
	MarkNativeAsOptional("VIP_HaveAccessToItem");
	MarkNativeAsOptional("VIP_GetClientItemList");
	MarkNativeAsOptional("VIP_SetItemStatus");
	MarkNativeAsOptional("VIP_GetSqlHandle");
	MarkNativeAsOptional("VIP_GetItemList");
	MarkNativeAsOptional("VIP_GetGroupList");
	MarkNativeAsOptional("VIP_MenuFlood");
	MarkNativeAsOptional("VIP_SetTemporaryGroup");
	MarkNativeAsOptional("VIP_UnSetTemporaryGroup");
	MarkNativeAsOptional("VIP_GetLastHolidayTime");
}
#endif