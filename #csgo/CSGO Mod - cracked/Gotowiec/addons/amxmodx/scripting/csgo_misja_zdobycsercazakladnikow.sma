#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo>
#include <csx>

new g_iMisja;

#define NAZWA_MISJI "Zdobyc serca zakladnikow" //Nazwa misji
#define OPIS_MISJI "Uratuj 50 zakladnikow" //Opis misji
#define NAGRODA_MISJI "2.50 Euro" //Nagroda za misje
#define WYMAGANA_RANGA "SILVER ELITE MASTER" //Wymagana ranga
#define WYMAGANY_POSTEP 30 //Wymagany postep

//Euro
#define NAGRODA_EURO 250

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	register_logevent("ev_HostOdprowadzony", 3, "1=triggered", "2=Rescued_A_Hostage");
}


public ev_HostOdprowadzony()
{
	new id = get_loguser_index();
	
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	if(csgo_get_user_active_mission(id) == g_iMisja) {
		csgo_set_user_mission_progress(id, csgo_get_user_mission_progress(id) + 1);
	}
	
	return PLUGIN_CONTINUE;
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
	}
}

stock get_loguser_index() {
	new loguser[80], name[32];
	read_logargv(0, loguser, 79);
	parse_loguser(loguser, name, 31);
	return get_user_index(name);
}



