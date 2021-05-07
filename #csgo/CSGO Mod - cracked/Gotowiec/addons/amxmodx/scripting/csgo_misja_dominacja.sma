#include <amxmodx>
#include <amxmisc>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Dominacja" //Nazwa misji
#define OPIS_MISJI "Zdobadz 50 fragow w ciagu jednej mapy" //Opis misji
#define NAGRODA_MISJI "3x Lekka skrzynia skarbow, 3x klucze, 8.00 Euro" //Nagroda za misje
#define WYMAGANA_RANGA "SUPREME MASTER FIRST CLASS" //Wymagana ranga
#define WYMAGANY_POSTEP 50 //Wymagany postep

//Euro
#define NAGRODA_EURO 800

//Skrzynki
#define NAZWA_SKRZYNKI "Lekka skrzynia skarbow"
#define ILOSC_SKRZYNEK 3

//KLUCZE
#define ILOSC_KLUCZY 3

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	register_event("DeathMsg", "ev_DeathMsg", "a");
}

public client_authorized(id) {
	if(csgo_get_user_active_mission(id) == g_iMisja) {
		csgo_set_user_mission_progress(id, 0);
	}
}

public ev_DeathMsg() {
	new iAtt = read_data(1);
	new id = read_data(2);
	
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt)) {
		return;
	}
	
	if(csgo_get_user_active_mission(iAtt) == g_iMisja) {
		csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
	}
}


public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
		
		//Skrzynki
		new iSkrzynka = csgo_get_crate_by_name(NAZWA_SKRZYNKI);
		csgo_set_user_crates(id, iSkrzynka, csgo_get_user_crates(id, iSkrzynka) + ILOSC_SKRZYNEK);
		
		//KLUCZE
		csgo_set_user_keys(id, csgo_get_user_keys(id) + ILOSC_KLUCZY);
	}
}



