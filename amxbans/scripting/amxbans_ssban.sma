#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < colorchat >

#define PLUGIN "AMXBans: Screens"
#define VERSION	"0.4"
#define AUTHOR "GmStaff"

new victim
new CvarMaxss, CvarInterval, CvarTimestamptype, CvarHUDText;
new CvarBanTime, CvarBanReason;

new CountMenu
new CvarCountScreens
new g_max_players
new g_user_ids[33]
new g_player[33]

public plugin_init ( ) { 
	register_plugin ( PLUGIN, VERSION, AUTHOR );

	register_clcmd ( "amx_ssban", "cmdScreen", ADMIN_BAN, "<authid, nick or #userid> <count of screens>" );
	register_clcmd ( "amx_ssbanmenu", "cmdScreenMenu", ADMIN_BAN, " - display screens menu" );

	CvarMaxss			= register_cvar ( "amx_maxscreens", "10" );
	CvarInterval		= register_cvar ( "amx_interval", "1.0" );
	CvarTimestamptype	= register_cvar ( "amx_stamptype", "3" );
	CvarHUDText		= register_cvar ( "amx_hudtext", "Cheese! :)" );
	CvarCountScreens	= register_cvar ( "amx_screenscount", "1 2 3 4 5 6 7 8 9");

	CvarBanTime		= register_cvar ( "amx_ssbantime", "0" );
	CvarBanReason		= register_cvar ( "amx_ssbanreason", "Screens, go gm-community.net" );

	register_cvar ( "amxbans_ssversion", VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	g_max_players = get_maxplayers();

	new configsDir [ 64 ];
	get_configsdir ( configsDir, 63 );
	
	server_cmd ( "exec %s/amxbans-ssban.cfg", configsDir );

}

public plugin_cfg ( ) {
	new line[ 128 ], token[ 10 ], szKey[ 16 ];
	get_pcvar_string ( CvarCountScreens, line, 127 );

	CountMenu = menu_create ( "\rCount of screens\w", "CountScreensMenu" );
	while ( contain ( line, " " ) != -1 ) {
		strbreak ( line, token, 9, line, 127 );
		format( szKey, charsmax ( szKey ), "Make %s screen(s)", token )
		menu_additem ( CountMenu, szKey, token );
	}
}

public cmdScreenMenu ( id, level, cid ) {
	if ( !cmd_access ( id, level, cid, 1 ) )
		return PLUGIN_HANDLED;
		
	new menu = menu_create ( "\rChoose player", "PlayersMenu" );
	
	new i, name[ 32 ], tempid[ 10 ];
	
	for ( i = 1; i <= g_max_players; i++ ) {
		if ( is_user_connected ( i ) ) {
			get_user_name ( i, name, 31 );
			num_to_str ( i, tempid, 9 );
			g_user_ids[ i ] = get_user_userid ( i );
			menu_additem ( menu, name, tempid, 0 );
		}
	}
	
	menu_display ( id, menu, 0 );
	return PLUGIN_HANDLED;
}

public PlayersMenu ( id, menu, item ) {
	if ( item == MENU_EXIT ) {
		return PLUGIN_HANDLED;
	}
	
	new data[ 6 ], iName[ 64 ];
	new access, callback;
	menu_item_getinfo ( menu, item, access, data, 5, iName, 63, callback );
	
	g_player[ id ] = str_to_num ( data );
	menu_display ( id, CountMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public CountScreensMenu ( id, menu, item ) {
	if ( item == MENU_EXIT ) {
		return PLUGIN_HANDLED;
	}
	
	new data[ 6 ], iName[ 64 ];
	new access, callback;
	new player = g_player[id];
	
	menu_item_getinfo ( menu, item, access, data,5, iName, 63, callback );
	
	if ( g_user_ids[ player ] == get_user_userid ( player ) ) {
		client_cmd ( id, "amx_ssban #%d %s", g_user_ids[ player ], data );
	}
	
	return PLUGIN_HANDLED;
}

public cmdScreen ( id, level, cid ) { 
	if ( !cmd_access ( id, level, cid, 3 ) ) {
		return PLUGIN_HANDLED;
	}

	new arg1[ 24 ], arg2[ 4 ];

	read_argv ( 1, arg1, 23 );
	read_argv ( 2, arg2, 3 );
	
	new screens = str_to_num ( arg2 );
	victim = cmd_target ( id, arg1, 1 );
	
	if ( screens > get_pcvar_num ( CvarMaxss ) ) {
		console_print ( id, "Gm# You cannot take that many screenshots!" );
		
		return PLUGIN_HANDLED;
	}
	
	if ( !victim ) {
		return PLUGIN_HANDLED;
	}
	
	new Float: interval = get_pcvar_float ( CvarInterval );
	new array[ 2 ];

	array[ 0 ] = id;
	array[ 1 ] = victim;

	set_task ( interval, "takeScreen", 0, array, 2, "a", screens );
	set_task ( interval * screens + 1.0, "victimBan", 0, array, 2 );

	return PLUGIN_HANDLED;
}
 
public takeScreen ( array[ 2 ] ) {
	new victim = array[ 1 ];
	new id = array[ 0 ];
	
	new timestamp[ 32 ], HUDText[ 32 ], name[ 32 ], adminname[ 32 ];
	get_time ( "%m/%d/%Y - %H:%M:%S", timestamp, 31 );
	get_user_name ( victim, name, 31 );
	get_user_name ( id, adminname, 31 );
	get_pcvar_string ( CvarHUDText, HUDText, 31 );

	switch( get_pcvar_num ( CvarTimestamptype ) ) {
		case 0: {
			ColorChat( id, RED, "Gm#^x01 Screenshot taken on player ^x03%s^x01 by admin ^x04%s^x01", name, adminname );
			client_cmd ( victim, "snapshot" );
		}

		case 1: {
			ColorChat( id, RED, "Gm#^x01 Screenshot taken on player ^x03%s^x01 by admin ^x04%s^x01 (Date: %s)", name, adminname, timestamp );
		 	client_cmd(victim, "snapshot");
		}

		case 2: {
			set_hudmessage( 225, 225, 225, 0.02, 0.90, 0, 1.0, 2.0 );
			show_hudmessage ( victim, "%s", HUDText );
			client_cmd ( victim, "snapshot" );
		}

		case 3: {
			set_hudmessage( 225, 225, 225, 0.02, 0.90, 0, 1.0, 2.0 );
			show_hudmessage ( victim, "%s", HUDText );
			ColorChat ( id, RED, "Gm#^x01 Screenshot taken on player ^x03%s^x01 by admin ^x04%s^x01 (Date: %s)", name, adminname, timestamp );
			client_cmd ( victim, "snapshot" );
		}
	}

	return PLUGIN_CONTINUE;
}

public victimBan ( array[ 2 ] ) {
	new  Reason[ 50 ];

	new victimId = get_user_userid ( array[ 1 ] );
	get_pcvar_string ( CvarBanReason, Reason, 31 );

	client_cmd ( array[ 0 ], "amx_ban %i #%i ^"%s^"", get_pcvar_num ( CvarBanTime ), victimId, Reason);
}
