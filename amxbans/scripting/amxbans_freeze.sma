/*

	AMXBans, managing bans for Half-Life modifications
	Copyright (C) 2003, 2004  Ronald Renes / Jeroen de Rover
	
	Copyright (C) 2009, 2010  Thomas Kurz

	Amxbans Freeze Plugin

	cvar: amxbans_freeze_mode "abc"
		"a" = freeze
		"b" = strip weapons
		"c" = block chat
		"d" = player glow red

*/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include "include/amxbans_main.inc"

#define PLUGIN "AMXBans Freeze"
#define VERSION "1.0"
#define AUTHOR "|PJ|ShOrTy"

new bool:g_frozen[33]
new pcvar_mode
new mode

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	pcvar_mode=register_cvar("amxbans_freeze_mode","abcd")
	register_clcmd("say","handle_say")
	register_clcmd("say_team","handle_say")
}

// forward from amxbans_main
public amxbans_ban_motdopen(id) {
	new tmp[8]
	get_pcvar_string(pcvar_mode,tmp,charsmax(tmp))
	mode=read_flags(tmp)
	
	if(is_user_connected(id)) g_frozen[id]=true;
	if(is_user_alive(id)) {
		g_frozen[id]=true;
		if(mode & 8) glow_player(id)
		if(mode & 2) strip_player(id)
		if(mode & 1) freeze_player(id)
		
	}
}
public client_connect(id) {
	g_frozen[id]=false
}
public client_disconnect(id) {
	g_frozen[id]=false
}
public handle_say(id) {
	if(g_frozen[id] && (mode & 4)) return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}
freeze_player(id) {
	set_pev(id,pev_velocity,Float:{0.0,0.0,0.0})
	engfunc(EngFunc_SetClientMaxspeed,id,0.00001)
	set_pev( id , pev_flags , pev( id , pev_flags ) | FL_FROZEN )
}
strip_player(id) {
	strip_user_weapons(id);
}
glow_player(id) {
	set_user_rendering(id,kRenderFxGlowShell,255,0,0,kRenderNormal,25)
}
/*
glow_remove(id) {
	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,25)
}
*/
