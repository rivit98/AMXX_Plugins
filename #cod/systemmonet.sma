/*
CHANGELOG:
* 1.0.0 - pierwsze wydanie
* 1.0.1 - naprawa: kopiowanie monet z jednego nicku na drugi
* 1.0.2 - dodanie: natywow
* 1.0.3 - dodanie: typu zapisu
* 1.0.4 - naprawa: dostawanie monet za wpisanie kill w konsoli (Podziekowania dla Szybcioor za wykrycie i dla Goliath za zalatanie :])
* 1.0.5 - dodanie: nowe eventy za ktore zdobywa sie monety
* 1.0.6 - dodanie: cvaru - wlacznie/wylaczenie monet za TeamKill
* 1.0.7 - naprawa: brak monet za zabicie
* 1.0.8 - naprawa: brak monet za uratowanie/zabicie hosta
* 1.1.0 - naprawa: zbyt maly rozmiar tablicy
		- naprawa: problem z pobieraniem cvaru cod_savetype 
		- optymalizacja kodu
* 1.1.1 - dodanie: cvaru - ustawia minimalna ilosc graczy na serwerze, od ktorej mozliwe jest zdobywanie monet
*/

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN	"System Monet"
#define AUTHOR	"kisiel96"
#define VERSION	"1.1.1"

#define TASK_SHOW_COINS 666
#define VIP ADMIN_LEVEL_G

enum events { kill = 0, kill_hs, defused, planted, rescue_hostage, kill_hostage };

new player_auth[33][64];
new player_coins[33];
new bool:player_vip[33];

new sync_hud_obj;

new pcvar_coins[events];
new pcvar_coins_vip[events];
new cvar_coins[events];
new cvar_coins_vip[events];

new pcvar_coins_minplayers;
new pcvar_coins_ff;
new cvar_coins_minplayers;
new cvar_coins_ff;

new pcvar_savetype;
new bool:dataLoaded[33];
new Handle:hookSql;
new Tabela[32];

public plugin_init()
{	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("DeathMsg", "EnemyKilled", "a");
	register_event("ResetHUD", "ResetHUD", "abe");
	register_logevent("HostageRescued", 3, "1=triggered", "2=Rescued_A_Hostage");
	register_logevent("HostageKilled", 3, "1=triggered", "2=Killed_A_Hostage");
	
	sync_hud_obj = CreateHudSyncObj();
	
	pcvar_coins_ff						= 	register_cvar("cod_coins_friendlyfire", "0");
	
	pcvar_coins[kill]					= 	register_cvar("cod_coins_kill", "1");
	pcvar_coins_vip[kill] 				= 	register_cvar("cod_coins_kill_vip", "2");
	pcvar_coins[kill_hs] 				= 	register_cvar("cod_coins_kill_hs", "3");
	pcvar_coins_vip[kill_hs] 			= 	register_cvar("cod_coins_kill_hs_vip", "6");
	
	pcvar_coins[planted]				= 	register_cvar("cod_coins_planted", "1");
	pcvar_coins_vip[planted]			= 	register_cvar("cod_coins_planted_vip", "2");
	pcvar_coins[defused] 				= 	register_cvar("cod_coins_defused", "1");
	pcvar_coins_vip[defused] 			= 	register_cvar("cod_coins_defused_vip", "2");
	
	pcvar_coins[rescue_hostage]			= 	register_cvar("cod_coins_rescue_hostage", "1");
	pcvar_coins_vip[rescue_hostage]		= 	register_cvar("cod_coins_rescue_hostage_vip", "2");
	pcvar_coins[kill_hostage]			= 	register_cvar("cod_coins_kill_hostage", "2");
	pcvar_coins_vip[kill_hostage] 		= 	register_cvar("cod_coins_kill_hostage_vip", "1");
	
	pcvar_coins_minplayers				= 	register_cvar("cod_coins_minplayers", "2");

	//////
	// register_cvar("cod_savetype", "1");
//////
	pcvar_savetype 						= 	get_cvar_num("cod_savetype");

	register_cvar("cod_sql_table_monety", "codmod_table_monety");

	/////
	// register_cvar("cod_sql_host", "");
	// register_cvar("cod_sql_user", "");
	// register_cvar("cod_sql_pass", "");
	// register_cvar("cod_sql_db", "");
	/////
	set_task(0.2, "InitDB");
}

public InitDB(){
	new DaneBazy[4][64];
	get_cvar_string("cod_sql_host", DaneBazy[0], 63); 
	get_cvar_string("cod_sql_user", DaneBazy[1], 63); 
	get_cvar_string("cod_sql_pass", DaneBazy[2], 63); 
	get_cvar_string("cod_sql_db", DaneBazy[3], 63); 
	
	get_cvar_string("cod_sql_table_monety", Tabela, 31); 

	hookSql = SQL_MakeDbTuple(DaneBazy[0], DaneBazy[1], DaneBazy[2], DaneBazy[3]);

	new error, szError[128];
	new Handle:hConn = SQL_Connect(hookSql, error, szError, 127);
	if(error){
		log_amx("Error: %s", szError);
		return;
	}
	new szTemp[1024];
	formatex(szTemp, charsmax(szTemp), "CREATE TABLE IF NOT EXISTS `%s` (name VARCHAR(35) NOT NULL, monety INT DEFAULT 0, PRIMARY KEY(name))", Tabela);

	new Handle:query = SQL_PrepareQuery(hConn, szTemp);
	SQL_Execute(query);
	SQL_FreeHandle(query);
	SQL_FreeHandle(hConn);
}

public plugin_natives()
{
	register_native("cod_get_user_coins", "GetCoins", 1);
	register_native("cod_set_user_coins", "SetCoins", 1);
}	

public client_putinserver(id)
{
	dataLoaded[id] = false;
	RemoveCoins(id);
	
	switch(pcvar_savetype)
	{
		case 1: get_user_name(id, player_auth[id], 63);
		case 2: get_user_authid(id, player_auth[id], 63);
		case 3: get_user_ip(id, player_auth[id], 63);
		default: get_user_name(id, player_auth[id], 63);
	}

	mysql_escape_string(player_auth[id], player_auth[id], charsmax(player_auth[]));
		
	if(get_user_flags(id) & VIP)
		player_vip[id] = true;
	else 
		player_vip[id] = false;
	
	LoadCoins(id);
}

public client_disconnect(id)
{
	if(dataLoaded[id]){
		SaveCoins(id);
	}
}

public plugin_end()
	SQL_FreeHandle(hookSql);

// /-----------\ //
// |RESET MONET| //
// \-----------/ //

public RemoveCoins(id)
{
	player_coins[id] = 0;
	player_vip[id] = false;
}

// /--------------\ //
// |ZLICZNIE MONET| //
// \--------------/ //

public EnemyKilled()
{
	cvar_coins_minplayers = get_pcvar_num(pcvar_coins_minplayers);
	if(get_playersnum() < cvar_coins_minplayers)
		return;

	new kid = read_data(1);
	new vid = read_data(2);
	new hs = read_data(3);
	
	if(kid == vid)
		return;
	
	cvar_coins_ff = get_pcvar_num(pcvar_coins_ff) 
	
	if(cvar_coins_ff == 0 && get_user_team(kid) == get_user_team(vid))
		return;
	
	cvar_coins[kill] = get_pcvar_num(pcvar_coins[kill]);
	cvar_coins_vip[kill] = get_pcvar_num(pcvar_coins_vip[kill]);
	cvar_coins[kill_hs] = get_pcvar_num(pcvar_coins[kill_hs]);
	cvar_coins_vip[kill_hs] = get_pcvar_num(pcvar_coins_vip[kill_hs]);
	
	if(player_vip[kid])
	{
		if(hs)
			player_coins[kid] += cvar_coins_vip[kill_hs];
		else
			player_coins[kid] += cvar_coins_vip[kill];
	}
	else
	{
		if(hs)
			player_coins[kid] += cvar_coins[kill_hs];
		else
			player_coins[kid] += cvar_coins[kill];
	}
}

public BombPlanted(id)
{
	cvar_coins_minplayers = get_pcvar_num(pcvar_coins_minplayers);
	if(get_playersnum() < cvar_coins_minplayers)
		return;
	
	cvar_coins[planted] = get_pcvar_num(pcvar_coins[planted]);
	cvar_coins_vip[planted] = get_pcvar_num(pcvar_coins_vip[planted]);
	
	if(player_vip[id])
		player_coins[id] += cvar_coins_vip[planted];
	else
		player_coins[id] += cvar_coins[planted];
}

public BombDefused(id)
{
	cvar_coins_minplayers = get_pcvar_num(pcvar_coins_minplayers);
	if(get_playersnum() < cvar_coins_minplayers)
		return;
	
	cvar_coins[defused] = get_pcvar_num(pcvar_coins[defused]);
	cvar_coins_vip[defused] = get_pcvar_num(pcvar_coins_vip[defused]);	
	
	if(player_vip[id])
		player_coins[id] += cvar_coins_vip[defused];
	else
		player_coins[id] += cvar_coins[defused];
}

public HostageRescued(id)
{
	cvar_coins_minplayers = get_pcvar_num(pcvar_coins_minplayers);
	if(get_playersnum() < cvar_coins_minplayers)
		return;

	new loguser[80], name[32];
	read_logargv(0, loguser, 79);
	parse_loguser(loguser, name, 31);
	
	new id = get_user_index(name);
	
	cvar_coins[rescue_hostage] = get_pcvar_num(pcvar_coins[rescue_hostage]);
	cvar_coins_vip[rescue_hostage] = get_pcvar_num(pcvar_coins_vip[rescue_hostage]);
	
	if(player_vip[id])
		player_coins[id] += cvar_coins_vip[rescue_hostage];
	else
		player_coins[id] += cvar_coins[rescue_hostage];
} 

public HostageKilled(id) 
{
	cvar_coins_minplayers = get_pcvar_num(pcvar_coins_minplayers);
	if(get_playersnum() < cvar_coins_minplayers)
		return;
	
	new loguser[80], name[32];
	read_logargv(0, loguser, 79);
	parse_loguser(loguser, name, 31);
	
	new id = get_user_index(name);
		
	cvar_coins[kill_hostage] = get_pcvar_num(pcvar_coins[kill_hostage]);
	cvar_coins_vip[kill_hostage] = get_pcvar_num(pcvar_coins_vip[kill_hostage]);
	
	if(player_vip[id])
		player_coins[id] -= cvar_coins_vip[kill_hostage];
	else
		player_coins[id] -= cvar_coins[kill_hostage];
} 

// /---\ //
// |HUD| //
// \---/ //

public ShowCoins(id)
{
	id -= TASK_SHOW_COINS;
	
	if(!is_user_alive(id))
	{
		remove_task(id + TASK_SHOW_COINS);
		return;
	}
	
	set_hudmessage(0, 255, 0, 0.02, 0.23, 0, 0.0, 0.3, 0.0, 0.0);
	ShowSyncHudMsg(id, sync_hud_obj, "^n^n^n^n^n^n^n[Monety: %i]", player_coins[id]);
}

public ResetHUD(id)
{
	if(!task_exists(id+TASK_SHOW_COINS))
		set_task(0.1, "ShowCoins", id + TASK_SHOW_COINS, _, _, "b");
}

// /------\ //
// |NATYWY| //
// \------/ //

public SetCoins(id, wartosc){
	player_coins[id] = wartosc
}

public GetCoins(id)
	return player_coins[id];

public SaveCoins(id){
	new data[1], query[256];
	formatex(query, 255, "UPDATE `%s` SET monety='%d' WHERE `name` = '%s';", Tabela, player_coins[id], player_auth[id]);
	data[0] = id;

	SQL_ThreadQuery(hookSql, "handleIgnore", query, data, 1);
}

public LoadCoins(id){
	new data[1], query[256];
	formatex(query, 255, "SELECT `monety` FROM `%s` WHERE `name` = '%s';", Tabela, player_auth[id]);
	data[0] = id;
	log_amx(query);

	SQL_ThreadQuery(hookSql, "QueryLoadData", query, data, 1);
}

public QueryLoadData(failstate, Handle:query2, error[], errnum, data[])
{
	if( failstate == TQUERY_CONNECT_FAILED || failstate == TQUERY_QUERY_FAILED )
		log_amx(error);
	else
	{
		new id = data[0];

		if(SQL_NumResults(query2))
		{
			dataLoaded[id] = true;
			player_coins[id] = SQL_ReadResult(query2, SQL_FieldNameToNum(query2, "monety"));
			log_amx("wczuytano: %i", player_coins[id])
		}
		else
		{
			new data[1], query[256];
			data[0] = id;
			player_coins[id] = 0;
			formatex(query, 255, "INSERT INTO `%s` (name) VALUES ( '%s' ) ON DUPLICATE KEY UPDATE `name`='%s';", Tabela, player_auth[id], player_auth[id])
			SQL_ThreadQuery( hookSql, "handleIgnore", query, data, 1);
		}
	}
}

public handleIgnore(failstate, Handle:query, error[], errnum, data[], size){
	if(failstate != TQUERY_SUCCESS){
		log_amx("<Query> Error: %s", error);
		return;
	}
	new id = data[0];
	dataLoaded[id] = true;
}

// /-----------------\ //
// |ZEBY BYLO LADNIEJ| //
// \-----------------/ //

public bomb_planted(planter) 
{
	BombPlanted(planter);
}

public bomb_defused(defuser)
{
	BombDefused(defuser);
}

stock mysql_escape_string(const source[], dest[], length)
{
	copy(dest, length, source);

	replace_all(dest, length, "\\", "\\\\");
	replace_all(dest, length, "\0", "\\0");
	replace_all(dest, length, "\n", "\\n");
	replace_all(dest, length, "\r", "\\r");
	replace_all(dest, length, "\x1a", "\Z");
	replace_all(dest, length, "'", "\'");
	replace_all(dest, length, "`", "\`");
	replace_all(dest, length, "^"", "\^"");
}