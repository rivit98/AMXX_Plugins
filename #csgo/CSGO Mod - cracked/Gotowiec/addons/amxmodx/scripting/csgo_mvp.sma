/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <csx>
#include <cstrike>
#include <csgo>

new g_iPunktyMVPGracza[33];
new g_iNagrodyMVPGracza[33];

new g_iBonusDoWybuchu;
new g_iOstatniOdprowadzajacy;
new g_iIloscSlotow;

public plugin_init() {
	register_plugin("CSGO Mod: MVP", "1.0", "donaciak.pl");
	
	register_cvar("csgo_mvp_euroaward", "500");
	
	register_event("DeathMsg", "ev_DeathMsg", "a");	
	register_logevent("ev_HostOdprowadzony", 3, "1=triggered", "2=Rescued_A_Hostage");
	register_logevent("ev_HostyOdprowadzone", 6, "2=triggered", "3=All_Hostages_Rescued");
	register_event("SendAudio", "WygranaTerro" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "WygranaCT", "a", "2&%!MRAD_ctwin");
	
	set_task(0.1, "task_NagrodaNajwiecejMVP", _, _, _, "d");
	g_iIloscSlotow = get_maxplayers();
}

public client_putinserver(id) {
	g_iPunktyMVPGracza[id] = 0;
	g_iNagrodyMVPGracza[id] = 0;
}

public ev_DeathMsg() {
	new iAtt = read_data(1);
	new id = read_data(2);
	
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt)) {
		return;
	}
	
	g_iPunktyMVPGracza[iAtt] += 3;
}

public ev_HostOdprowadzony()
{
	new id = get_loguser_index();
	
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	g_iOstatniOdprowadzajacy = id;
	g_iPunktyMVPGracza[id] += 1;
	
	return PLUGIN_CONTINUE;
}

public ev_HostyOdprowadzone()
{
	new id = g_iOstatniOdprowadzajacy;
	new iPunkty = 1;
	
	if(PobierzIloscGraczy(1)) {
		iPunkty += 2;
		
		if(PobierzIloscGraczy(2) == 1) { 
			iPunkty += 2;
		}
	}
	
	g_iPunktyMVPGracza[id] += iPunkty;
	
	return PLUGIN_CONTINUE;
}

public bomb_planted(id) {
	new iIloscTT = PobierzIloscGraczy(1);
	if(iIloscTT == 1) {
		g_iPunktyMVPGracza[id] += 2;
		g_iBonusDoWybuchu = 2;
	}
	else {
		g_iPunktyMVPGracza[id] += 1;
	}
}

public bomb_explode(id, iDef) {
	new iPunkty = 1+g_iBonusDoWybuchu;
	if(PobierzIloscGraczy(2)) {
		iPunkty += 1;
		
		if(PobierzIloscGraczy(1) == 1) { 
			iPunkty += 1;
		}
	}
	
	g_iPunktyMVPGracza[id] += iPunkty;
}

public bomb_defused(id) {
	new iPunkty = 3;
	if(PobierzIloscGraczy(1)) {
		iPunkty += 2;
		
		if(PobierzIloscGraczy(2) == 1) { 
			iPunkty += 2;
		}
	}
	
	g_iPunktyMVPGracza[id] += iPunkty;
}

public WygranaCT() { 
	WygranaRunda(2);
}

public WygranaTerro() {
	WygranaRunda(1);
}

public WygranaRunda(iTeam) {
	static iWymaganaIloscGraczy;
	
	if(!iWymaganaIloscGraczy) {
		iWymaganaIloscGraczy = get_cvar_num("csgo_wymaganailoscgraczygranie");
	}
	
	if(get_playersnum() < iWymaganaIloscGraczy)
		return;
	
	new id, iNajlepszyWynik;
	for(new i = 1; i <= g_iIloscSlotow; i++) {
		if(is_user_connected(i) && get_user_team(i) == iTeam && g_iPunktyMVPGracza[i] >= iNajlepszyWynik) {
			id = i;
			iNajlepszyWynik = g_iPunktyMVPGracza[i];
		}
		
		g_iPunktyMVPGracza[i] = 0;
	}
	
	new szNick[32];
	get_user_name(id, szNick, 31);
	
	csgo_print_message(0, "^x04[MVP]^x01 Najbardziej wartosciowym zawodnikiem rundy zostal(a)^x03 %s!^x01 Brawo!", szNick);
	g_iNagrodyMVPGracza[id] ++;
	
	g_iBonusDoWybuchu = 0;
}

public task_NagrodaNajwiecejMVP() {
	new id, iNajlepszyWynik;
	for(new i = 1; i <= g_iIloscSlotow; i++) {
		if(is_user_connected(i) && g_iNagrodyMVPGracza[i] > iNajlepszyWynik) {
			id = i;
			iNajlepszyWynik = g_iNagrodyMVPGracza[i];
		}
	}
	
	if(!id) {
		return;
	}
	
	new szNick[32], iIloscEuro = get_cvar_num("csgo_mvp_euroaward"), szEuro[32];
	get_user_name(id, szNick, 31);
	csgo_format_euro(iIloscEuro, szEuro, 31);
	
	csgo_set_user_euro(id, csgo_get_user_euro(id) + iIloscEuro);
	
	csgo_print_message(0, "^x04[MVP]^x01 Najwiecej nagrod MVP, bo az^x03 %d^x01 zdobyl(a)...^x03%s!", iNajlepszyWynik, szNick);
	csgo_print_message(0, "^x04[MVP]^x01 W nagrode dostaje on(a)^x04 +%s Euro!", szEuro);
}

stock PobierzIloscGraczy(iTeam) { 
	new iIlosc;
	for(new i = 1; i <= g_iIloscSlotow; i++) {
		if(is_user_alive(i) && get_user_team(i) == iTeam) {
			iIlosc ++;
		}
	}
	
	return iIlosc;
}
stock get_loguser_index() 
{
	new loguser[80], name[32]
	read_logargv(0, loguser, 79)
	parse_loguser(loguser, name, 31)
	return get_user_index(name)
}

