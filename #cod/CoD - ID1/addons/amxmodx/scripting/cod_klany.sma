#include < amxmodx >
#include < nvault >
#include < nvault_util >
#include < hamsandwich >
#include cstrike
#include codmod

/*-----------------KONFIGURACJA-----------------*/

#define PO_ILU_USUNAC 14 //po ilu dniach nieobecnosci czlonka z klanu ma go usuwac z klanu
#define MAX_POINTS 100 //ile maksymalnie punktow moze przydzielic klan
#define LIMIT_HAJS 15
#define LIMIT_SPEED 15
#define LIMIT_HP 25
#define MNOZNIK_EXPA 200
#define MNOZNIK_HAJS 200
#define MNOZNIK_SPEED 3
#define MNOZNIK_HP 2
#define MAX_MEMBERS 5

/*--------------KONIEC KONFIGURACJI--------------*/


enum guildInfoStruct {
	giName[33], 
	giGold, 
	giHajs, 
	giExp, 
	giSpeed,
	giHP, 
	Array: giMembers
}

enum
{
	grLeadder = 1,  
	grMember
}

enum playerInfoStruct {
	miRank, 
	miGuild[5]
}

new const prefix[] = "^4[KLAN]^1";

new giLastGuildIndex;

new gPlayerInfo[33][playerInfoStruct];

new Trie: gtGuilds //lista klanow - klucz to liczba w stringu
new Array: gaGuilds; //trzyma liste tych stringow
new Trie: gtPlayers; //lista graczy - klucz to nick

new cod_klan_wymagany_lvl, cod_klan_koszt_skill;
new gfKlanZmieniony;
new szNick[33][33]

public plugin_init()
{
	register_plugin("[CoD] Klany", "1.4", "RiviT");
	
	cod_klan_wymagany_lvl = register_cvar("cod_klan_wymagany_lvl", "100");
	cod_klan_koszt_skill = register_cvar("cod_klan_koszt_skill", "30");

      gfKlanZmieniony = CreateOneForward(find_plugin_byfile("QTM_CodMod.amxx"), "cod_klan_changed", FP_CELL, FP_STRING)
	
	RegisterHam(Ham_Spawn, "player", "hamPlayerSpawned", 1);
	RegisterHam(Ham_Killed, "player", "hamPlayerKilledPost", 1);

	register_clcmd("say /klan", "cmdKlan");
	
	register_clcmd("Nazwa_Klanu", "cmdGuildCreate");
}

public plugin_natives()
{
	register_native("cod_add_user_clan_gold", "DajZloto", 1)
	register_native("cod_get_user_clan", "MaKlan", 1)
}
	
public DajZloto(id, ile)
{
	new guildBuffer[guildInfoStruct];
      TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
	guildBuffer[giGold] += ile
	TrieSetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
}

public MaKlan(id)
	return TrieKeyExists(gtGuilds, gPlayerInfo[id][miGuild])

public client_connect(id) 
{
	get_user_name(id, szNick[id], 32);
	
	gPlayerInfo[id][miRank] = -1;
	copy(gPlayerInfo[id][miGuild], 4, "-1");
	
	new iRet;

	if(TrieKeyExists(gtPlayers, szNick[id])) //jesli nick jest w bazie danych to pobierz info gracza
	{
		TrieGetArray(gtPlayers, szNick[id], gPlayerInfo[id], playerInfoStruct);

		if(TrieKeyExists(gtGuilds, gPlayerInfo[id][miGuild]))
		{
			new guildBuffer[guildInfoStruct];

			TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
			ExecuteForward(gfKlanZmieniony, iRet, id, guildBuffer[giName]);

			cod_add_user_bonus_trim(id, guildBuffer[giSpeed] * MNOZNIK_SPEED)
			cod_add_user_bonus_health(id, guildBuffer[giHP] * MNOZNIK_HP)
			
			return;
		}
	}
      
	ExecuteForward(gfKlanZmieniony, iRet, id, "Brak");
}

public hamPlayerSpawned(id)
{
	if(!is_user_alive(id) || !TrieKeyExists(gtGuilds, gPlayerInfo[id][miGuild]))
		return;

	new guildBuffer[guildInfoStruct];

	TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
	
	cs_set_user_money(id, min(16000, cs_get_user_money(id)+(guildBuffer[giHajs] * MNOZNIK_HAJS)))
}

public hamPlayerKilledPost(iThis, iKiller)
{
	if(! is_user_connected(iKiller) || iThis == iKiller || !iKiller)
		return;

	if(! TrieKeyExists(gtGuilds, gPlayerInfo[iKiller][miGuild]))
		return;
      
      new guildBuffer[guildInfoStruct];

      TrieGetArray(gtGuilds, gPlayerInfo[iKiller][miGuild], guildBuffer, guildInfoStruct);

      if(!random(12))
      {
            new ile = random_num(1, 5)
            client_print(iKiller, print_center, "[KLAN] Zdobyles %i zlota dla klanu!", ile)
            
            guildBuffer[giGold] += ile
            TrieSetArray(gtGuilds, gPlayerInfo[iKiller][miGuild], guildBuffer, guildInfoStruct);
      }
      
      cod_add_user_xp(iKiller, guildBuffer[giExp] * MNOZNIK_EXPA)
}

public client_disconnect(id)
{
	if(!TrieKeyExists(gtPlayers, szNick[id])) return;
	
	new szBuffer[16];

	TrieSetArray(gtPlayers, szNick[id], gPlayerInfo[id], playerInfoStruct);
	
	formatex(szBuffer, 15, "%d %s", gPlayerInfo[id][miRank], gPlayerInfo[id][miGuild]);
	
	new vault = nvault_open("cod_members"); 
	nvault_set(vault, szNick[id], szBuffer);
	nvault_close(vault)
}

public plugin_precache()
{
	new vault = nvault_open("cod_members"); 
	nvault_prune(vault, 0, get_systime() - (86400 * PO_ILU_USUNAC));
	nvault_close(vault)

	vault = nvault_util_open("cod_clans"); 
	
	gtGuilds = TrieCreate();
	gaGuilds = ArrayCreate(33, 1);
	gtPlayers = TrieCreate();
	
	new iPos, szKey[33], szBuffer[64], temp;
	new iCount = nvault_util_count(vault);
	new guildBuffer[guildInfoStruct];

	new i;
	new szArgs[6][5]; 
	
	for(i = 1; i <= iCount; i++)
	{
		iPos = nvault_util_read(vault, iPos, szKey, 32, szBuffer, 63, temp);
						//szKey to nazwa gildii
		parse(szBuffer, 
				szArgs[0], 4, //index klanu
				szArgs[1], 4, //gold
				szArgs[2], 4, //hajs
				szArgs[3], 4, //xp
				szArgs[4], 4,//speed
				szArgs[5], 4 //hp
		);

		copy(guildBuffer[giName], 32, szKey);
		
		guildBuffer[giGold] = str_to_num(szArgs[1]);
		guildBuffer[giHajs] = str_to_num(szArgs[2]);
		guildBuffer[giExp] = str_to_num(szArgs[3]);
		guildBuffer[giSpeed] = str_to_num(szArgs[4]);
		guildBuffer[giHP] = str_to_num(szArgs[5]);
		guildBuffer[giMembers] = _: ArrayCreate(33, 1);

		temp = str_to_num(szArgs[0])
		if(temp > giLastGuildIndex)
			giLastGuildIndex = temp;
		
		TrieSetArray(gtGuilds, szArgs[0], guildBuffer, guildInfoStruct);
		ArrayPushString(gaGuilds, szArgs[0]);
	}
	
	nvault_util_close(vault);
	vault = nvault_util_open("cod_members"); 

	new playerBuffer[playerInfoStruct];
	iPos = 0;
	iCount = nvault_util_count(vault);
	
	for(i = 1; i <= iCount; i++)
	{
		iPos = nvault_util_read(vault, iPos, szKey, 32, szBuffer, 63, temp);

		parse(szBuffer, szArgs[0], 4, playerBuffer[miGuild], 4);
		
		playerBuffer[miRank] = str_to_num(szArgs[0]);
		
		if(TrieKeyExists(gtGuilds, playerBuffer[miGuild]))
		{
                  TrieGetArray(gtGuilds, playerBuffer[miGuild], guildBuffer, guildInfoStruct);
                  ArrayPushString(guildBuffer[giMembers], szKey);
		}

		TrieSetArray(gtPlayers, szKey, playerBuffer, playerInfoStruct);
	}
	
	nvault_util_close(vault);
}

public plugin_end()
{
	new szKey[5], szBuffer[64];
	new vault = nvault_open("cod_clans");
	new guildBuffer[guildInfoStruct];

	for(new i = 0 ; i < ArraySize(gaGuilds); i ++)
	{
		ArrayGetString(gaGuilds, i, szKey, 4);
		
		TrieGetArray(gtGuilds, szKey, guildBuffer, guildInfoStruct);
		TrieDeleteKey(gtGuilds, szKey);
		
		ArrayDestroy(guildBuffer[giMembers]);
		
		formatex(szBuffer, 63, "%s %d %d %d %d %d", 
					szKey, //index gildii
					guildBuffer[giGold], 
					guildBuffer[giHajs], 
					guildBuffer[giExp], 
					guildBuffer[giSpeed],
					guildBuffer[giHP]
		);

		nvault_set(vault, guildBuffer[giName], szBuffer);
	}
	
	TrieDestroy(gtGuilds)
	TrieDestroy(gtPlayers);
	ArrayDestroy(gaGuilds)

	nvault_close(vault);
}

public cmdKlan(id)
{
	new iMenu = menu_create("Klan:", "cmdGuildH");
	
	if(!TrieKeyExists(gtGuilds, gPlayerInfo[id][miGuild]))
		menu_additem(iMenu, "Stworz klan", "0");
	else
	{
		if(gPlayerInfo[id][miRank] == grLeadder)
		{
			menu_additem(iMenu, "\yDodaj\w czlonka", "1");
			menu_additem(iMenu, "\rUsun\w czlonka", "2");
                  menu_additem(iMenu, "\rRozwiaz klan", "3");
		}
		
		if(gPlayerInfo[id][miRank] == grMember)
			menu_additem(iMenu, "\rOpusc klan", "5");
			
            menu_additem(iMenu, "Skille klanu", "4");
		menu_additem(iMenu, "Czlonkowie klanu", "6");
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, iMenu);
}

public cmdGuildH(id, iMenux, iItem)
{
      if(iItem == MENU_EXIT)
      {
            menu_destroy(iMenux);
		return;
      }

	new szItem[3], tmp
	
	menu_item_getinfo(iMenux, iItem, tmp, szItem, 2, _, _, tmp);
	switch(str_to_num(szItem))
	{
		case 0:
		{
                  new wymog = get_pcvar_num(cod_klan_wymagany_lvl)
                  new obecny = cod_get_user_level(id)
			if(obecny < wymog)
				client_print_color(id, print_team_red, "%s Brakuje Ci %i lvli!", prefix, (wymog-obecny))
			else
				client_cmd(id, "messagemode Nazwa_Klanu");
		}
		case 1:
		{
			new guildBuffer[guildInfoStruct]
			TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);

			if(ArraySize(guildBuffer[giMembers]) >= MAX_MEMBERS)
			{
				client_print(id, print_center, "Klan posiada maksymalna liczbe czlonkow!")
				menu_destroy(iMenux);
				return;
			}
			
			new iMenu = menu_create("Klan - Dodaj czlonka:", "addMemberH");

			new szID[3], bool:jestChociazJeden;
			for(new i = 1; i <= get_maxplayers(); i++)
			{
				if(!is_user_connected(i) || TrieKeyExists(gtGuilds, gPlayerInfo[i][miGuild]))
					continue;

				num_to_str(i, szID, 2);
				jestChociazJeden = true
				
				menu_additem(iMenu, szNick[i], szID);
			}
			
			if(jestChociazJeden)
			{
				menu_setprop(iMenu, MPROP_EXITNAME, "Wroc");
				
				menu_display(id, iMenu);
			}
			else
				client_print(id, print_center, "Brak graczy bez klanu!")
		}
		case 2:
		{
			new iMenu = menu_create("Klan - Usun czlonka:", "removeMemberH");
			
			new guildBuffer[guildInfoStruct], szID[3], szNickx[33];
			TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
			for(new i = 0 ; i < ArraySize(guildBuffer[giMembers]); i ++)
			{
				num_to_str(i, szID, 2);
			
				ArrayGetString(guildBuffer[giMembers], i, szNickx, 32);
				menu_additem(iMenu, szNickx, szID);
			}
			
			menu_setprop(iMenu, MPROP_EXITNAME, "Wroc");
			
			menu_display(id, iMenu);
		}
		case 3:
		{
			new iMenu = menu_create("Klan - Czy na pewno chcesz rozwiazac klan?", "removeGuildH");
			
			menu_additem(iMenu, "Tak");
			menu_additem(iMenu, "Nie");
	
			menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
			
			menu_display(id, iMenu);
		}
		case 4: guildSkillsMenu(id);
		case 5:
		{
			new guildBuffer[guildInfoStruct];

			TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
			new szBuffer[33];
			for(new i = 0; i < ArraySize(guildBuffer[giMembers]); i++)
			{
				ArrayGetString(guildBuffer[giMembers], i, szBuffer, 32);
				if(equali(szBuffer, szNick[i]))
				{
					ArrayDeleteItem(guildBuffer[giMembers], i);
					break;
				}
			}
			
			TrieSetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
			formatex(gPlayerInfo[id][miGuild], 4, "-1");
			gPlayerInfo[id][miRank] = -1;
			
                  new iRet;
                  ExecuteForward(gfKlanZmieniony, iRet, id, "Brak");

			client_print_color(id, print_team_red, "%s Opusciles klan!", prefix);
		}
		case 6:
		{
			new guildBuffer[guildInfoStruct];
			new szBuffer[512], szNickx[33];
			add(szBuffer, 511, "<html><style>body{background-color:#000;color:#FF0505}</style><body><b>Czlonkowie klanu:</b><br>")
			TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
			for(new i = 0; i < ArraySize(Array: guildBuffer[giMembers]); i++)
			{
				ArrayGetString(Array: guildBuffer[giMembers], i, szNickx, 32);
				
                        add(szBuffer, 511, szNickx);
                        add(szBuffer, 511, "<br>");
			}
                  add(szBuffer, 511, "</body></html>")
			
			show_motd(id, szBuffer)
		}
	}

	menu_destroy(iMenux);
}

public addMemberH(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
            cmdKlan(id)
		return;
      }

	new szID[3], iTarget;
	menu_item_getinfo(iMenu, iItem, iTarget, szID, 2, _, _, iTarget);
	
	iTarget = str_to_num(szID);
	if(!is_user_connected(iTarget))
	{
            client_print_color(id, print_team_red, "%s Gracza nie ma na serwerze!", prefix);
		return;
      }

	sendGuildInvite(id, iTarget);
}

public removeMemberH(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
            cmdKlan(id)
		return;
      }

	new szID[3], szNick[33], szBuffer[64];
	menu_item_getinfo(iMenu, iItem, szBuffer[0], szID, 2, szNick, 32, szBuffer[0]);
	
	new guildBuffer[guildInfoStruct];
	TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
	
	new doWykopania = get_user_index(szNick)
      if(doWykopania == id) 
	{
            client_print_color(id, print_team_red, "%s Nie mozesz sam sie usunac!", prefix);
		return;
	}

	new vault;
	if(is_user_connected(doWykopania))
	{
		copy(gPlayerInfo[doWykopania][miGuild], 4, "-1");
		client_print_color(doWykopania, print_team_red, "%s Zostales wykopany z klanu !", prefix);
		cod_add_user_bonus_trim(doWykopania, -guildBuffer[giSpeed] * MNOZNIK_SPEED)
		cod_add_user_bonus_health(doWykopania, -guildBuffer[giHP] * MNOZNIK_HP)
            
            ExecuteForward(gfKlanZmieniony, vault, doWykopania, "Brak");
	}

	ArrayDeleteItem(guildBuffer[giMembers], str_to_num(szID));
	TrieDeleteKey(gtPlayers, szNick)
	
	vault = nvault_open("cod_members"); 
	nvault_remove(vault, szNick);
	nvault_close(vault)
	
	client_print_color(doWykopania, print_team_red, "%s Wykopales gracza^4 %s!", prefix, szNick);
}

public removeGuildH(id, iMenu, iItem)
{
	if(iItem == 1)
	{
            cmdKlan(id)
		return;
      }
	
	new guildBuffer[guildInfoStruct];
	TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);

      new vault, temp[33], index, i;
	vault = nvault_open("cod_members");
      for(i = 0 ; i < ArraySize(guildBuffer[giMembers]); i ++)
      {
            ArrayGetString(guildBuffer[giMembers], i, temp, 32);
            index = get_user_index(temp)
            if(is_user_connected(index))
            {
			nvault_remove(vault, temp);
			TrieDeleteKey(gtPlayers, temp)
                  cod_add_user_bonus_trim(index, -guildBuffer[giSpeed] * MNOZNIK_SPEED)
                  cod_add_user_bonus_health(index, -guildBuffer[giHP] * MNOZNIK_HP)
                  ExecuteForward(gfKlanZmieniony, temp[0], index, "Brak");
            }
      }
      
	ArrayDestroy(guildBuffer[giMembers]);
	nvault_close(vault);
	
	vault = nvault_open("cod_clans")
	nvault_remove(vault, guildBuffer[giName])
	nvault_close(vault);
	
	TrieDeleteKey(gtGuilds, gPlayerInfo[id][miGuild])

	for(i = 0; i < ArraySize(gaGuilds); i++)
	{
		ArrayGetString(gaGuilds, i, temp, 4);
		if(equali(temp, gPlayerInfo[id][miGuild]))
		{
			ArrayDeleteItem(gaGuilds, i)
			break;
		}
	}
	
	copy(gPlayerInfo[id][miGuild], 4, "-1");
	client_print_color(id, print_team_red, "%s Klan zostal usuniety !", prefix);
}

public guildSkillsMenu(id)
{
	new guildBuffer[guildInfoStruct];
      TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
      
      if(guildBuffer[giExp]+guildBuffer[giHajs]+guildBuffer[giSpeed]+guildBuffer[giHP] >= MAX_POINTS)
      {
            client_print_color(id, print_team_red, "%s Klan jest maksymalnie rozwiniety!", prefix);
            cmdKlan(id);
            return
      }
      
	new szBuffer[64];
      formatex(szBuffer, 63, "Klan - Skille (%i zlota/1pkt):", get_pcvar_num(cod_klan_koszt_skill));

      new iMenu = menu_create(szBuffer, "guildSkillsMenuH");

	new cb = menu_makecallback("menu_cb")
	
	formatex(szBuffer, 63, "Exp \r[%d]\d (+%i expa za frag)", guildBuffer[giExp], guildBuffer[giExp] * MNOZNIK_EXPA);
	menu_additem(iMenu, szBuffer);
	
	formatex(szBuffer, 63, "Hajs \r[%d]\d (+%i kasy za runde)", guildBuffer[giHajs], guildBuffer[giHajs] * MNOZNIK_HAJS);
	if(guildBuffer[giHajs] < LIMIT_HAJS)
            menu_additem(iMenu, szBuffer);
	else
            menu_additem(iMenu, szBuffer, _, _, cb);
      
      formatex(szBuffer, 63, "Speed \r[%d]\d (+%i punktow do kondycji)", guildBuffer[giSpeed], guildBuffer[giSpeed] * MNOZNIK_SPEED);
      if(guildBuffer[giSpeed] < LIMIT_SPEED)
            menu_additem(iMenu, szBuffer);
      else
           menu_additem(iMenu, szBuffer, _, _, cb);
      
      formatex(szBuffer, 63, "HP \r[%d]\d (+%i punktow do zdrowia)", guildBuffer[giHP], guildBuffer[giHP] * MNOZNIK_HP);
      if(guildBuffer[giHP] < LIMIT_HP)
            menu_additem(iMenu, szBuffer);
	else
            menu_additem(iMenu, szBuffer, _, _, cb);
	
	formatex(szBuffer, 63, "Wroc^n^nIlosc zlota: \y%d", guildBuffer[giGold]);
	menu_setprop(iMenu, MPROP_EXITNAME, szBuffer);
	menu_display(id, iMenu);
}

public menu_cb() return ITEM_DISABLED

public guildSkillsMenuH(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
            cmdKlan(id)
		menu_destroy(iMenu);
		return;
	}

	if(gPlayerInfo[id][miRank] == grMember)
	{
            guildSkillsMenu(id)
		client_print_color(id, print_team_red, "%s Nie masz uprawnien do kupna skilli!" , prefix);
		return;
	}
	
	new guildBuffer[guildInfoStruct];
	TrieGetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
	new koszt = get_pcvar_num(cod_klan_koszt_skill)
	if(guildBuffer[giGold] < koszt)
	{
            guildSkillsMenu(id)
		client_print_color(id, print_team_red, "%s Klan nie posiada %i zlota!" , prefix, koszt);
		return;
	}

	guildBuffer[giGold] -= koszt;
	
	switch(iItem)
	{
		case 0: guildBuffer[giExp] ++;
		case 1: guildBuffer[giHajs] ++;
		case 2:
		{
                  new szNickx[33], index;
			for(new i = 0 ; i < ArraySize(guildBuffer[giMembers]); i ++)
			{
                        ArrayGetString(guildBuffer[giMembers], i, szNickx, 32);
                        index = get_user_index(szNickx)
                        if(is_user_connected(index))
                              cod_add_user_bonus_trim(index, MNOZNIK_SPEED)
                  }

                  guildBuffer[giSpeed] ++;
		}
            case 3:
		{
                  new szNickx[33], index;
			for(new i = 0 ; i < ArraySize(guildBuffer[giMembers]); i ++)
			{
                        ArrayGetString(guildBuffer[giMembers], i, szNickx, 32);
                        index = get_user_index(szNickx)
                        if(is_user_connected(index))
                              cod_add_user_bonus_health(index, MNOZNIK_HP)
                  }

                  guildBuffer[giHP] ++;
		}
	}
	
	TrieSetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
	
	guildSkillsMenu(id);
}

public sendGuildInvite(iSender, iReciver)
{
	new szBuffer[64];
	new guildBuffer[guildInfoStruct];
	TrieGetArray(gtGuilds, gPlayerInfo[iSender][miGuild], guildBuffer, guildInfoStruct);
	
	formatex(szBuffer, 63, "Zostales zaproszony do klanu: %s", guildBuffer[giName]);
	new iMenu = menu_create(szBuffer, "sendGuildInviteH");
	
	num_to_str(iSender, szBuffer, 2);
	
	menu_additem(iMenu, "\yPrzyjmuje", szBuffer);
	menu_additem(iMenu, "\rOdrzucam", szBuffer);
	
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(iReciver, iMenu);
}

public sendGuildInviteH(id, iMenu, iItem)
{
	new szID[3], iSender;
	menu_item_getinfo(iMenu, iItem, iSender, szID, 2, _, _, iSender);
	
	iSender = str_to_num(szID);

	switch(iItem)
	{
		case 0:
		{
			new guildBuffer[guildInfoStruct];
			TrieGetArray(gtGuilds, gPlayerInfo[iSender][miGuild], guildBuffer, guildInfoStruct);
			ArrayPushString(guildBuffer[giMembers], szNick[id]);
			
			copy(gPlayerInfo[id][miGuild], 4, gPlayerInfo[iSender][miGuild]);
			gPlayerInfo[id][miRank] = grMember;
			
			new vault;
			ExecuteForward(gfKlanZmieniony, vault, id, guildBuffer[giName]);
			
			new szBuffer[16]
			formatex(szBuffer, 15, "%i %s", grMember, gPlayerInfo[iSender][miGuild]);
			
			vault = nvault_open("cod_members"); 
			nvault_set(vault, szNick[id], szBuffer);
			nvault_close(vault)

                  cod_add_user_bonus_trim(id, guildBuffer[giSpeed] * MNOZNIK_SPEED)
                  cod_add_user_bonus_health(id, guildBuffer[giHP] * MNOZNIK_HP)
			
			client_print_color(iSender, print_team_red, "%s %s przyja twoje zaproszenie", prefix, szNick[id]);
		}		
		case 1: client_print_color(iSender, print_team_red, "%s %s odrzucil twoje zaproszenie.", prefix, szNick);
	}
}

public cmdGuildCreate(id)
{
	if(TrieKeyExists(gtGuilds, gPlayerInfo[id][miGuild]))
		return;

	new szBuffer[33];
	read_argv(1, szBuffer, 32);
	remove_quotes(szBuffer);
	
	if(isGuildExists(szBuffer))
	{
		client_print_color(id, print_team_red, "%s Klan o nazwie^1 %s^4 juz istnieje!", prefix, szBuffer);
		return;
	}

	giLastGuildIndex ++;

	num_to_str(giLastGuildIndex, gPlayerInfo[id][miGuild], 4);
	gPlayerInfo[id][miRank] = grLeadder;
	TrieSetArray(gtPlayers, szNick[id], gPlayerInfo[id], playerInfoStruct)
	
	new temp[16]
	formatex(temp, 15, "%i %i", grLeadder, giLastGuildIndex);

	new vault = nvault_open("cod_members"); 
	nvault_set(vault, szNick[id], temp);
	nvault_close(vault)
	
	new guildBuffer[guildInfoStruct];
	copy(guildBuffer[giName], 32, szBuffer);
	guildBuffer[giMembers] = _:ArrayCreate(33);
	ArrayPushString(guildBuffer[giMembers], szNick[id]);
	TrieSetArray(gtGuilds, gPlayerInfo[id][miGuild], guildBuffer, guildInfoStruct);
	ArrayPushString(gaGuilds, gPlayerInfo[id][miGuild]);
	
      new iRet;
      ExecuteForward(gfKlanZmieniony, iRet, id, guildBuffer[giName]);
	
	client_print_color(id, print_team_red, "%s Klan o nazwie^4 %s^1 zostal zalozony!", prefix, guildBuffer[giName]);
}

stock isGuildExists(szName[])
{
	new szBuffer[33];
	new guildBuffer[guildInfoStruct];
	
	for(new i = 0 ; i < ArraySize(gaGuilds); i ++)
	{
		ArrayGetString(gaGuilds, i, szBuffer, 32);
		TrieGetArray(gtGuilds, szBuffer, guildBuffer, guildInfoStruct);
	
		if(equali(szName, guildBuffer[giName]))
			return true;
	}
	
	return false;
}