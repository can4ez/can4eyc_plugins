#if defined _wS_vip_old_included
	#endinput
#endif
#define _wS_vip_old_included 
// Авторизован ли игрок (forward VIP_OnClientAuthorized)
native bool:VIP_IsClientAuthorized(client);

// Есть ли VIP доступ
native bool:VIP_IsVipPlayer(client);