#include <amxmodx>
#include <amxmisc>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Pokaz, na co Cie stac!" //Nazwa misji
#define OPIS_MISJI "Zabij 50 graczy z wyzsza od Ciebie ranga" //Opis misji
#define NAGRODA_MISJI "3.00 Euro, 1x klucz" //Nagroda za misje
#define WYMAGANA_RANGA "GOLD NOVA I" //Wymagana ranga
#define WYMAGANY_POSTEP 50 //Wymagany postep

//Euro
#define NAGRODA_EURO 300

//KLUCZE
#define ILOSC_KLUCZY 1

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	
	register_event("DeathMsg", "ev_DeathMsg", "a");
}

public ev_DeathMsg() {
	new iAtt = read_data(1);
	new id = read_data(2);
	
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt)) {
		return;
	}
	
	if(csgo_get_user_active_mission(iAtt) == g_iMisja && csgo_get_user_rank(iAtt) < csgo_get_user_rank(id)) {
		csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
		
		//KLUCZE
		csgo_set_user_keys(id, csgo_get_user_keys(id) + ILOSC_KLUCZY);
	}
}



