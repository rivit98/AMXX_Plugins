#include <amxmodx>
#include <reapi>
#include <sqlx>
#include <ColorChat>
#include <hamsandwich>

#define is_user_steam(%0) (REU_GetAuthtype(%0) == CA_TYPE_STEAM)
#define MAX 100
#define MAX_U 25
#define SHOW_HUD_INFO 672

#define _GetItemInfo_iId(%1)    rg_get_iteminfo(%1, ItemInfo_iId)
#define _SetItemInfo_iId(%1,%2)    rg_set_iteminfo(%1, ItemInfo_iId, %2)

native csgo_set_user_transfer_menu(id);
#if AMXX_VERSION_NUM < 183
	#define replace_string replace_all
#endif	

const UNQUEID = 32;

new IP[32];

new trzymany_skin[33]=0;

new skinName[MAX][33],
    skinModelsPath[MAX][48],
    skinWeaponid[MAX],
    skinChanceDrop[MAX],
    allSkins;
	
new playerKeepSkin[MAX_U][33], playerSkin[MAX][33], playerPassword[33][33];
new SyncHudObj, Handle:info, bool:connected;

new bool:playerLoaded[33],
	bool:playerAllowSaveDate[33],
	bool:playerGetFreeSkin[33],
	bool:playerRegister[33];

new playerCoin[33]=0,
	playerHeadShot[33]=0,
	playerKills[33]=0,
	playerDeads[33]=0,
	playerAssits[33]=0,
	playerRank[33]=0,
	playerTime[33]=0,
	playerChest[33]=0,
	playerKey[33]=0,
	playerGoldMedal[33]=0,
	playerSilverMedal[33]=0,
	playerBrownMedal[33]=0,
	playerOpenChest[33]=0,
	playerChoseSkin[33]=0,
	playerID[33];

new top_kills[15];
new top_deads[15];
new top_czas[15];
new top_assists[15];
new top_hs[15];
new name_top15[15][16];
new rank_position[33];
new rank_max=0;
new bool:oneTimeGetRank[33]=false;



enum CVARS
{ 
	host, 
	user, 
	pass, 
	db
};

new g_pCvars[CVARS];

new const RANK[][] = 
{
	{20, "Silver I"},
	{50, "Silver II"},
	{125, "Silver III"},
	{200, "Silver IV"},
	{350, "Silver elite"},
	{500, "Silver elite master"},
	{750, "Gold nova I"},
	{900, "Gold nova II"},
	{1000, "Gold nova III"},
	{1100, "Gold nova master"},
	{1300, "Master guardian I"},
	{2500, "Master guardian II"},
	{2700, "Master guardian elite"},
	{3000, "Distinguished master guardian"},
	{3500, "Legendary eagle"},
	{7500, "Legendary eagle master"},
	{10000, "Supreme master first class"},
	{999999, "THE GLOBAL ELITE"}
};

new const WEAPONS[][] = 
{
	{0, "Skin do Wszystkich Broni"},
	{29, "Skin do Kosy"},
	{28, "Skin do AK47"},
	{22, "Skin do M4A1"},
	{18, "Skin do AWP"},
	{15, "Skin do FAMAS"},
	{14, "Skin do GALI"},
	{16, "Skin do USP"},
	{17, "Skin do GLOCK18"},
	{26, "Skin do DEAGLE"},
	{30, "Skin do P90"},
	{3, "Skin do Scout"},
	{5, "Skin do XM1014"},
	{7, "Skin do MAC10"},
	{19, "Skin do MP5"},
	{20, "Skin do M249"},
	{21, "Skin do M3"}
};

new Float:kd_ratio_value[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 1.10, 1.15, 1.2, 1.2, 1.25, 1.3, 1.5, 1.7, 2.0, 2000.0};

public plugin_precache()
{
	new Line[128], Data[4][48], Len;
	allSkins++;

	if(file_exists("addons/amxmodx/configs/csgo/skins.cfg"))
	{
		for(new i; i < file_size("addons/amxmodx/configs/csgo/skins.cfg", 1); i++)
		{
			read_file("addons/amxmodx/configs/csgo/skins.cfg", i, Line, charsmax(Line), Len);
			
			if(strlen(Line) < 5 || Line[0] == ';')
				continue;

			parse(Line, Data[0], charsmax(Data[]), Data[1], charsmax(Data[]), Data[2], charsmax(Data[]), Data[3], charsmax(Data[]));
			skinWeaponid[allSkins] = str_to_num(Data[0]);
			copy(skinName[allSkins], charsmax(skinName), Data[1]);
			if(ValidMdl(Data[2]))
			{
				precache_model(Data[2]);
				copy(skinModelsPath[allSkins], charsmax(skinModelsPath), Data[2]);
			}
			skinChanceDrop[allSkins] = str_to_num(Data[3]);
			allSkins++;
		}
	}
}

public plugin_end()
	SQL_FreeHandle(info);

public plugin_init()
{
	register_plugin("[CSGO] System: Core", "1.0", "TyTuS")

	g_pCvars[host] = register_cvar("csgo_host_sql", 	"127.0.0.1");
	g_pCvars[user] = register_cvar("csgo_user_sql", 	"root",	    FCVAR_PROTECTED);
	g_pCvars[pass] = register_cvar("csgo_password_sql", 	"password", FCVAR_PROTECTED);
	g_pCvars[db]   = register_cvar("csgo_database_sql",   	"database");

	register_clcmd("say /menu", "menuCore");
	register_clcmd("say /rangi", "menuSystemRank")
	register_clcmd("say /skin", "menuCore");
	register_clcmd("say /domyslne", "domyslne");
	register_clcmd("say /top15","top15")
	register_clcmd("say /rank","rank_stats")

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "spawnPlayer", true);
	register_logevent("Round_End", 2, "1=Round_End");
	register_event("HLTV", "startRound", "a", "1=0", "2=0");
	register_message(get_user_msgid("SayText"),"handleSayText");
	SyncHudObj = CreateHudSyncObj();
	get_user_ip(0, IP, 32, 0);

	for(new i=1; i<sizeof(WEAPONS); i++)
	{
		new weaponname[22];
		get_weaponname(WEAPONS[i][0], weaponname, 21);
		RegisterHam(Ham_Item_Deploy, weaponname, "weaponSkinSetMdl", 1);
	}
}

public plugin_cfg()
{
	new szHost[64], szUser[64], szPass[64], szDB[64];
	get_pcvar_string(g_pCvars[host], szHost, charsmax(szHost));
	get_pcvar_string(g_pCvars[user], szUser, charsmax(szUser));
	get_pcvar_string(g_pCvars[pass], szPass, charsmax(szPass));
	get_pcvar_string(g_pCvars[db],   szDB,   charsmax(szDB));
	info = SQL_MakeDbTuple(szHost, szUser, szPass, szDB); 

	new len_full, temp_full[2024]; 
	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full, "CREATE TABLE IF NOT EXISTS `csgo` (`name` VARCHAR(48), `steam` VARCHAR(48), `ip` VARCHAR(48), `pass` VARCHAR(48), `register` TINYINT(1), `kills` INT(10), `deads` INT(10), `assists` INT(10), `hs` INT(10),");  
        len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full, "`gold_m` INT(10), `silver_m` INT(10), `browns_m` INT(10), `key` INT(10), `chest` INT(10), `coins` int(10), `ranga` INT(10), `time` INT(10),`first_game` INT(20),`last_game` INT(20), `issteam` TINYINT(1), `staty_1` VARCHAR(254), `skiny_1` VARCHAR(254), `skiny_2` VARCHAR(254))");   
	SQL_ThreadQuery(info, "ConnectSql_Handler", temp_full);
	set_task(5.0, "csgotop15");
}

public plugin_natives()
{
	register_native("csgo_set_user_coin", "setUserCoin", 1);
	register_native("csgo_get_user_coin", "getUserCoin", 1);

	register_native("csgo_set_user_key", "setUserKey", 1);
	register_native("csgo_get_user_key", "getUserKey", 1);

	register_native("csgo_set_user_chest", "setUserChest", 1);
	register_native("csgo_get_user_chest", "getUserChest", 1);

	register_native("csgo_set_user_skin", "setUserSkin", 1);
	register_native("csgo_get_user_skin", "getUserSkin", 1);

	register_native("csgo_set_user_hold_skin", "setUserHoldSkin", 1);
	register_native("csgo_get_user_hold_skin", "getUserHoldSkin", 1);

	register_native("csgo_set_user_medal_gold", "setUserGoldMedal", 1);
	register_native("csgo_get_user_medal_gold", "getUserGoldMedal", 1);

	register_native("csgo_set_user_medal_silver", "setUserSilverMedal", 1);
	register_native("csgo_get_user_medal_silver", "getUserSilverMedal", 1);

	register_native("csgo_set_user_medal_brown", "setUserBrownMedal", 1);
	register_native("csgo_get_user_medal_brown", "getUserBrownMedal", 1);

	register_native("csgo_set_user_assist", "setUserAssist", 1);
	register_native("csgo_get_user_assist", "getUserAssist", 1);

	register_native("csgo_get_user_kills", "getUserKills", 1);
	register_native("csgo_get_user_deads", "getUserDeads", 1);
	register_native("csgo_get_user_time", "getUserTime", 1);

	register_native("csgo_get_user_loaded", "getUseLoaded", 1);

	register_native("csgo_set_user_allow", "setUserAllow", 1);
	register_native("csgo_get_user_allow", "getUserAllow", 1);

	register_native("csgo_set_user_register", "setUserRegister", 1);
	register_native("csgo_get_user_register", "getUserRegister", 1);

	register_native("csgo_get_user_rank", "getUserRank", 1);
	register_native("csgo_get_user_player", "getUserPlayerId", 1);
	register_native("csgo_get_skin_count", "getSkinCount", 1);
	register_native("csgo_get_skin_name", "getSkinName", 1);
	register_native("csgo_get_skin_drop", "getSkinDrop", 1);
	register_native("csgo_get_skin_weaponid", "getSkinWeaponid", 1);
	
	register_native("csgo_get_max_rank", "getMaxRank", 1);

	register_native("csgo_get_user_password", "getUserPassword", 1);
	register_native("csgo_set_user_password", "setUserPassword", 1);
}

public handleSayText(msgId,msgDest,msgEnt)
{     
	new id = get_msg_arg_int(1);

	if(!is_user_connected(id))      
		return PLUGIN_CONTINUE;

	new szPrefix[64];

	if(is_user_connected(id))
	{
		new szTmp[192], szTmp2[192];
		get_msg_arg_string(2, szTmp, charsmax(szTmp));

		if(get_user_flags(id) & ADMIN_LEVEL_H)
		{
			formatex(szPrefix,charsmax( szPrefix ),"^x04[^x03 VIP ^x04|^x03 %s ^x04]", RANK[playerRank[id]][1]);
		} 
		else	formatex(szPrefix,charsmax( szPrefix ),"^x04[^x3 %s ^x04]", RANK[playerRank[id]][1]);

		if(!equal(szTmp,"#Cstrike_Chat_All"))
		{
			add(szTmp2, charsmax(szTmp2), "^x01");
			add(szTmp2, charsmax(szTmp2), szPrefix);
			add(szTmp2, charsmax(szTmp2), " ");
			add(szTmp2, charsmax(szTmp2), szTmp);
		}
		else
		{
			new szPlayerName[64];
			get_user_name(id, szPlayerName, charsmax(szPlayerName));

			get_msg_arg_string(4, szTmp, charsmax(szTmp)); //4. argument zawiera tre�� wys�anej wiadomo�ci
			set_msg_arg_string(4, ""); //Musimy go wyzerowa�, gdy� gra wykorzysta wiadomo�� podw�jnie co mo�e skutkowa� crash'em 191+ znak�w.

			add(szTmp2, charsmax(szTmp2), "^x01");
			add(szTmp2, charsmax(szTmp2), szPrefix);
			add(szTmp2, charsmax(szTmp2), "^x03 ");
			add(szTmp2, charsmax(szTmp2), szPlayerName);
			add(szTmp2, charsmax(szTmp2), "^x01 :  ");
			add(szTmp2, charsmax(szTmp2), szTmp)
		}
		set_msg_arg_string(2, szTmp2);
	}
	return PLUGIN_CONTINUE;
}
public csgotop15(id)
{
	SQL_ThreadQuery(info, "csgotop15_handler","SELECT * FROM `csgo` ORDER BY (`kills`-`deads`) DESC LIMIT 15")
	getMaxRankSql();
	return PLUGIN_CONTINUE;
}

public csgotop15_handler(failstate, Handle:query, error[], errnum, data[], size)
{
	if(failstate != TQUERY_SUCCESS)
	{
		log_amx("MySQL top15 Error: %s", error);
		return PLUGIN_CONTINUE;
	}
	new count = 0
	while(SQL_MoreResults(query))
	{
		SQL_ReadResult(query, 0, name_top15[count], 15);
		top_kills[count] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"kills"))
		top_deads[count] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"deads"))
		top_hs[count] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"hs"))
		top_czas[count] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"time"))
		top_assists[count] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"assists"))
		count++
		SQL_NextRow(query)
	}
	return PLUGIN_CONTINUE;
}
 
public top15(id)
{
	new msg[4015]=0
	new len=0, iMax=sizeof(msg) - 1
	
	len += formatex(msg[len], iMax-len, "<style>body{background:#000}tr{text-align:left} table{font-size:13px;color:#FFB000;padding:2px} h2{color:#FFF;font-family:Verdana}</style><body>")
	len += formatex(msg[len], iMax-len, "<table width=100%% border=0 align=center cellpadding=0 cellspacing=1>")
	len += formatex(msg[len], iMax-len, "<tr><th>#<th><b>Nick</b><th>Kills<th>HS<th>Deads<th>Assists<th>Godzin</tr>");

	new count = 1
	new nametop[16];
	for(new i = 0; i <= 14; i++)
	{
		if(equali(name_top15[i], ""))
			break;

		formatex(nametop, charsmax(nametop), name_top15[i]);
		mysql_escape_string(nametop, charsmax(nametop));

		len += formatex(msg[len], iMax-len, "<tr><td>%d<td><b>%s</b><td>%d<td>%d<td>%d</tr>%d</tr>%d</tr>", count, nametop, top_kills[i], top_hs[i], top_deads[i], top_assists[i], floatround(float(top_czas[i]/3600)));
		count++
	}
	show_motd(id, msg, "COD TOP 15 - By TyTuS")
	return PLUGIN_CONTINUE;
}
public startRound()	
{
	for(new id=1;id<=32;id++)
	{
		if(playerTime[id]<18000 && is_user_connected(id))
		{
			set_task(15.0, "showInfo", id);
		}

		if(playerTime[id]<72000 && is_user_connected(id) && !(get_user_flags(id) & ADMIN_LEVEL_H))
		{
			client_print(id,print_chat,"[!] skina lub vipa mozesz kupic wpisujac na say /sklepsms")
		}

		if(is_user_connected(id) && playerAllowSaveDate[id] && module_exists("MySQL") && !is_user_bot(id) && !is_user_hltv(id) && playerKills[id]>5 && !oneTimeGetRank[id])
		{
			getUserPostion(id);
		}
	}
}
public getUserPostion(id)
{
	new szTemppp[512]=0, data[1], Szname[33];
	data[0] = id;

	get_user_name(id, Szname, 32);
	mysql_escape_string(Szname, charsmax(Szname));

	formatex(szTemppp, charsmax(szTemppp), "SELECT COUNT(*) AS pozycja FROM `csgo` WHERE (`kills`-`deads`) >=  (SELECT Max(`kills`-`deads`) FROM `csgo` WHERE `name` = '%s')", Szname);
	SQL_ThreadQuery(info, "getUserPostionHandler", szTemppp, data, sizeof data);
}


public getUserPostionHandler(failstate, Handle:query, Error[], errnum, Data[], size)
{
	if(failstate != TQUERY_SUCCESS)
	{
		log_amx("MySQL user position error: %s", Error);
		return;
	}
	new id = Data[0];

	if(SQL_NumRows(query))
	{
		rank_position[id] = SQL_ReadResult(query, 0);
	}
	oneTimeGetRank[id]=true;
}
public getMaxRankSql()
{
	SQL_ThreadQuery(info, "getMaxRankSqlHandler","SELECT COUNT(*) FROM `csgo` WHERE 1")
	return PLUGIN_CONTINUE;
}

public getMaxRankSqlHandler(failstate, Handle:query, error[], errnum, data[], size)
{
	if(failstate != TQUERY_SUCCESS)
	{
		log_amx("MySQL max rank Error: %s", error);
		return PLUGIN_CONTINUE;
	}

	if(SQL_NumRows(query))
	{
		rank_max = SQL_ReadResult(query, 0);
	}
	return PLUGIN_CONTINUE;
}

public rank_stats(id)
{
	ColorChat(id, TEAM_COLOR, "[CS:GO]^x01 Posiadasz:^x04 %d^x01 /^x04 %d^x01 Pozycje^x04 %d^x01 Zabojstw,^x04 %d^x01 Smierci,^x04 %d^x01 Head Shotow,^x04 %d^x01 Asyst", rank_position[id], rank_max, playerKills[id], playerDeads[id], playerHeadShot[id], playerAssits[id]);
}

public menuSystemRank(id)
{
	new infomenu[128];
	new menu = menu_create("System Rank", "menuSystemRankHandle");
	for(new i=1; i < sizeof(RANK); i++)
	{
		formatex(infomenu, 127, "%s [\d od Killi: %d i K/D: %0.2f%\w]", RANK[i][1], RANK[i-1][0], kd_ratio_value[i-1]); 
		menu_additem(menu, infomenu);
	}
	menu_display(id, menu);
}

public menuSystemRankHandle(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

public spawnPlayer(id)
{
	if(!is_user_alive(id))
		return HC_BREAK;

	// if(playerKills[id]>50)
	// {
	// 	if(playerGetFreeSkin[id]==false)
	// 	{
	// 		playerGetFreeSkin[id]=true;
	// 		randomSkin(id);
	// 	}
	// }
	return HC_CONTINUE;
}

public randomSkin(id)
{
	new rWeapon = random_num(1, allSkins);
	new rNum = random_num(39, 100);

	if(skinChanceDrop[rWeapon] >= rNum)
	{
		playerSkin[rWeapon][id]++;
		new Name[33];
		get_user_name(id, Name, 32);
		ColorChat(0, TEAM_COLOR, "[CS:GO]^x01 Gracz %s^x01 Dostal^x03 %s^x04 [Darmowy Skin]", Name, skinName[rWeapon]);
		MsgToLog("[free skina] %s dostal %s", Name, skinName[rWeapon]);
	}
	else randomSkin(id)
}

public CBasePlayer_Killed(ofiara, zabojca)
{ 
	if(!is_user_connected(zabojca) || zabojca<1 || zabojca>32 || ofiara<1 || ofiara>32|| zabojca==ofiara || get_playersnum() < 3 )
		return HC_CONTINUE;

	new imiezabojcy[32], imieofiary[32], ip_ofiara[33], ip_attacker[33];
	get_user_name(zabojca, imiezabojcy, 31); 
	get_user_name(ofiara, imieofiary, 31);

	get_user_ip(ofiara, ip_ofiara, 32, 1);
	get_user_ip(zabojca, ip_attacker, 32, 1);

	if(equal(ip_ofiara, ip_attacker))
		return HC_CONTINUE;	

	playerKills[zabojca]++;
	playerDeads[ofiara]++;

	if(get_member(ofiara, m_bHeadshotKilled))
	{
		playerHeadShot[zabojca]++;
	}

	if(playerRank[zabojca]<7 && playerKills[zabojca] >= RANK[playerRank[zabojca]][0] && playerRank[zabojca] < 18)
	{
		playerRank[zabojca]++;
		ColorChat(0, TEAM_COLOR, "[CS:GO]^x01 Gracz^x04 %s^x03 Awansowal na^x04 %s", imiezabojcy, RANK[playerRank[zabojca]][1]); 
	}
	else if(playerKills[zabojca] >= RANK[playerRank[zabojca]][0] && playerRank[zabojca] < 18 && playerRank[zabojca]>6 && float(playerKills[zabojca])/float(playerDeads[zabojca]) > kd_ratio_value[playerRank[zabojca]])
	{
		playerRank[zabojca]++;
		ColorChat(0, TEAM_COLOR, "[CS:GO]^x01 Gracz^x04 %s^x03 Awansowal na^x04 %s", imiezabojcy, RANK[playerRank[zabojca]][1]); 
	}
	ColorChat(ofiara, GREEN, "[COD]^x01 Zabil Cie:^x03 %s^x04 |^x01(^x03 %s^x01)^x04 |^x01 K/D ratio:^x03 %0.2f%^x04 |^x03 Zdrowie: %d^x04 HP", imiezabojcy, RANK[playerRank[zabojca]][1], float(playerKills[zabojca])/float(playerDeads[zabojca]), get_user_health(zabojca));
	return HC_CONTINUE;	
}

public domyslne(id)
{
	for(new i; i <MAX_U; i++)
		playerKeepSkin[i][id] = 0;
	ColorChat(id, TEAM_COLOR, "[CS:GO]^x01 Pomyslnie ustawiono domyslne skiny");
}

public Round_End()
{
	for(new i=1; i<33;i++)
	{
		if(is_user_connected(i)) fix_skin(i);
		if(is_user_connected(i) && playerLoaded[i] && playerAllowSaveDate[i]) saveData(i);
	}
	client_print(0,print_chat,"Aby kupic slota lub vipa bez wychodzenia z serwa, wpisz /sklepsms");
}

public fix_skin(id)
{
	new name[33];
	get_user_name(id, name, 32);
	if(playerKey[id] <= -1){log_to_file("csgo_bug.log","%s Mial zbugowane klucze: %d",name, playerKey[id]);playerKey[id]=0;}
	if(playerChest[id] <= -1){ log_to_file("csgo_bug.log","%s Mial zbugowane skrzynie: %d",name, playerChest[id]); playerChest[id]=0;}
	if(playerKey[id] >=750){ log_to_file("csgo_bug.log","%s Mial zbugowane klucze: %d",name, playerKey[id]);playerKey[id]=0;}
	if(playerChest[id] >=750){ log_to_file("csgo_bug.log","%s Mial zbugowane skrzynie: %d",name, playerChest[id]); playerChest[id]=0;}
	if(playerCoin[id] <= -1){ log_to_file("csgo_bug.log","%s Mial zbugowane moenty: %d",name, playerCoin[id]);playerCoin[id]=0;}
	for(new i = 1; i < allSkins; i++)
	{
		if(playerSkin[i][id] == 0)
		continue;

		if(playerSkin[i][id] <= -1)
		{
			log_to_file("csgo_bug.log"," %s ma zbugowane skiny a dokladnie skina %s w ilosci %d", name, skinName[i], playerSkin[i][id]);
			playerSkin[i][id]=0;
			for(new k; k <MAX_U; k++)
			playerKeepSkin[k][id] = 0;
		}
	}
	for(new i=0;i<MAX_U;i++)
	{
		if(playerSkin[playerKeepSkin[i][id]][id]<=0)
		playerKeepSkin[i][id]=0;
	} 
	return PLUGIN_CONTINUE;
}

public weaponSkinSetMdl(pItem)
{
	new pPlayer = get_member(pItem, m_pPlayer);

	if(is_nullent(pItem) || !is_user_connected(pPlayer))
		return PLUGIN_CONTINUE;

	if(_GetItemInfo_iId(pItem) < UNQUEID)
	{
		_SetItemInfo_iId(pItem, get_user_userid(pPlayer) + UNQUEID);
		return PLUGIN_CONTINUE;
	}

	static ownerID, szName[33], szItemName[16], takeWeaponOnetime[33];
	ownerID = _GetItemInfo_iId(pItem) - UNQUEID;
    
	if(get_user_userid(pPlayer)==ownerID)
	{
		rg_get_iteminfo(pItem, ItemInfo_pszName, szItemName, charsmax(szItemName));

		for(new u=0; u<MAX_U;u++)
		{
			if(get_weaponid(szItemName) == skinWeaponid[playerKeepSkin[u][pPlayer]])
			{
				set_entvar(pPlayer, var_viewmodel, skinModelsPath[playerKeepSkin[u][pPlayer]]);
				trzymany_skin[pPlayer]=playerKeepSkin[u][pPlayer];
				//ColorChat(pPlayer, GREEN, "Podniosles swojego skina %s id %d | name %s", skinName[playerKeepSkin[u][pPlayer]], pItem, szItemName)
				return PLUGIN_CONTINUE;
			}
			trzymany_skin[pPlayer]=0;
		}
		return PLUGIN_CONTINUE;
	}
	trzymany_skin[pPlayer]=0;

	for (new i = 1; i <= MAX_CLIENTS; i++)
	{
		if(!is_user_connected(i) || ownerID!=i)
			return PLUGIN_CONTINUE;

		get_user_name(i, szName, charsmax(szName));
		rg_get_iteminfo(pItem, ItemInfo_pszName, szItemName, charsmax(szItemName));

		for(new u=0; u<MAX_U;u++)
		{
			if(get_weaponid(szItemName) == skinWeaponid[playerKeepSkin[u][i]])
			{
				set_entvar(pPlayer, var_viewmodel, skinModelsPath[playerKeepSkin[u][i]]);
				trzymany_skin[pPlayer]=playerKeepSkin[u][i];
				if(!takeWeaponOnetime[pPlayer])
				{
					ColorChat(pPlayer, GREEN, "Podniosles skina %s gracza %s | id %d | name %s", skinName[playerKeepSkin[u][i]], szName, pItem, szItemName)
					takeWeaponOnetime[pPlayer]=1;
				}
				return PLUGIN_CONTINUE;
			}
			trzymany_skin[pPlayer]=0;
		}	  
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

public menuCore(id)
{
	if(!playerLoaded[id])
	{
		client_print(id, 3, " Trwa wczytywanie danych");
		return PLUGIN_CONTINUE;
	}

	if(!playerAllowSaveDate[id])
	{
		ColorChat(id,GREEN,"Zrob /konto aby przegladac swoje skiny!")
	}

	new sklepsms_string[128], otworzskrzynie[128];
	new sMenu = menu_create("\d CS:GO \r By TyTuS", "MenuHandler");

	formatex(sklepsms_string, 127, "/Sklepsms \d(\ySkiny, Skrzynie, Klucze za SMS\d)^n^n\yIP Serva:\w%s \r<- dodaj do ulubionych | zapros znajomych!", IP);
	formatex(otworzskrzynie, charsmax(otworzskrzynie), "Otworz Skrzynie (\d40procent na drop skina\w)- [Kluczy: %d, Skrzyn: %d]", playerKey[id], playerChest[id])
	menu_additem(sMenu, "Skins");
	menu_additem(sMenu, otworzskrzynie);
	menu_additem(sMenu, "Wymien skina z innym graczem!");
	menu_additem(sMenu, "Jak Kupic Przelewem | PSC | PayPal - VIP'a | SKIN");
	menu_additem(sMenu, sklepsms_string);
	menu_display(id, sMenu);
	return PLUGIN_CONTINUE;
}

public MenuHandler(id, sMenu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(sMenu);
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		case 0:menuChoseWeapon(id);
		case 1:
		{
			if(playerChest[id] > 0 && playerKey[id] > 0)
			{
				playerChest[id]--;
				playerKey[id]--;
				chestOpen(id);
				menuCore(id);
				return PLUGIN_CONTINUE;
			}
			else ColorChat(id, TEAM_COLOR, "[CS:GO]^x01 Nie posiadasz Klucza Lub Skrzyni!");
		}
		case 2:csgo_set_user_transfer_menu(id);
		case 3:show_motd(id,"http://codstatystyki.gameclan.pl/rozne/przelew.html","CS:GO MOD --PRZELEW--");
		case 4:cmdExecute(id, "say /sklepsms");
     }
	return PLUGIN_CONTINUE;
}
	
public menuChoseWeapon(id)
{
	new string[128], menu = menu_create("\d Wybierz Bron (Skina)", "menuChoseWeaponHandle");
	for(new i=0; i<sizeof(WEAPONS); i++)
	{
		formatex(string, 127, "%s", WEAPONS[i][1]);
		menu_additem(menu, string);
	}
	menu_display(id, menu);
}

public menuChoseWeaponHandle(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new string[33], szText[128], menu = menu_create("Wybierz Skina: ", "menuCheckSkinHandle");

	for(new i = 1; i < allSkins; i++)
	{
		if(WEAPONS[item-1][0]==0)
		{
			formatex(string, 32, "%d %d", i, skinWeaponid[i]);

			if(playerSkin[i][id]>0)
			{
				formatex(szText, 127, "%s\w | (sztuk:\d %d\w)", skinName[i], playerSkin[i][id]);
			}
			else formatex(szText, 127, "\d%s\r (Brak)", skinName[i]);

			menu_additem(menu, szText, string);
		}
		else if(skinWeaponid[i]==WEAPONS[item-1][0])
		{
			formatex(string, 32, "%d %d", i, skinWeaponid[i]);

			if(playerSkin[i][id]>0)
			{
				formatex(szText, 127, "%s\w | (sztuk:\d %d\w)", skinName[i], playerSkin[i][id]);
			}
			else formatex(szText, 127, "\d%s\r (Brak)", skinName[i]);

			menu_additem(menu, szText, string);
		}
	}
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}
public menuCheckSkinHandle(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new access, callback, Data2[4][33], id_skina[33];
	menu_item_getinfo(menu, item, access, Data2[0], 32, Data2[1], 32, callback);

	parse(Data2[0], id_skina, 32);
	playerChoseSkin[id] = str_to_num(id_skina);
	new title_menu[128];
	formatex(title_menu, charsmax(title_menu), "Wybrales Skina: %s", skinName[playerChoseSkin[id]]); 
	new menu = menu_create(title_menu, "menuSkinOption");
	menu_additem(menu, "Zaloz na bron");
	menu_additem(menu, "Przywroc domyslny wyglad broni");
	menu_additem(menu, "Przekaz Graczowi [1x] (\rDostep:\w od 20 h Gry)");
	menu_additem(menu, "Sprawdz jak wyglada");
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}

public menuSkinOption(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}

	switch(item)
	{
		case 1:
		{
			if(playerSkin[playerChoseSkin[id]][id]<1)
			{
				ColorChat(id, RED,"Nie posiadasz tego skina, jesli chcesz mozesz go kupic^x04 -->^x03 /sklepsms")
				return PLUGIN_CONTINUE;
			}	
			for(new i=0; i<sizeof(WEAPONS); i++)
			{
				if(skinWeaponid[playerChoseSkin[id]]!=WEAPONS[i][0])
					continue;

				playerKeepSkin[i][id]=playerChoseSkin[id];  
				ColorChat(id, TEAM_COLOR, "[CS:GO]^x01 Zalozyles^x04 %s", skinName[playerChoseSkin[id]]);
			}
		}
		case 2: 
		{
			if(playerSkin[playerChoseSkin[id]][id]<1)
			{
				ColorChat(id, RED,"Nie posiadasz tego skina, jesli chcesz mozesz go kupic^x04 -->^x03 /sklepsms")
				return PLUGIN_CONTINUE;
			}	

			for(new i=0; i<sizeof(WEAPONS); i++)
			{
				if(skinWeaponid[playerChoseSkin[id]]!=WEAPONS[i][0])
					continue;

				playerKeepSkin[i][id]=0;  
				ColorChat(id, TEAM_COLOR, "[CS:GO]^x01 Ustawiles domyslny skin dla tej broni!");
			}
		}
		case 3:
		{
			if(playerSkin[playerChoseSkin[id]][id]<1)
			{
				ColorChat(id, RED,"Nie posiadasz tego skina, jesli chcesz mozesz go kupic^x04 -->^x03 /sklepsms")
				return PLUGIN_CONTINUE;
			}	
		} 
		case 4: checkLookSkin(id, playerChoseSkin[id]);
	}
	return PLUGIN_CONTINUE;
}

public checkLookSkin(id, id_skin)
{
	new Data[1536], tytul2[128],Len;
	Len = formatex(Data[Len], 1536 - Len, "<html><body bgcolor=Black><br>");
	Len += formatex(Data[Len], 1536 - Len, "<center><table frame=^"border^" width=^"840^" cellspacing=^"0^" bordercolor=#000000 style=^"color:#ffff00;text-align:center;^">"); 
	Len += formatex(Data[Len], 1536 - Len, "<tr>");
	Len += formatex(Data[Len], 1536 - Len, "<img src=^"http://codstatystyki.gameclan.pl/nowe/%d.jpg^"", id_skin);
	Len += formatex(Data[Len], 1536 - Len, "</tr>");
	Len += formatex(Data[Len], 1536 - Len,"</center></body></html>");
	format(tytul2, 127, "Tak wyglada skin %s", skinName[id_skin]);
	show_motd(id, Data, tytul2);
	return PLUGIN_CONTINUE;
}

public transferSkin(id)
{
	if(playerTime[id] < (20*60*60))
	{
		ColorChat(id, RED, "Potrzebujesz 20 godzin przegranych na serverze!!!");
		return PLUGIN_CONTINUE;
	}

	new menu = menu_create("Wybierz gracza:", "transferSkinHandle");
	new players[32], pnum, tempid;
	new szName[32], szTempid[10];
	get_players(players, pnum);

	for(new i; i<pnum; i++)
	{
		tempid = players[i];
		get_user_name(tempid, szName, charsmax(szName));
		num_to_str(tempid, szTempid, charsmax(szTempid));
		menu_additem(menu, szName, szTempid, 0);
	}
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public transferSkinHandle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	new tempid = str_to_num(data);
	new name[33], tempname[33];
	get_user_name(tempid, tempname, 32);
	get_user_name(id, name, 32);

	if(tempid==id)
		return PLUGIN_CONTINUE;
	
	if(!playerAllowSaveDate[tempid])
	{
		ColorChat(id,RED,"Ten gracz musi sie zalogowac na swoje konto!");
		return PLUGIN_CONTINUE;
	}
	playerSkin[playerChoseSkin[id]][id]--;
	playerSkin[playerChoseSkin[id]][tempid]++;

	if(playerSkin[playerChoseSkin[id]][id]<1)
	{
		for(new i=0; i<sizeof(WEAPONS); i++)
		{
			if(skinWeaponid[playerChoseSkin[id]]!=WEAPONS[i][0])
				continue;

			playerKeepSkin[i][id]=0;  
			ColorChat(id, TEAM_COLOR, "[CS:GO]^x01 Ustawiono Ci domyslny skin, poniewaz przekazales komus tego skina!");
		}
	}
	ColorChat(id, TEAM_COLOR, "[CS:GO]^x01 Przekazales^x04 %s^x01 Skina^x04 %s", tempname, skinName[playerChoseSkin[id]]);
	ColorChat(tempid, TEAM_COLOR, "[CS:GO]^x01 Otrzymales^x04 %s^x01 od^x04 %s", skinName[playerChoseSkin[id]], name);
	return PLUGIN_CONTINUE;
}

public showPlayerInfo(id)
{
	id -= SHOW_HUD_INFO;

	if(!is_user_connected(id))
	{
		remove_task(id+SHOW_HUD_INFO);
		return PLUGIN_CONTINUE;
	}
	if(!is_user_alive(id))
	{
		new target = get_entvar(id, EntVars:var_iuser2);

		if(!target)
			return PLUGIN_CONTINUE;	

		set_hudmessage(0, 255, 0, 0.02, 0.19, 0, 0.0, 0.3, 0.0, 0.0);
		ShowSyncHudMsg(id, SyncHudObj, "Ranga : %s^nPostep : %d/%d^nK/D ratio: %0.2f%^nMonety : %d^nSkin : %s", RANK[playerRank[target]][1],playerKills[target], RANK[playerRank[target]][0], float(playerKills[target])/float(playerDeads[target]), playerCoin[target], trzymany_skin[target] ? skinName[trzymany_skin[target]] : "Brak");
		return PLUGIN_CONTINUE;
	}
	set_hudmessage(0, 255, 0, 0.02, 0.19, 0, 0.0, 0.3, 0.0, 0.0);
	ShowSyncHudMsg(id, SyncHudObj, "Ranga : %s^nPostep : %d/%d^nK/D ratio: %0.2f%^nMonety : %d^nSkin : %s", RANK[playerRank[id]][1],playerKills[id], RANK[playerRank[id]][0], float(playerKills[id])/float(playerDeads[id]), playerCoin[id], trzymany_skin[id] ? skinName[trzymany_skin[id]] : "Brak");
	return PLUGIN_CONTINUE;
}

public chestOpen(id)
{
	new rWeapon = random_num(1, allSkins);
	new rNum = random_num(1, 100);
	
	if(skinChanceDrop[rWeapon] >= rNum)
	{
		if(40 >= random_num(1, 100))
		{
			new Name[33];
			get_user_name(id, Name, charsmax(Name));
			
			playerSkin[rWeapon][id]++;
			playerOpenChest[id]++;

			ColorChat(0, TEAM_COLOR, "[CS:GO]^x01 Gracz^x04 %s^x01 znalazl w skrzyni^x03 %s^x01 szansa na drop:^x03 %d%", Name, skinName[rWeapon], skinChanceDrop[rWeapon]);
			MsgToLog("[CS:GO] %s znalazl w skrzyni %s", Name, skinName[rWeapon]);
			menuCore(id);
		}
		else
		{
			ColorChat(id, GREEN, "[CSGO:MOD]^x03 Niestety w skrzynce nie bylo zadnego skina!");
			menuCore(id);
		}

	}
	else chestOpen(id);
}

public client_putinserver(id)
{
	resetData(id);
	readData(id);
	if(!task_exists(id+SHOW_HUD_INFO))
		set_task(0.2, "showPlayerInfo", id+SHOW_HUD_INFO, _, _, "b");
}
public client_disconnect(id)
{
	saveData(id);
	resetData(id);
}

public resetData(id)
{
	for(new i=0; i < MAX_U; i++)
		playerKeepSkin[i][id] = 0;

	for(new i=0; i < MAX; i++)
		playerSkin[i][id] = 0;

	playerLoaded[id]=false;
	playerAllowSaveDate[id]=false;
	playerPassword[id]="";
	playerRegister[id]=false;
	playerGetFreeSkin[id]=false;
	playerOpenChest[id]=0;
	playerKey[id]=0;
	playerChest[id]=0;
	playerHeadShot[id]=0;
	playerKills[id]=0;
	playerDeads[id]=0;
	playerAssits[id]=0;
	playerRank[id]=0;
	playerTime[id]=0;
	playerCoin[id]=0;
	playerGoldMedal[id]=0;
	playerSilverMedal[id]=0;
	playerBrownMedal[id]=0;
	playerChoseSkin[id]=0;
	trzymany_skin[id]=0;
	rank_position[id]=0;
	playerID[id]=0;
	remove_task(id+SHOW_HUD_INFO);
}
public showInfo(id)
	ColorChat(id, GREEN, "Witaj na^x03 CSGO:MOD^x01 jestes pierwszy raz? wpisz^x04 /menu^x03 Zapisz IP^x04 %s", IP);

public saveData(id)
{
	if(!connected || !is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || !playerLoaded[id] || !playerAllowSaveDate[id] || !module_exists("MySQL"))
		return PLUGIN_CONTINUE;

	new len_full, temp_full[2048];
	new name[33], steam[33], ipgr[33];
	get_user_authid(id, steam, charsmax(steam));
	get_user_ip(id, ipgr, 32, 1);
	get_user_name(id, name, charsmax(name));

	mysql_escape_string(name, charsmax(name));

	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full, "UPDATE `csgo` SET `steam` = '%s', `ip` = '%s', `pass` = '%s', `register` = '%i', `kills` = '%i', `deads` = '%i', `assists` = '%i', `hs` = '%i'", steam, ipgr, playerPassword[id], playerRegister[id], playerKills[id], playerDeads[id], playerAssits[id], playerHeadShot[id]);
	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full, ", `coins` = '%i', `gold_m` = '%i', `silver_m` = '%i', `browns_m` = '%i', `key` = '%i', `chest` = '%i',`ranga` = '%i', `time` = '%i', `last_game` = '%d', `issteam` = '%d'", playerCoin[id], playerGoldMedal[id], playerSilverMedal[id], playerBrownMedal[id], playerKey[id], playerChest[id], playerRank[id], playerTime[id]+get_user_time(id,1), get_systime(), is_user_steam(id));

	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full, ", `staty_1` = '"); 
	
	for(new i=0; i <MAX_U; i++)
	{
		len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full,"#%i", playerKeepSkin[i][id]);
	}
	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full, "#%i#%i', `skiny_1` ='",playerGetFreeSkin[id], playerOpenChest[id])
	
	for(new i = 0; i <60; i++)
	{
		len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full,"#%i", playerSkin[i][id]);
	}
	

	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full,"', `skiny_2` ='");

	for(new i = 60; i <MAX; i++)
	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full,"#%i", playerSkin[i][id]);

	len_full += formatex(temp_full[len_full], charsmax(temp_full)-len_full,"' WHERE `name` = '%s'", name);
	SQL_ThreadQuery(info, "saveDataHandler", temp_full);
	return PLUGIN_CONTINUE;
}

public saveDataHandler(failstate, Handle:query, error[], errnum, data[], size)
{
	if(failstate != TQUERY_SUCCESS)
	{
		log_to_file("csgo_error_sql.log","update error blad %s", error);
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}
public readData(id)
{
	if(!connected || !is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || playerLoaded[id] || !module_exists("MySQL"))
		return PLUGIN_CONTINUE;

	new data[1], temp[2048], name[33];
	data[0] = id;

	get_user_name(id, name, charsmax(name));
	mysql_escape_string(name, charsmax(name));

	formatex(temp, charsmax(temp), "SELECT * FROM `csgo` WHERE `name` = '%s'", name);
	SQL_ThreadQuery(info, "readDataHandler", temp, data, sizeof(data));
	return PLUGIN_CONTINUE;
}
public readDataHandler(failstate, Handle:query, error[], errnum, data[], size)
{
	new id = data[0];

	if(failstate != TQUERY_SUCCESS)
	{
		log_to_file("csgo_error_sql.log","Wczytywanie error blad %s",error);
		return PLUGIN_CONTINUE;
	}

	if(SQL_MoreResults(query))
	{
		new steamid_gracza[33], ip_gracza[33];
		SQL_ReadResult(query, 1, steamid_gracza, 32);
		SQL_ReadResult(query, 2, ip_gracza, 32);
		SQL_ReadResult(query, 3, playerPassword[id], 32);
		playerRegister[id] = bool:SQL_ReadResult(query, SQL_FieldNameToNum(query,"register"))
		playerKills[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"kills"))
		playerDeads[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"deads"))
		playerAssits[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"assists"))
		playerHeadShot[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"hs"))
		playerKey[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"key"))
		playerChest[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"chest"))
		playerCoin[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"coins"))
		playerRank[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"ranga"))
		playerTime[id] = SQL_ReadResult(query, SQL_FieldNameToNum(query,"time"))

		new staty_1[256], skiny_1[512], skiny_2[512]; /// jesli to przechowuje kazdego gracza kazdego jego skina to znaczy ze przekracza tablice 32 gracze * 60 skinow = 2k
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "staty_1"), staty_1, charsmax(staty_1));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "skiny_1"), skiny_1, charsmax(skiny_1));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "skiny_2"), skiny_2, charsmax(skiny_2));

		replace_all(staty_1, charsmax(staty_1), "#", " ");
		replace_all(skiny_1, charsmax(skiny_1), "#", " ");
		replace_all(skiny_2, charsmax(skiny_2), "#", " ");

		new staty[27][8];
		parse(staty_1, staty[0], charsmax(staty[]), staty[1], charsmax(staty[]), staty[2], charsmax(staty[]), staty[3], charsmax(staty[]), staty[4], charsmax(staty[]), staty[5], charsmax(staty[]), staty[6], charsmax(staty[]), staty[7], charsmax(staty[]),
		staty[8], charsmax(staty[]), staty[9], charsmax(staty[]), staty[10], charsmax(staty[]), staty[11], charsmax(staty[]), staty[12], charsmax(staty[]), staty[13], charsmax(staty[]), staty[14], charsmax(staty[]), staty[15], charsmax(staty[]),
		staty[16], charsmax(staty[]), staty[17], charsmax(staty[]));

		for(new i=0; i <MAX_U; i++)
		{
			playerKeepSkin[i][id] = str_to_num(staty[i]);
		}
		playerGetFreeSkin[id]= bool:str_to_num(staty[25]);
		playerOpenChest[id]=str_to_num(staty[26]);

		new skinr1[MAX][8];
		parse(skiny_1, skinr1[0], charsmax(skinr1[]), skinr1[1], charsmax(skinr1[]), skinr1[2], charsmax(skinr1[]), skinr1[3], charsmax(skinr1[]), skinr1[4], charsmax(skinr1[]), skinr1[5], charsmax(skinr1[]), skinr1[6], charsmax(skinr1[]), skinr1[7], charsmax(skinr1[]), skinr1[8], charsmax(skinr1[]), skinr1[9], charsmax(skinr1[]), skinr1[10], charsmax(skinr1[]), skinr1[11], charsmax(skinr1[]),skinr1[12], charsmax(skinr1[]), skinr1[13], charsmax(skinr1[]),
		skinr1[14], charsmax(skinr1[]), skinr1[15], charsmax(skinr1[]), skinr1[16], charsmax(skinr1[]), skinr1[17], charsmax(skinr1[]), skinr1[18], charsmax(skinr1[]), skinr1[19], charsmax(skinr1[]), skinr1[20], charsmax(skinr1[]), skinr1[21], charsmax(skinr1[]), skinr1[22], charsmax(skinr1[]), skinr1[23], charsmax(skinr1[]), skinr1[24], charsmax(skinr1[]), skinr1[25], charsmax(skinr1[]), skinr1[26], charsmax(skinr1[]), skinr1[27], charsmax(skinr1[]),
		skinr1[28], charsmax(skinr1[]), skinr1[29], charsmax(skinr1[]), skinr1[30], charsmax(skinr1[]), skinr1[31], charsmax(skinr1[]), skinr1[32], charsmax(skinr1[]), skinr1[33], charsmax(skinr1[]), skinr1[34], charsmax(skinr1[]), skinr1[35], charsmax(skinr1[]), skinr1[36], charsmax(skinr1[]), skinr1[37], charsmax(skinr1[]), skinr1[38], charsmax(skinr1[]), skinr1[39], charsmax(skinr1[]), skinr1[40], charsmax(skinr1[]), skinr1[41], charsmax(skinr1[]),
		skinr1[42], charsmax(skinr1[]), skinr1[43], charsmax(skinr1[]), skinr1[44], charsmax(skinr1[]), skinr1[45], charsmax(skinr1[]), skinr1[46], charsmax(skinr1[]), skinr1[47], charsmax(skinr1[]), skinr1[48], charsmax(skinr1[]), skinr1[49], charsmax(skinr1[]), skinr1[50], charsmax(skinr1[]), skinr1[51], charsmax(skinr1[]), skinr1[52], charsmax(skinr1[]), skinr1[53], charsmax(skinr1[]), skinr1[54], charsmax(skinr1[]), skinr1[55], charsmax(skinr1[]),
		skinr1[56], charsmax(skinr1[]), skinr1[57], charsmax(skinr1[]), skinr1[58], charsmax(skinr1[]), skinr1[59], charsmax(skinr1[]));

		for(new i = 0; i < 60; i++)
			playerSkin[i][id] = str_to_num(skinr1[i]);

		parse(skiny_2, skinr1[60], charsmax(skinr1[]), skinr1[61], charsmax(skinr1[]),skinr1[62], charsmax(skinr1[]), skinr1[63], charsmax(skinr1[]), skinr1[64], charsmax(skinr1[]), skinr1[65], charsmax(skinr1[]), skinr1[66], charsmax(skinr1[]), skinr1[67], charsmax(skinr1[]), skinr1[68], charsmax(skinr1[]), skinr1[69], charsmax(skinr1[]), skinr1[70], charsmax(skinr1[]), skinr1[71], charsmax(skinr1[]), skinr1[72], charsmax(skinr1[]),
		skinr1[73], charsmax(skinr1[]), skinr1[74], charsmax(skinr1[]), skinr1[75], charsmax(skinr1[]), skinr1[76], charsmax(skinr1[]), skinr1[77], charsmax(skinr1[]), skinr1[78], charsmax(skinr1[]), skinr1[79], charsmax(skinr1[]), skinr1[80], charsmax(skinr1[]), skinr1[81], charsmax(skinr1[]), skinr1[82], charsmax(skinr1[]), skinr1[83], charsmax(skinr1[]), skinr1[84], charsmax(skinr1[]), skinr1[85], charsmax(skinr1[]),
		skinr1[86], charsmax(skinr1[]), skinr1[87], charsmax(skinr1[]), skinr1[88], charsmax(skinr1[]), skinr1[89], charsmax(skinr1[]), skinr1[90], charsmax(skinr1[]), skinr1[91], charsmax(skinr1[]), skinr1[92], charsmax(skinr1[]), skinr1[93], charsmax(skinr1[]), skinr1[94], charsmax(skinr1[]), skinr1[95], charsmax(skinr1[]), skinr1[96], charsmax(skinr1[]), skinr1[97], charsmax(skinr1[]), skinr1[98], charsmax(skinr1[]),
		skinr1[99], charsmax(skinr1[]));

		for(new i = 60; i < MAX; i++)
			playerSkin[i][id] = str_to_num(skinr1[i]);

		new ip[33], steamaa[33], hasloo[33];
		get_user_ip(id, ip, 32, 1);
		get_user_authid(id, steamaa, 32);
		get_user_info(id, "_csgomod", hasloo, charsmax(hasloo));

		playerLoaded[id] = true;

		if(playerRegister[id])
		{
			if(equali(steamaa,steamid_gracza) || equali(ip_gracza, ip) || equali(hasloo, playerPassword[id]))
			{
				playerAllowSaveDate[id]=true;
			}
			else 
			{
				playerAllowSaveDate[id]=false;
			}
		}
		else
		{
			playerAllowSaveDate[id]=false;
		}
	}
	else
	{
		new data[1];
		data[0] = id;

		if(!connected || !is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || playerLoaded[id] || !module_exists("MySQL"))
			return PLUGIN_CONTINUE;

		new temp[2048], steam[33], name[64], ip[33];
		get_user_authid(id, steam, charsmax(steam));
		get_user_name(id, name, charsmax(name));
		get_user_ip(id, ip, 32, 1);
		mysql_escape_string(name, charsmax(name));

		format(temp, charsmax(temp), "INSERT INTO `csgo` (name, steam, ip, pass, register, issteam, first_game, staty_1, skiny_1, skiny_2) VALUES('%s', '%s', '%s', '', '0', '%i', '%d', '#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0', '#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0', '#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0')",
		name, steam, ip, is_user_steam(id), get_systime()); 
		SQL_ThreadQuery(info, "readDataHandler2", temp, data, sizeof(data));
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}
public readDataHandler2(failstate, Handle:query, error[], errnum, data[], size)
{
	new id = data[0];

	if(failstate != TQUERY_SUCCESS)
	{
		playerLoaded[id] = false;
		playerAllowSaveDate[id]=false;
		new name[33];
		get_user_name(id, name,32);
		log_to_file("csgo_error_sql.log","Wczytywanie dla %s blad %s", name, error);
		return PLUGIN_CONTINUE;
	}
	playerAllowSaveDate[id]=false;
	playerLoaded[id] = true;
	return PLUGIN_CONTINUE;
}

public ConnectSql_Handler(failstate, Handle:query, error[], errnum, data[], size)
{
	if(failstate != TQUERY_SUCCESS)
	{
		connected = false;
		log_to_file("csgo_error_sql.log","Connect error: %s", error);
		return PLUGIN_CONTINUE;
	}
	connected = true;
	return PLUGIN_CONTINUE;
}

public setUserCoin(id, wartosc)
{
	playerCoin[id] = wartosc;
}

public getUserCoin(id)
	return playerCoin[id];

public setUserKey(id, wartosc)
{
	playerKey[id] = wartosc;
}

public getUserKey(id)
	return playerKey[id];

public setUserChest(id, wartosc)
{
	playerChest[id] = wartosc;
}

public getUserChest(id)
	return playerChest[id];

public setUserSkin(id, skin_id, wartosc)
{
	playerSkin[skin_id][id]=wartosc;
}

public getUserSkin(id, skin_id)
	return playerSkin[skin_id][id];

public getUserHoldSkin(id, weaponid)
	return playerKeepSkin[weaponid][id];

public setUserHoldSkin(id, weaponid, wartosc)
{
	playerKeepSkin[weaponid][id]=wartosc;
}
public setUserGoldMedal(id, wartosc)
{
	playerGoldMedal[id]=wartosc;
}

public getUserGoldMedal(id)
	return playerGoldMedal[id];

public setUserSilverMedal(id, wartosc)
{
	playerSilverMedal[id]=wartosc;
}

public getUserSilverMedal(id)
	return playerSilverMedal[id];

public setUserBrownMedal(id, wartosc)
{
	playerBrownMedal[id]=wartosc;
}

public getUserBrownMedal(id)
	return playerBrownMedal[id];	 

public setUserAssist(id, wartosc)
{
	playerAssits[id]=wartosc;
}
public getUserAssist(id)
	return playerAssits[id];

public getUserKills(id)
	return playerKills[id];

public getUserDeads(id)
	return playerDeads[id];

public getUserTime(id)
	return playerTime[id];
		
public getUseLoaded(id)
	return playerLoaded[id];

public setUserAllow(id, bool:wartosc)
{
	playerAllowSaveDate[id]=wartosc;
}

public getUserAllow(id)
	return playerAllowSaveDate[id];
		 
public setUserRegister(id, bool:wartosc)
{
	playerRegister[id]=wartosc;
}
		 
public getUserRegister(id)
	return playerRegister[id];

public getSkinCount()
	return allSkins;

public getSkinName(skin_id, Return[], len)
{
	if(skin_id <= allSkins)
	{
		param_convert(2);
		copy(Return, len, skinName[skin_id]);
	}
}
public getSkinDrop(skin_id)
	return skinChanceDrop[skin_id];

public getUserRank(id)
	return rank_position[id];

public getUserPlayerId(id)
	return playerID[id];

public getMaxRank()
	return rank_max;	

public getUserPassword(id, Return[], len)
{
	if(playerLoaded[id]){
		param_convert(2);
		copy(Return, len, playerPassword[id]);
	}
}
		 
public setUserPassword(id, const nazwa[])
{
   param_convert(2);
   copy(playerPassword[id], 32, nazwa)
   playerRegister[id]=true;
   playerAllowSaveDate[id]=true;
   saveData(id);
}
public getSkinWeaponid(skin_id)
	return skinWeaponid[skin_id];

MsgToLog(szRawMessage[], any:... ) 
{
	static fp
	new File[64], szTemp[20];
	formatex(File, charsmax(File), "addons/amxmodx/logs/csgo")

	if(!dir_exists(File)) mkdir(File);

	get_time("%Y_%m_%d", szTemp, charsmax(szTemp));
	formatex(File, charsmax(File), "%s/csgo_system_core_%s.log", File, szTemp);
	new szMessage[192], Data[16]
	vformat(szMessage, charsmax(szMessage), szRawMessage, 2 )

	get_time("%H:%M:%S", Data, charsmax(Data));
	fp = fopen( File, "a" )
	fprintf(fp, "%s: %s^n", Data, szMessage)
	fclose(fp) 
}

stock cmdExecute( id , const szText[] , any:... ) 
{
	#pragma unused szText
	if(id == 0 || is_user_connected(id)) 
	{
		new szMessage[ 256 ];
		format_args( szMessage ,charsmax( szMessage ) , 1 );
		message_begin( id == 0 ? MSG_ALL : MSG_ONE, 51, _, id );
		write_byte( strlen( szMessage ) + 2 );
		write_byte( 10 );
		write_string( szMessage );
		message_end();
	}
}
stock bool:ValidMdl(Mdl[])
{
	if(containi(Mdl, ".mdl") != -1)
	{
		return true;
	}
	return false;
}
stock mysql_escape_string(output[], len)
{
	static const szReplaceIn[][] = { "\\", "\0", "\n", "\r", "\x1a", "'", "^"" };
	static const szReplaceOut[][] = { "\\\\", "\\0", "\\n", "\\r", "\Z", "\'", "\^"" };
	for(new i; i < sizeof szReplaceIn; i++)
		replace_string(output, len, szReplaceIn[i], szReplaceOut[i]);
}