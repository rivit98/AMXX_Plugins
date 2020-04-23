/*

	AMXBans, managing bans for Half-Life modifications
	Copyright (C) 2003, 2004  Ronald Renes / Jeroen de Rover
	
	Copyright (C) 2009, 2010  Thomas Kurz
	
	Amxbans Flagged Plugin
*/

/*
^x01 is Yellow
^x03 is Team Color
^x04 is Green
*/

#include <amxmodx>
#include <amxmisc>
#include <amxbans_main>
#include <colorchat>

#define PLUGIN "AMXBans Flagged"
#define VERSION "1.0.3"
#define AUTHOR "AMXBans Dev Team"

new authid[33][35],ip[33][22],reason[33][100]//,Float:left[33]
new flagged_end[33]
new g_maxplayers

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	g_maxplayers=get_maxplayers()
	register_dictionary("amxbans.txt")
}
public amxbans_player_flagged(id,sec_left,reas[]) {
	if(!is_user_connected(id)) return PLUGIN_HANDLED
	if(sec_left) {
		flagged_end[id]=get_systime()+sec_left
	} else {
		flagged_end[id]=-1 //permanent
	}
	
	get_user_authid(id,authid[id],sizeof(authid[]))
	get_user_ip(id,ip[id],sizeof(ip[]))
	copy(reason[id],sizeof(reason[]),reas)
	
	set_task(10.0,"announce",id)
	return PLUGIN_HANDLED
}
public amxbans_player_unflagged(id) {
	remove_task(id)
}
public announce(id) {
	new name[32],left_str[32]
	get_user_name(id,name,sizeof(name))
	
	if(flagged_end[id]==-1) {
		formatex(left_str,charsmax(left_str)," ^x04(%L)^x01",LANG_PLAYER,"PERMANENT")
	} else if(flagged_end[id]) {
		new Float:left=float(flagged_end[id]-get_systime())/60
		//if(left <= 0.1 && task_exists(id)) remove_task(id)
		new left_int=floatround(left,floatround_ceil)
		
		formatex(left_str,charsmax(left_str)," ^x04(left: %d min)^x01",left_int)
		if(left_int) set_task(60.0,"announce",id)
	}
	//only show msg to admins with ADMIN_CHAT
	for(new i=1;i<=g_maxplayers;i++) {
		if(!is_user_connected(i)) continue
		if(get_user_flags(i) & ADMIN_CHAT)
			ColorChat(i, RED, "[AMXBans]^x01 %L", LANG_PLAYER, "FLAGGED_PLAYER",name,authid[id],reason[id])
	}
}
public client_disconnect(id) {
	remove_task(id)
}