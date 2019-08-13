#if defined _knife_arena_included
	#endinput
#endif
#define _knife_arena_included

enum KA_Reason
{
	KA_Disconnect = 0,					// вышел с сервера
	KA_Box,								// не на арене (не в клетке)
	KA_Team,							// сменил команду
	KA_Suicide,							// убил сам себя
	KA_Death,							// умер (т.к. урон наносится лишь от соперника, значит его убил соперник)
	KA_Self,							// покинул арену сам (через меню)
	KA_Admin							// удалён админом
};

enum KA_Event
{
	KA_OnArenaSpawn = 0,				// public Action:CallBack();
	KA_OnArenaSpawnPost,				// public CallBack(const Float:center[3], const Float:tt[3], const Float:ct[3]);
	KA_OnPushToQueue,					// public Action:CallBack(client); - игрок хочет занять очередь
	KA_OnPushToQueuePost,				// public CallBack(client, queue, place);
	KA_OnPushFromQueueToArena,			// public Action:CallBack(client); - пришла очередь игрока (Plugin_Stop = запретить = из очереди берётся следующий игрок)
	KA_OnPushFromQueueToArenaPost,		// public CallBack(client);
	KA_OnArenaTimer,					// public CallBack(sec); - отсчет перед поединком (0 = go)
	KA_OnArenaHasWinner,				// public CallBack(winner, loser); - winner УБИЛ игрока loser
	KA_OnLeaveArena,					// public Action:CallBack(client); - игрок хочет покинуть арену (через меню)
	KA_OnArenaClientRemoved,			// public CallBack(client, KA_Reason:reason); - игрок покинул арену
	KA_OnFightTimerEnd					// public CallBack(tt, ct); - время поединка истекло (cvar ka_timer_fight) и оба игрока были убиты
};

native KA_HookEvent(KA_Event:event, Function:CallBack);

native bool:KA_ClientOnArena(client);
native bool:KA_ArenaExists();			// арена создана, но может быть недоступна
native bool:KA_ArenaExistsAndReady();	// создана и доступна
native bool:KA_IsArena(const Float:vec[3]);
native bool:KA_RemoveFromQueue(client);
native bool:KA_RemoveFromArena(client);
native bool:KA_PushToQueue(client);
native bool:KA_DeleteArena();			// в следующем раунде арена появится снова

native KA_GetArenaClients(&t, &ct);		// decl t, ct; KA_GetArenaClients(t, ct); если < 1, то на арене нет t/ct
native KA_GetPlaceInQueue(client, &queue = 0);	// < 1 = нет в очереди (queue = общее кол-во товарищей в очереди с учетом client)

public SharedPlugin:__pl_knife_arena = 
{
	name = "knife_arena",
	file = "knife_arena.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_knife_arena_SetNTVOptional()
{
	MarkNativeAsOptional("KA_HookEvent");
	MarkNativeAsOptional("KA_ClientOnArena");
	MarkNativeAsOptional("KA_ArenaExists");
	MarkNativeAsOptional("KA_ArenaExistsAndReady");
	MarkNativeAsOptional("KA_IsArena");
	MarkNativeAsOptional("KA_RemoveFromQueue");
	MarkNativeAsOptional("KA_RemoveFromArena");
	MarkNativeAsOptional("KA_PushToQueue");
	MarkNativeAsOptional("KA_DeleteArena");
	MarkNativeAsOptional("KA_GetArenaClients");
	MarkNativeAsOptional("KA_GetPlaceInQueue");
}
#endif