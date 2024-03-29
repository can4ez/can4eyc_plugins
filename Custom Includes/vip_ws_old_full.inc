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

// ����������� �� ����� (forward VIP_OnClientAuthorized)
native bool:VIP_IsClientAuthorized(client);

// ���� �� VIP ������
native bool:VIP_IsVipPlayer(client);

// ���������� ����� VIP ������� � ��������, ���:
// -2 ��� vip �������
// -1 ����������
native VIP_GetAccessSeconds(client);

// �������� ��� ������ VIP ������ (������ VIP_IsVipPlayer �� �����, maxlength 50)
native bool:VIP_GetGroupName(client, String:buffer[], maxlength);

// ���������� �� VIP ������
native bool:VIP_IsValidGroup(const String:GroupName[]);

// ������� VIP ����
native VIP_ShowMenu(client);

/**
 * ������� VIP ������� (����� � !vip ����)
 *
 * ItemName			- ���������� ���, �������� "hp"
 *                    ������������ ��� ��������, ������� ��������� ��� � vip.phrases.txt
 * toggle			- ���� true,  �� ������� �� �����, ����� ����� ���/���� �������
 * selectable		- ���� false, �� ����� ����� (������ ������)
 *
 * ���������� ItemID
 * ���� < 1, �� �� ������� �������
**/
native VIP_RegisterItem(const String:ItemName[], bool:toggle, bool:selectable);

/**
 * ������� VIP ������� �� !vip ����
**/
native VIP_UnRegisterItem(const String:ItemName[]);

/**
 * ��������, ���� ���� VIP_RegisterItem("hp" ..
 * � � VIP ������ ��������� hp: 150
 * �� ������� ������ true � � ItemInfo ����� "150"
 * ���� ������ false, �� � ������ ��� ������� � �������
**/
native bool:VIP_GetClientItemInfo(client, const String:ItemName[], String:ItemInfo[]);

// ����� �������� �� ����
// ������ �������, �������� (true) ��� ��������� (false)
// ���� true, �� ��� �� ������, ��� � ������ ���� ������ � �������, ����������� VIP_GetClientItemInfo
native bool:VIP_GetItemToggledStatus(client, const String:ItemName[]);

// ���������� Handle:kv (KeyValues), � ������� �������� ������ ��������� ������ (����� ������������ �������� KvRewind)
// ��� INVALID_HANDLE
native Handle:VIP_GetClientCacheHandle(client);

// ������ true, ���� ������� ��������� �� ������� ����� (sm_vipdisable)
native bool:VIP_ItemDisabled(const String:ItemName[]);

// ������ �������
native eServerType:VIP_GetServerType();


///


/**
 * ����� ������������� (�� ���)
 *
 * vip				- true, ��� ��� VIP �����
 * group			- ������ VIP ������, ��� "", ���� ��� �� VIP
**/
forward VIP_OnClientAuthorized(client, const String:steamid[], bool:vip, const String:group[]);

/**
 * ����� ������� VIP �������
 *
 * client			- ������ ������ (���� < 1, �� �� �� �������)
 * steamid			- ���� ��� ������ (����� ������ ������)
 * reason			- �������: "time is up", "admin: server", "admin: wS, STEAM_0:0:17233444"
**/
forward VIP_OnRemoved(client, const String:steamid[], const String:reason[]);

/**
 * ����� ������� VIP ������
 *
 * client			- ������ ������ (���� < 1, �� ����� �������� ������, wtf)
 * steamid			- ���� ��� ������ (����� ������ ������)
 * group			- ��� ������ ������
 * min				- �� ������� ����� ������� VIP (0 = ��������)
 * admin_steamid	- ���� ������ ��� "server"
**/
forward VIP_OnAdded(client, const String:steamid[], const String:group[], min, const String:admin_steamid[]);

/**
 * ������ VIP ������ ��������
 *
 * client			- ������ ��� ������ (����� ������ ������)
 * steamid			- ���� ��� ������ (����� ������ ������)
 * OldGroup			- � ����� ������ ���
 * NewGroup			- � ����� ������
**/
forward VIP_OnGroupChanged(client, const String:steamid[], const String:OldGroup[], const String:NewGroup[]);

/**
 * ����� ������� ����������� ����
**/
forward VIP_OnKeyWasUsed(client, const String:steamid[], const String:key[]);

/**
 * VIP ����� �������/�������� ������� ����� ���� (VIP_OnVipItemPressed �� ����������)
 *
 * enabled			- ���� true, �� �������
 * ItemName			- ���������� ���, �������� "hp"
 * ItemInfo			- ���� � VIP ������ ���� ��������� hp: 150, �� ��� "150"
**/
forward VIP_OnVipItemToggled(client, ItemID, const String:ItemName[], const String:ItemInfo[], bool:enabled);

/**
 * VIP ����� ������ ����� � ���� (VIP_OnVipItemToggled �� ����������)
**/
forward VIP_OnVipItemPressed(client, ItemID, const String:ItemName[], const String:ItemInfo[]);

/**
 * ����� ������� (�� ����� ��� � team > 1)
**/
forward VIP_OnPlayerSpawn(client, team, bool:bot, bool:vip, const String:steamid[], const String:group[]);
