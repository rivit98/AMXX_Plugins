/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <csgo>
#include <fakemeta>
#include <nvault>

native is_user_logged(id);

new bool:g_bHudGracza[33];
new g_iHud;

public plugin_init() {
	register_plugin("CSGO: HUD", "1.0", "d0naciak");
	
	register_clcmd("say /hud", "cmd_HUD");
	register_event("ResetHUD", "ev_ResetHUD", "b");
	g_iHud = CreateHudSyncObj();
}


public plugin_natives() {
	register_native("csgo_set_hud", "cmd_HUD", 1);
}

public client_authorized(id) {
	new iVault = nvault_open("CSGO_Hud"), szNick[32];
	get_user_name(id, szNick, 31);
	g_bHudGracza[id] = bool:!nvault_get(iVault, szNick);
	nvault_close(iVault);
}

public client_putinserver(id) {
	if(g_bHudGracza[id]) {
		set_task(1.0, "task_HUD", id, _, _, "b");
	}
}

public client_disconnect(id) {
	remove_task(id);
}

public cmd_HUD(id) {
	if(!is_user_logged(id)) {
		return PLUGIN_HANDLED;
	}
	
	g_bHudGracza[id] = !g_bHudGracza[id];
	new iVault = nvault_open("CSGO_Hud"), szNick[32], szDane[4];
	get_user_name(id, szNick, 31);
	num_to_str(_:!g_bHudGracza[id], szDane, 3);
	nvault_set(iVault, szNick, szDane);
	nvault_close(iVault);
	
	if(g_bHudGracza[id]) {
		set_task(1.0, "task_HUD", id, _, _, "b");
	} else {
		remove_task(id);
	}
	
	csgo_print_message(id, "HUD zostal:^x03 %s", g_bHudGracza[id] ? "wlaczony" : "wylaczony");
	return PLUGIN_HANDLED;
}

public ev_ResetHUD(id) {
	if(g_bHudGracza[id]) {
		return;
	}

	new iSmierci = csgo_get_user_deaths(id),
	iFragi = csgo_get_user_frags(id),
	Float:fStosunek = float(iFragi)/float((iSmierci ? iSmierci : 1)),
	szRanga[32];
	csgo_get_rank_name(csgo_get_user_rank(id), szRanga, 31);
	
	csgo_print_message(id, "Ranga:^x03 %s", szRanga);
	csgo_print_message(id, "Statystyki:^x03 %d/%d (%.1f)", iFragi, iSmierci, fStosunek);
}

public task_HUD(id) {
	if(!g_bHudGracza[id]) {
		return;
	}
	
	new iTarget;
	
	if(!is_user_alive(id)) {
		iTarget = pev(id, pev_iuser2);
	}
	else {
		iTarget = id;
	}
	
	if(iTarget) {
		new iSmierci = csgo_get_user_deaths(iTarget),
		iFragi = csgo_get_user_frags(iTarget),
		iMisja = csgo_get_user_active_mission(iTarget),
		iBron = get_user_weapon(iTarget), szEuro[16], szNazwaMisji[32], szRanga[32], szSkin[32];
		new Float:fStosunek = float(iFragi)/float((iSmierci ? iSmierci : 1));
		csgo_format_euro(csgo_get_user_euro(iTarget), szEuro, 15);
		csgo_get_mission_name(iMisja, szNazwaMisji, 31);
		csgo_get_rank_name(csgo_get_user_rank(iTarget), szRanga, 31);
		csgo_get_skin_name(iBron, csgo_get_user_default_skin(iTarget, iBron), szSkin, 31);
		set_hudmessage(255, 255, 0, 0.01, 0.2, 0, 2.5, 2.5, 1.0, 0.3, 2);
		ShowSyncHudMsg(id, g_iHud, "[Ranga: %s]^n[Statystyki: %d/%d (%.1f)]^n^n[Skin: %s]^n[Stan konta: %s Euro]^n^n[Misja: %s (%d/%d)]", 
		szRanga, iFragi, iSmierci, fStosunek, szSkin, szEuro, szNazwaMisji, csgo_get_user_mission_progress(iTarget), csgo_get_req_mission_progress(iMisja));
	}
}
