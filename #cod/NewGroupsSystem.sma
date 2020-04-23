#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <nvault>
#include <colorchat>
#include <codmod>

#define MAX_MEMBERS 20 //Maksymalna ilosc czlonkow w grupie

#define TO_ADD 0
#define XP 1
#define ATTACK 2
#define DEFENSE 3

new Array:g_szGroupName;
new Array:g_szGroupOwner, Array:g_szGroupMembers[MAX_MEMBERS];
new Array:g_iGroupExperience, Array:g_iGroupLevel;
new Array:g_iGroupAdditionalPoints[4];
new Array:g_iGroupMembersCount;

new g_szTop15Motd[2000];
new g_iGroupsCount;

new g_iPlayerGroup[33], g_iIsGroupOwner[33];
new g_szPlayerName[33][64];
new g_iLastQuestioner[33];

new g_iExpForKill;
new g_iHud, g_msgStatusText, g_iSlotsCount;
new g_iVault;
public plugin_init()
{
	
	register_plugin("Nowy System Grup", "1.1.0", "d0naciak");
	
	g_szGroupName = ArrayCreate(20, 50);
	g_szGroupOwner = ArrayCreate(64, 50);
	for(new i = 0; i < MAX_MEMBERS; i++)
		g_szGroupMembers[i] = ArrayCreate(64, 50);
	g_iGroupExperience = ArrayCreate(1, 50);
	g_iGroupLevel = ArrayCreate(1, 50);
	g_iGroupMembersCount = ArrayCreate(1, 50);
	for(new i = 0; i < 4; i++)
		g_iGroupAdditionalPoints[i] = ArrayCreate(1, 50);
		
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "fw_Killed_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	
	register_clcmd("WpiszNazweGrupy", "GroupNameWrited");
	register_clcmd("say /grupa", "GroupMenu");
	
	g_iVault = nvault_open("CodGroups");
	
	for(new i = 0; ReadGroupData(i); i++)
		g_iGroupsCount++;
	
	g_iHud = CreateHudSyncObj();
	g_msgStatusText = get_user_msgid("StatusText");
	g_iSlotsCount = get_maxplayers();
}

public plugin_cfg()
{
	FormatTop15();
	
	g_iExpForKill = get_cvar_num("cod_killxp");
}
	
public plugin_end()
{
	for(new i = 0; i < g_iGroupsCount; i++)
		SaveGroupData(i);
	
	nvault_close(g_iVault);
	
	ArrayDestroy(g_szGroupName);
	ArrayDestroy(g_szGroupOwner);
	for(new i = 0; i < MAX_MEMBERS; i++)
		ArrayDestroy(g_szGroupMembers[i]);
	ArrayDestroy(g_iGroupExperience);
	ArrayDestroy(g_iGroupLevel);
	ArrayDestroy(g_iGroupMembersCount);
	for(new i = 0; i < 4; i++)
		ArrayDestroy(g_iGroupAdditionalPoints[i]);
}

public client_authorized(id)
	get_user_name(id, g_szPlayerName[id], 63);

public client_putinserver(id)
{
	g_iPlayerGroup[id] = -1;
	g_iIsGroupOwner[id] = 0;
	
	ReadUserData(id);
}

public client_disconnect(id)
{
	SaveUserData(id);

	g_iLastQuestioner[id] = 0;
}

public fw_Spawn_Post(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED;
	
	new iGroup = g_iPlayerGroup[id];
	
	if(iGroup != -1)
	{
		if(g_iIsGroupOwner[id] && ArrayGetCell(g_iGroupAdditionalPoints[TO_ADD], iGroup))
			DealPoints(id);
		
		set_task(0.1, "UpdateInfo", id);
	}
	
	return HAM_IGNORED;
}

public fw_Killed_Post(iVictim, iKiller)
{
	if(!is_user_connected(iKiller) || get_user_team(iKiller) == get_user_team(iVictim) || g_iPlayerGroup[iKiller] == -1)
		return HAM_IGNORED;
		
	new iExpForKill = g_iExpForKill, iExpToAdd = iExpForKill, iGroup = g_iPlayerGroup[iKiller], iXpPoints = ArrayGetCell(g_iGroupAdditionalPoints[XP], iGroup);
	
	if(iXpPoints)
		iExpToAdd += floatround(iExpForKill * iXpPoints * 0.025);
		
	if(cod_get_user_level(iVictim) > cod_get_user_level(iKiller))
		iExpToAdd += (cod_get_user_level(iVictim)-cod_get_user_level(iKiller))*(iExpForKill/10);
	
	ArraySetCell(g_iGroupExperience, iGroup, ArrayGetCell(g_iGroupExperience, iGroup) + iExpToAdd);
	
	set_hudmessage(255, 255, 0, -1.0, 0.2, 0, 3.0, 3.0, _, _, -1);
	ShowSyncHudMsg(iKiller, g_iHud, "XP Grupy: +%d", iExpToAdd);
	
	CheckLevel(iGroup);
	
	return HAM_IGNORED;
}

public fw_TakeDamage(id, iEnt, iAttacker, Float:fDamage, iDamageBits)
{
	if(!is_user_connected(iAttacker) || get_user_team(id) == get_user_team(iAttacker) || !(iDamageBits & (1<<1)))
		return HAM_IGNORED;
	
	if(g_iPlayerGroup[id] != -1)
	{
		new iDefensePoints = ArrayGetCell(g_iGroupAdditionalPoints[DEFENSE], g_iPlayerGroup[id]);
		
		if(iDefensePoints)
		{
			SetHamParamFloat(4, fDamage - fDamage * iDefensePoints * 0.01);
			
			return HAM_HANDLED;
		}
	}
	
	if(g_iPlayerGroup[iAttacker] != -1)
	{
		new iAttackPoints = ArrayGetCell(g_iGroupAdditionalPoints[ATTACK], g_iPlayerGroup[iAttacker]);
		
		if(iAttackPoints)
		{
			SetHamParamFloat(4, fDamage + fDamage * iAttackPoints * 0.04);
			
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}
	
public GroupMenu(id)
{
	new iMenu = menu_create("GroupsSystem by \rd0naciak", "GroupMenu_Handler");
	
	menu_additem(iMenu, "Stworz grupe");
	menu_additem(iMenu, "Zniszcz grupe");
	menu_additem(iMenu, "Wyjdz z grupy");
	menu_addblank(iMenu, 0);
	menu_additem(iMenu, "Dodaj czlonkow");
	menu_additem(iMenu, "Wyrzuc czlonkow");
	menu_addblank(iMenu, 0);
	menu_additem(iMenu, "Punkty grupy");
	menu_additem(iMenu, "Resetuj punkty grupy");
	menu_addblank(iMenu, 0);
	menu_additem(iMenu, "Lista grup");
	menu_additem(iMenu, "\rTop 15 grup");
	menu_additem(iMenu, "Informacje o mojej grupie");
	menu_addblank(iMenu, 0);
	menu_additem(iMenu, "Co to grupy?");
	
	menu_display(id, iMenu);
	
	return PLUGIN_HANDLED;
}

public GroupMenu_Handler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
		return PLUGIN_CONTINUE;
		
	switch(iItem)
	{
		case 0: CreateGroup(id);
		case 1: DeleteGroup(id);
		case 2: LeaveFromGroup(id);
		case 3: AddMember(id);
		case 4: KickMember(id);
		case 5: DealPoints(id);
		case 6: ResetPoints(id);
		case 7: ListOfGroups(id);
		case 8: ShowTop15(id);
		case 9: GroupInfo(id);
		case 10: show_motd(id, "GroupInfo.txt", "Co to grupy?");
	}
	
	menu_destroy(iMenu);
	return PLUGIN_CONTINUE;
}
		

public CreateGroup(id)
{
	if(g_iPlayerGroup[id] != -1)
	{
		print_msg(id, "Jestes juz w grupie!");
		return PLUGIN_CONTINUE;
	}
	
	client_cmd(id, "messagemode WpiszNazweGrupy");
	print_msg(id, "Wszystko dobrze, wpisz teraz nazwe grupy.");
	
	return PLUGIN_CONTINUE;
}

public GroupNameWrited(id)
{
	if(g_iPlayerGroup[id] != -1)
	{
		print_msg(id, "Jestes juz w grupie!");
		return PLUGIN_HANDLED;
	}
	
	new szGroupName[20];
	
	read_argv(1, szGroupName, 20);
	
	g_iPlayerGroup[id] = g_iGroupsCount;
	g_iIsGroupOwner[id] = 1;
	
	ArrayPushCell(g_iGroupLevel, 1);
	ArrayPushCell(g_iGroupExperience, 0);
	ArrayPushCell(g_iGroupMembersCount, 1);
	
	for(new i = 1; i < MAX_MEMBERS; i++)
		ArrayPushString(g_szGroupMembers[i], "");
		
	for(new i = 0; i < 4; i++)
		ArrayPushCell(g_iGroupAdditionalPoints[i], 0);
	
	ArrayPushString(g_szGroupName, szGroupName);
	ArrayPushString(g_szGroupOwner, g_szPlayerName[id]);
	
	g_iGroupsCount++;
	
	UpdateInfo(id);
	
	print_msg(id, "Grupa^x03 %s^x01 zostala zalozona.", szGroupName);
	
	return PLUGIN_HANDLED;
}

public AddMember(id)
{
	if(g_iPlayerGroup[id] == -1)
	{
		print_msg(id, "Nie jestes w grupie!");
		return PLUGIN_CONTINUE;
	}
	if(!g_iIsGroupOwner[id])
	{
		print_msg(id, "Tylko wlasciciel moze dodawac czlonkow do grupy!");
		return PLUGIN_CONTINUE;
	}
	if(ArrayGetCell(g_iGroupMembersCount, g_iPlayerGroup[id]) >= MAX_MEMBERS)
	{
		print_msg(id, "Przekroczono limit maksymalnej ilosci czlonkow!");
		return PLUGIN_CONTINUE;
	}
	
	new iMenu = menu_create("Dodaj czlonka", "AddMember_Handle");

	for(new iPlayers = 1; iPlayers <= g_iSlotsCount; iPlayers++)
	{
		if(!is_user_connected(iPlayers) || g_iPlayerGroup[iPlayers] != -1)
			continue;
		
		menu_additem(iMenu, g_szPlayerName[iPlayers], g_szPlayerName[iPlayers]);
	}
	menu_display(id, iMenu);
	
	return PLUGIN_CONTINUE;
}

public AddMember_Handle(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
		
	new szData[64], iAccess;
	menu_item_getinfo(iMenu, iItem, iAccess, szData, 63, _, _, iAccess);
	
	new iNewMember = get_user_index2(szData);
	
	if(!is_user_connected(iNewMember))
	{
		print_msg(id, "Nie znaleziono^x03 %s!", szData);
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
	if(g_iPlayerGroup[iNewMember] != -1)
	{
		print_msg(id, "Gracz^x03 %s^x01 jest juz w grupie!", szData);
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
	
	g_iLastQuestioner[iNewMember] = id;
	AskPlayer(iNewMember, g_iPlayerGroup[id]);
	
	menu_destroy(iMenu);
	
	return PLUGIN_CONTINUE;
}

public AskPlayer(id, iGroup)
{
	new szTitle[60], szGroupName[20];
	
	ArrayGetString(g_szGroupName, iGroup, szGroupName, 19);
	
	formatex(szTitle, 59, "Chcesz dolaczyc do \y%s\w?", szGroupName);
	
	new iMenu = menu_create(szTitle, "AskPlayer_Handler");
	
	menu_additem(iMenu, "Tak");
	menu_additem(iMenu, "Nie");
	
	menu_display(id, iMenu);
}

public AskPlayer_Handler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
	
	new iOwner = g_iLastQuestioner[id];
	
	if(iItem == 0)
	{
		new iGroup = g_iPlayerGroup[id] = g_iPlayerGroup[iOwner]; ////
		new iMembersCount = ArrayGetCell(g_iGroupMembersCount, iGroup);
		
		ArraySetString(g_szGroupMembers[iMembersCount], iGroup, g_szPlayerName[id]);
		ArraySetCell(g_iGroupMembersCount, iGroup, iMembersCount + 1);
		
		UpdateInfo(id);
		
		print_msg(iOwner, "Gracz^x03 %s^x01 dolaczyl do grupy.", g_szPlayerName[id]);
	}
	else print_msg(iOwner, "Gracz^x03 %s^x01 odrzucil zaproszenie grupy.", g_szPlayerName[id]);
	
	menu_destroy(iMenu);
	
	return PLUGIN_CONTINUE;
}
			
public KickMember(id)
{
	if(g_iPlayerGroup[id] == -1)
	{
		print_msg(id, "Nie jestes w grupie!");
		return PLUGIN_CONTINUE;
	}
	if(!g_iIsGroupOwner[id])
	{
		print_msg(id, "Tylko wlasciciel usuwac z grupy!");
		return PLUGIN_CONTINUE;
	}
	
	new iMenu = menu_create("Wywalaj z grupy", "KickMember_Handler"), szMemberName[64];
	new iGroup = g_iPlayerGroup[id];
	
	for(new i = 1; i < ArrayGetCell(g_iGroupMembersCount, iGroup); i++)
	{
		ArrayGetString(g_szGroupMembers[i], iGroup, szMemberName, 63);
		menu_additem(iMenu, szMemberName, szMemberName);
	}
	
	menu_display(id, iMenu);
	return PLUGIN_CONTINUE;
}

public KickMember_Handler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
		
	new szData[64], iAccess, iCallBack;
	menu_item_getinfo(iMenu, iItem, iAccess, szData, 63, _, _, iCallBack);
	
	new iEjected = get_user_index2(szData);
	new iGroup = g_iPlayerGroup[id];
	
	if(is_user_connected(iEjected) && g_iPlayerGroup[iEjected] != iGroup)
	{
		print_msg(id, "Tego gracza nie ma w grupie!");
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
	
	new iMembersCount = ArrayGetCell(g_iGroupMembersCount, iGroup), iMemberId, szGroupMemberName[64], szVaultKey[128];
	
	if(is_user_connected(iEjected))
	{
		g_iPlayerGroup[iEjected] = -1;
		
		UpdateInfo(id);
		
		print_msg(iEjected, "Zostales wyrzucony z grupy...");
	}

	formatex(szVaultKey, 127, "%s-PlayerData", szData);
	nvault_remove(g_iVault, szVaultKey);
	
	for(new i = 1; i < iMembersCount; i++)
	{
		ArrayGetString(g_szGroupMembers[i], iGroup, szGroupMemberName, 63);
		
		if(equal(szData, szGroupMemberName))
		{
			iMemberId = i;
			break;
		}
	}
	
	if(iMemberId+1 < iMembersCount)
	{
		for(new i = iMemberId+1; i < MAX_MEMBERS; i++)
		{
			ArrayGetString(g_szGroupMembers[i], iGroup, szGroupMemberName, 63);
			
			if(!szGroupMemberName[0])
			{
				ArraySetString(g_szGroupMembers[i-1], iGroup, "");
				break;
			}
			ArraySetString(g_szGroupMembers[i-1], iGroup, szGroupMemberName);
		}
	}
	else ArraySetString(g_szGroupMembers[iMemberId], iGroup, "");
	
	iMembersCount--;
	ArraySetCell(g_iGroupMembersCount, iGroup, iMembersCount);
	
	print_msg(id, "Gracz^x03 %s wyszedl z grupy.", szData);
	
	menu_destroy(iMenu);
	return PLUGIN_CONTINUE;
}

public DealPoints(id)
{
	new iGroup = g_iPlayerGroup[id]; 
	
	if(iGroup == -1)
	{
		print_msg(id, "Nie jestes w grupie!");
		return PLUGIN_CONTINUE;
	}
	if(!g_iIsGroupOwner[id])
	{
		print_msg(id, "Tylko wlasciciel moze rozdawac punkty!");
		return PLUGIN_CONTINUE;
	}
	
	new szFormat[101], iPoints;
	
	iPoints = ArrayGetCell(g_iGroupAdditionalPoints[TO_ADD], iGroup);
	formatex(szFormat, 100, "Rozdaj punkty \r(%d)", iPoints);
	new iMenu = menu_create(szFormat, "DealPoints_Handler");
	
	iPoints = ArrayGetCell(g_iGroupAdditionalPoints[XP], iGroup);
	formatex(szFormat, 100, "Exp \r[%d] \y(Wiecej XP za zabojstwo)", iPoints);
	menu_additem(iMenu, szFormat);
	
	iPoints = ArrayGetCell(g_iGroupAdditionalPoints[ATTACK], iGroup);
	formatex(szFormat, 100, "Atak \r[%d] \y(Wiecej zadanych obrazen)", iPoints);
	menu_additem(iMenu, szFormat);
	
	iPoints = ArrayGetCell(g_iGroupAdditionalPoints[DEFENSE], iGroup);
	formatex(szFormat, 100, "Obrona \r[%d] \y(Mniej otrzymanych obrazen)", iPoints);
	menu_additem(iMenu, szFormat);
	
	menu_display(id, iMenu);
	
	return PLUGIN_CONTINUE;
}

public DealPoints_Handler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
	if(iItem  < 0)
		return PLUGIN_CONTINUE;

	new iGroup = g_iPlayerGroup[id];
	new iWhatAdd = iItem + 1, iStatisticPoints, iPointsToAdd;
	
	iStatisticPoints = ArrayGetCell(g_iGroupAdditionalPoints[iWhatAdd], iGroup);
	iPointsToAdd = ArrayGetCell(g_iGroupAdditionalPoints[TO_ADD], iGroup);
	
	if(!iPointsToAdd)
	{
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
		
	if(iStatisticPoints < 40)
	{
		ArraySetCell(g_iGroupAdditionalPoints[iWhatAdd], iGroup, iStatisticPoints + 1);
		iPointsToAdd -= 1;
	}
	else
		print_msg(id, "Maksymalna ilosc punktow zostala osiagnieta!");
	
	ArraySetCell(g_iGroupAdditionalPoints[TO_ADD], iGroup, iPointsToAdd);
	
	menu_destroy(iMenu);
	
	if(iPointsToAdd)
		DealPoints(id);
	
	return PLUGIN_CONTINUE;
}

public ResetPoints(id)
{
	if(g_iPlayerGroup[id] == -1)
	{
		print_msg(id, "Nie jestes w grupie!");
		return PLUGIN_CONTINUE;
	}
	if(!g_iIsGroupOwner[id])
	{
		print_msg(id, "Tylko wlasciciel moze resetowac punkty grupy!");
		return PLUGIN_CONTINUE;
	}
	
	new iGroup = g_iPlayerGroup[id];
	
	if(ArrayGetCell(g_iGroupLevel, iGroup) <= 1)
	{
		print_msg(id, "Nie posiadasz zadnych punktow!");
		return PLUGIN_CONTINUE;
	}
	
	for(new i = 1; i <= 3; i++)
		ArraySetCell(g_iGroupAdditionalPoints[i], iGroup, 0);
	ArraySetCell(g_iGroupAdditionalPoints[TO_ADD], iGroup, (ArrayGetCell(g_iGroupLevel, iGroup)-1)*2);
	
	DealPoints(id);
	
	return PLUGIN_CONTINUE;
}

public ListOfGroups(id)
{
	new szGroupName[20], iMenu = menu_create("Lista wszytkich grup", "ListOfGroups_Handler");
	
	for(new i = 0; i < g_iGroupsCount; i++)
	{
		ArrayGetString(g_szGroupName, i, szGroupName, 19);
		
		menu_additem(iMenu, szGroupName);
	}
	
	menu_display(id, iMenu);
}

public ListOfGroups_Handler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
	
	new iGroup = iItem;
	new szGroupName[64], szGroupMemberName[64], iMembersCount, szInfo[512], iLen;
	
	ArrayGetString(g_szGroupName, iGroup, szGroupName, 19);
	ArrayGetString(g_szGroupOwner, iGroup, szGroupMemberName, 63);
	iMembersCount = ArrayGetCell(g_iGroupMembersCount, iGroup);
	
	iLen = formatex(szInfo, 511, "Grupa: \y%s^n", szGroupName);
	iLen += formatex(szInfo[iLen], 511-iLen, "\wWlasciciel: \y%s^n", szGroupMemberName);
	iLen += formatex(szInfo[iLen], 511-iLen, "\wPoziom: \y%d^n\wDoswiadczenie: \y%d^n", ArrayGetCell(g_iGroupLevel, iGroup), ArrayGetCell(g_iGroupExperience, iGroup));
	
	if(iMembersCount > 1)
	{
		iLen += formatex(szInfo[iLen], 511-iLen, "\d================^n");
		iLen += formatex(szInfo[iLen], 511-iLen, "\wRazem jest ich \y%d:^n", iMembersCount);
		
		for(new iMember = 1; iMember < iMembersCount; iMember++)
		{
			ArrayGetString(g_szGroupMembers[iMember], iGroup, szGroupMemberName, 63);
			
			iLen += formatex(szInfo[iLen], 511-iLen, "\wGracz: \y%s^n", szGroupMemberName);
		}
	}
	
	show_menu(id, 1023, szInfo);
	
	menu_destroy(iMenu);
	return PLUGIN_CONTINUE;
}

public ShowTop15(id)
	show_motd(id, g_szTop15Motd, "Top 15");
	
public GroupInfo(id)
{
	if(g_iPlayerGroup[id] == -1)
	{
		print_msg(id, "Nie jestes w grupie!");
		return PLUGIN_CONTINUE;
	}
	
	new iGroup = g_iPlayerGroup[id];
	new szGroupName[20], szGroupMemberName[64], iMembersCount, szInfo[512], iLen;
	
	ArrayGetString(g_szGroupName, iGroup, szGroupName, 19);
	ArrayGetString(g_szGroupOwner, iGroup, szGroupMemberName, 63);
	iMembersCount = ArrayGetCell(g_iGroupMembersCount, iGroup);
	
	iLen = formatex(szInfo, 511, "Grupa: \y%s^n", szGroupName);
	iLen += formatex(szInfo[iLen], 511-iLen, "\wWlasciciel: \y%s^n", szGroupMemberName);
	iLen += formatex(szInfo[iLen], 511-iLen, "\wPoziom: \y%d^n\wDoswiadczenie: \y%d^n", ArrayGetCell(g_iGroupLevel, iGroup), ArrayGetCell(g_iGroupExperience, iGroup));
	
	if(iMembersCount > 1)
	{
		iLen += formatex(szInfo[iLen], 511-iLen, "\d================^n");
		iLen += formatex(szInfo[iLen], 511-iLen, "\wRazem jest Was \y%d:^n", iMembersCount);
		
		for(new iMember = 1; iMember < iMembersCount; iMember++)
		{
			ArrayGetString(g_szGroupMembers[iMember], iGroup, szGroupMemberName, 63);
			
			iLen += formatex(szInfo[iLen], 511-iLen, "\wGracz: \y%s^n", szGroupMemberName);
		}
	}
	
	show_menu(id, 1023, szInfo);
	
	return PLUGIN_CONTINUE;
}

public DeleteGroup(id)
{
	if(g_iPlayerGroup[id] == -1)
	{
		print_msg(id, "Nie jestes w grupie!");
		return PLUGIN_CONTINUE;
	}
	if(!g_iIsGroupOwner[id])
	{
		print_msg(id, "Tylko wlasciciel moze niszczyc grupe!");
		return PLUGIN_CONTINUE;
	}
	
	new iGroup = g_iPlayerGroup[id];
	new iPlayer, szGroupMemberName[64], szVaultKey[128], szVaultData[14], szPlayerGroup[5], iDistrPos;
	
	for(new iMember = 1; iMember < ArrayGetCell(g_iGroupMembersCount, iGroup); iMember++)
	{
		ArrayGetString(g_szGroupMembers[iMember], iGroup, szGroupMemberName, 63);
		
		iPlayer = get_user_index2(szGroupMemberName);
			
		if(iPlayer)
		{
			g_iPlayerGroup[iPlayer] = -1;
			
			UpdateInfo(id);
			
			print_msg(iPlayer, "Grupa do ktorej nalezales zostala zniszczona!");
		}
		
		formatex(szVaultKey, 127, "%s-PlayerData", szGroupMemberName);
		nvault_remove(g_iVault, szVaultKey);
	}
	
	for(new iGroups = iGroup+1; iGroups < g_iGroupsCount; iGroups++)
	{
		for(new iMember = 1; iMember < ArrayGetCell(g_iGroupMembersCount, iGroups); iMember++)
		{
			ArrayGetString(g_szGroupMembers[iMember], iGroups, szGroupMemberName, 63);
			
			iPlayer = get_user_index2(szGroupMemberName);
				
			if(iPlayer)
				g_iPlayerGroup[iPlayer]--;
			else
			{
				formatex(szVaultKey, 127, "%s-PlayerData", szGroupMemberName);
				nvault_get(g_iVault, szVaultKey, szVaultData, 13);
				
				iDistrPos = contain(szVaultData, "#");
				
				copy(szVaultData[iDistrPos], 13 - iDistrPos, "");
				copy(szPlayerGroup, 4, szVaultData);
				
				formatex(szVaultData, 13, "%d#0", str_to_num(szPlayerGroup)-1);
				
				nvault_set(g_iVault, szVaultKey, szVaultData);
			}
		}
		
		ArrayGetString(g_szGroupOwner, iGroups, szGroupMemberName, 63);
			
		iPlayer = get_user_index2(szGroupMemberName);
			
		if(iPlayer)
			g_iPlayerGroup[iPlayer]--;
		else
		{
			formatex(szVaultKey, 127, "%s-PlayerData", szGroupMemberName);
			nvault_get(g_iVault, szVaultKey, szVaultData, 13);
				
			iDistrPos = contain(szVaultData, "#");
				
			copy(szVaultData[iDistrPos], 13-iDistrPos, "");
			copy(szPlayerGroup, 4, szVaultData);
				
			formatex(szVaultData, 13, "%d#1", str_to_num(szPlayerGroup)-1);
				
			nvault_set(g_iVault, szVaultKey, szVaultData);
		}
	}
	
	g_iPlayerGroup[id] = -1;
	g_iIsGroupOwner[id] = 0;
	
	formatex(szVaultKey, 127, "%s-PlayerData", g_szPlayerName[id]);
	nvault_remove(g_iVault, szVaultKey);
	
	ArrayDeleteItem(g_szGroupOwner, iGroup);
	ArrayDeleteItem(g_szGroupName, iGroup);
	
	for(new i = 0; i < 4; i++)
		ArrayDeleteItem(g_iGroupAdditionalPoints[i], iGroup);

	for(new i = 1; i < MAX_MEMBERS; i++)
		ArrayDeleteItem(g_szGroupMembers[i], iGroup);
	
	ArrayDeleteItem(g_iGroupMembersCount, iGroup);
	
	ArrayDeleteItem(g_iGroupExperience, iGroup);
	ArrayDeleteItem(g_iGroupLevel, iGroup);
	
	g_iGroupsCount--;
	
	for(new i = 1; i <= 4; i++)
	{
		formatex(szVaultKey, 127, "%d-%d-GroupData", i, g_iGroupsCount);
		nvault_remove(g_iVault, szVaultKey);
	}
	
	UpdateInfo(id);
	
	print_msg(id, "Grupa zostala zniszczona!");
	
	return PLUGIN_CONTINUE;
}

public LeaveFromGroup(id)
{
	if(g_iPlayerGroup[id] == -1)
	{
		print_msg(id, "Nie jestes w grupie!");
		return PLUGIN_CONTINUE;
	}
	if(g_iIsGroupOwner[id])
	{
		print_msg(id, "Wlasciciel moze tylko usuwac grupe!");
		return PLUGIN_CONTINUE;
	}
	
	new iGroup = g_iPlayerGroup[id];
	new iMembersCount = ArrayGetCell(g_iGroupMembersCount, iGroup), iMemberId, szGroupName[20], szGroupMemberName[64], szVaultKey[128];
	
	for(new i = 1; i < iMembersCount; i++)
	{
		ArrayGetString(g_szGroupMembers[i], iGroup, szGroupMemberName, 63);
		
		if(equal(g_szPlayerName[id], szGroupMemberName))
		{
			iMemberId = i;
			break;
		}
	}
	
	if(iMemberId+1 < iMembersCount)
	{
		for(new i = iMemberId+1; i < MAX_MEMBERS; i++)
		{
			ArrayGetString(g_szGroupMembers[i], iGroup, szGroupMemberName, 63);
			
			if(!szGroupMemberName[0])
			{
				ArraySetString(g_szGroupMembers[i-1], iGroup, "");
				break;
			}
			ArraySetString(g_szGroupMembers[i-1], iGroup, szGroupMemberName);
		}
	}
	else ArraySetString(g_szGroupMembers[iMemberId], iGroup, "");
	
	iMembersCount--;
	ArraySetCell(g_iGroupMembersCount, iGroup, iMembersCount);
	
	formatex(szVaultKey, 127, "%s-PlayerData", g_szPlayerName[id]);
	nvault_remove(g_iVault, szVaultKey);
	
	g_iPlayerGroup[id] = -1;
	
	ArrayGetString(g_szGroupName, iGroup, szGroupName, 19);
	
	UpdateInfo(id);
	
	print_msg(id, "Wyszles z grupy^x03 %s^x01.", szGroupName);
	
	return PLUGIN_CONTINUE;
}

public CheckLevel(iGroup)
{
	if(ArrayGetCell(g_iGroupLevel, iGroup) >= 61)
		return PLUGIN_CONTINUE;
	
	while(ArrayGetCell(g_iGroupExperience, iGroup) >= WriteLevelExp(ArrayGetCell(g_iGroupLevel, iGroup)))
	{
		new id;
		
		ArraySetCell(g_iGroupLevel, iGroup, ArrayGetCell(g_iGroupLevel, iGroup) + 1);
		ArraySetCell(g_iGroupAdditionalPoints[TO_ADD], iGroup, ArrayGetCell(g_iGroupAdditionalPoints[TO_ADD], iGroup) + 2);
		
		for(new i = 1; i <= g_iSlotsCount; i++)
		{
			if(!is_user_connected(i) ||  g_iPlayerGroup[i] != iGroup)
				continue;
			
			set_hudmessage(252, 252, 0, -1.0, 0.23, 0, 0.0, 1.1, 0.0, 0.0, -1);
			ShowSyncHudMsg(id, g_iHud, "Twoja grupa awansowala do %d poziomu!", ArrayGetCell(g_iGroupLevel, iGroup));
		}
	}
	
	for(new i = 1; i <= g_iSlotsCount; i++)
	{
		if(!is_user_connected(i) || g_iPlayerGroup[i] != iGroup)
			continue;
			
		UpdateInfo(i);
	}
	
	return PLUGIN_CONTINUE;
}

public UpdateInfo(id)
{
	if(g_iPlayerGroup[id] != -1)
	{
		static iGroup, iLevel, Float:fPercentExp, szGroupName[20], szInfo[512];
		
		iGroup = g_iPlayerGroup[id];
		iLevel = ArrayGetCell(g_iGroupLevel, iGroup);
		
		fPercentExp = float(ArrayGetCell(g_iGroupExperience, iGroup) - WriteLevelExp(iLevel-1)) / float(WriteLevelExp(iLevel) - WriteLevelExp(iLevel-1)) * 100.0;
		ArrayGetString(g_szGroupName, iGroup, szGroupName, 19);
		
		formatex(szInfo, 511, "Grupa : %s | Poziom: %d | Exp: %0.1f%%", szGroupName, iLevel, fPercentExp);
		
		message_begin(MSG_ONE, g_msgStatusText, {0,0,0}, id);
		write_byte(0);
		write_string(szInfo);
		message_end();
	}
	else
	{
		message_begin(MSG_ONE, g_msgStatusText, {0,0,0}, id);
		write_byte(0);
		write_string("");
		message_end();
	}
}
			
public FormatTop15()
{
	new iRankExp, iLastGroup, iRankedGroups, iMaxRank = (g_iGroupsCount > 15) ? 15 : g_iGroupsCount, iLen;
	new szGroupName[20], szGroupOwnerName[64];
	
	iLen = formatex(g_szTop15Motd, 1999, "<body bgcolor=#000000><font color=#FFB000><pre>");
	iLen += formatex(g_szTop15Motd[iLen], 1999 - iLen, "%2s. %22.22s | %6s | %13s | %22.22s | %12s | %12s | %12s^n", "#", "Nazwa grupy", "Poziom", "Doswiadczenie", "Wlasciciel", "Pkt. XP", "Pkt. Ataku", "Pkt. Obrony");
	
	for(new i = 0; i <= iMaxRank-1; i++)
	{
		for(new j = 0; j < g_iGroupsCount; j++)
		{
			if(ArrayGetCell(g_iGroupExperience, j) >= iRankExp)
			{
				if(!(iRankedGroups & (1<<j)))
				{
					iRankExp = ArrayGetCell(g_iGroupExperience, j);
					iLastGroup = j;
				}
			}
		}
		ArrayGetString(g_szGroupName, iLastGroup, szGroupName, 19);
		ArrayGetString(g_szGroupOwner, iLastGroup, szGroupOwnerName, 63);
		
		iLen += formatex(g_szTop15Motd[iLen], 1999 - iLen, "%2d. %22.22s | %6d | %13d | %22.22s | %12d | %12d | %12d^n", i + 1, szGroupName, ArrayGetCell(g_iGroupLevel, iLastGroup), 
		ArrayGetCell(g_iGroupExperience, iLastGroup), szGroupOwnerName, ArrayGetCell(g_iGroupAdditionalPoints[XP], iLastGroup),  ArrayGetCell(g_iGroupAdditionalPoints[ATTACK], iLastGroup), ArrayGetCell(g_iGroupAdditionalPoints[DEFENSE], iLastGroup));
		
		iRankedGroups |= (1<<iLastGroup);
		iRankExp = 0;
	}
}



public ReadGroupData(iGroup)
{
	new szVaultKey[128], szVaultData[1300], szGroupData[20][64], szGroupName[20];
	
	formatex(szVaultKey, 127, "1-%d-GroupData", iGroup);
	
	if(!nvault_get(g_iVault, szVaultKey, szGroupName, 19))
		return 0;
		
	ArrayPushString(g_szGroupName, szGroupName);
	
	formatex(szVaultKey, 127, "2-%d-GroupData", iGroup);
	nvault_get(g_iVault, szVaultKey, szVaultData, 1299);
	
	parse(szVaultData, szGroupData[1], 63,
	szGroupData[2], 63, szGroupData[3], 63, szGroupData[4], 63, szGroupData[5], 63,
	szGroupData[6], 63, szGroupData[7], 63, szGroupData[8], 63, szGroupData[9], 63,
	szGroupData[10], 63, szGroupData[11], 63, szGroupData[12], 63, szGroupData[13], 63,
	szGroupData[14], 63, szGroupData[15], 63, szGroupData[16], 63, szGroupData[17], 63,
	szGroupData[18], 63, szGroupData[19], 63);

	for(new i = 1; i < MAX_MEMBERS; i++)
		ArrayPushString(g_szGroupMembers[i], szGroupData[i]);
	
	formatex(szVaultKey, 127, "3-%d-GroupData", iGroup);
	nvault_get(g_iVault, szVaultKey, szGroupData[0], 63);
	ArrayPushString(g_szGroupOwner, szGroupData[0]);
	
	
	formatex(szVaultKey, 127, "4-%d-GroupData", iGroup);
	nvault_get(g_iVault, szVaultKey, szVaultData, 511);
	
	replace_all(szVaultData, 511, "#", " ");
	parse(szVaultData, szGroupData[0], 31, szGroupData[1], 31, szGroupData[2], 31, szGroupData[3], 31, szGroupData[4], 31, szGroupData[5], 31);
	
	ArrayPushCell(g_iGroupExperience, str_to_num(szGroupData[0]));
	ArrayPushCell(g_iGroupLevel, str_to_num(szGroupData[1])); 
	ArrayPushCell(g_iGroupAdditionalPoints[XP], str_to_num(szGroupData[2]));
	ArrayPushCell(g_iGroupAdditionalPoints[ATTACK], str_to_num(szGroupData[3]));
	ArrayPushCell(g_iGroupAdditionalPoints[DEFENSE], str_to_num(szGroupData[4]));
	ArrayPushCell(g_iGroupMembersCount, str_to_num(szGroupData[5]));
	ArrayPushCell(g_iGroupAdditionalPoints[TO_ADD], (str_to_num(szGroupData[1])-1)*2-str_to_num(szGroupData[2])-str_to_num(szGroupData[3])-str_to_num(szGroupData[4]));
	
	return 1;
}

public ReadUserData(id)
{
	new szVaultData[9], szVaultKey[128], szPlayerGroup[5], szIsGroupOwner[3];

	formatex(szVaultKey, 127, "%s-PlayerData", g_szPlayerName[id]);
	if(!nvault_get(g_iVault, szVaultKey, szVaultData, 8))
		return 0;
	
	strtok(szVaultData, szPlayerGroup, 4, szIsGroupOwner, 2, '#');
	
	g_iPlayerGroup[id] = str_to_num(szPlayerGroup);
	if(szIsGroupOwner[0] == '1')
		g_iIsGroupOwner[id] = 1;
	
	return 1;
}

public SaveGroupData(iGroup)
{
	new szVaultKey[128], szVaultData[1300], szMemberNameInQuotes[67];
	
	formatex(szVaultKey, 127, "1-%d-GroupData", iGroup);
	ArrayGetString(g_szGroupName, iGroup, szVaultData, 1299);
	nvault_set(g_iVault, szVaultKey, szVaultData);
	
	formatex(szVaultKey, 127, "2-%d-GroupData", iGroup);
	copy(szVaultData, 1299, "");
	
	for(new i = 1; i < 20; i++)
	{
		if(i < MAX_MEMBERS)
			ArrayGetString(g_szGroupMembers[i], iGroup, szMemberNameInQuotes, 63);
		else
			formatex(szMemberNameInQuotes, 66, " ");
		
		format(szMemberNameInQuotes, 66, " ^"%s^"", szMemberNameInQuotes);
		add(szVaultData, 1299, szMemberNameInQuotes, 66);
	}
	nvault_set(g_iVault, szVaultKey, szVaultData);
	
	formatex(szVaultKey, 127, "3-%d-GroupData", iGroup);
	ArrayGetString(g_szGroupOwner, iGroup, szVaultData, 1299);
	nvault_set(g_iVault, szVaultKey, szVaultData);
	
	
	formatex(szVaultKey, 127, "4-%d-GroupData", iGroup);
	formatex(szVaultData, 1299, "%d#%d#%d#%d#%d#%d", ArrayGetCell(g_iGroupExperience, iGroup), ArrayGetCell(g_iGroupLevel, iGroup), ArrayGetCell(g_iGroupAdditionalPoints[XP], iGroup), 
	ArrayGetCell(g_iGroupAdditionalPoints[ATTACK], iGroup), ArrayGetCell(g_iGroupAdditionalPoints[DEFENSE], iGroup), ArrayGetCell(g_iGroupMembersCount, iGroup));
	nvault_set(g_iVault, szVaultKey, szVaultData);
}

public SaveUserData(id)
{
	new szVaultData[9], szVaultKey[128];
	
	formatex(szVaultKey, 127, "%s-PlayerData", g_szPlayerName[id]);
	
	if(g_iPlayerGroup[id] == -1)
		return 0;
	
	formatex(szVaultData, 8, "%d#%d", g_iPlayerGroup[id], g_iIsGroupOwner[id]);
	
	nvault_set(g_iVault, szVaultKey, szVaultData);
	
	return 1;
}

stock WriteLevelExp(iLevel)
	return cod_get_level_xp(iLevel)*20;


stock print_msg(id, szText[], any:...)
{
	new szOutPut[256];
	
	vformat(szOutPut, 255, szText, 3);
	
	ColorChat(id, GREEN, "[COD:MW]^x01 %s", szOutPut);
	
	return 1;
}

stock get_user_index2(const szName[])
{
	new szPlayerName[64];
	
	for(new id = 1; id <= g_iSlotsCount; id++)
	{
		if(!is_user_connected(id))
			continue;
		
		get_user_name(id, szPlayerName, 63);
		
		if(equal(szPlayerName, szName))
			return id;
	}
	
	return 0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
