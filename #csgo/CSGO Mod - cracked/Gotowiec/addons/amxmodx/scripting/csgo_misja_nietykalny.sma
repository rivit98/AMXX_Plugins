#include <amxmodx>
#include <amxmisc>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Nietykalny" //Nazwa misji
#define OPIS_MISJI "Zabij 10 graczy nie ginac przy tym ani razu" //Opis misji
#define NAGRODA_MISJI "Lekka skrzynia skarbow" //Nagroda za misje
#define WYMAGANA_RANGA "DISTINGUISHED MASTER GUARDIAN" //Wymagana ranga
#define WYMAGANY_POSTEP 10 //Wymagany postep

//Skrzynki
#define NAZWA_SKRZYNKI "Lekka skrzynia skarbow"
#define ILOSC_SKRZYNEK 1

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	register_event("DeathMsg", "ev_DeathMsg", "a");
}

public ev_DeathMsg() {
	new iAtt = read_data(1);
	new id = read_data(2);
	
	if(csgo_get_user_active_mission(id) == g_iMisja) {
		csgo_set_user_mission_progress(id, 0);
	}
	
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt)) {
		return;
	}
	
	if(csgo_get_user_active_mission(iAtt) == g_iMisja) {
		csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
	}
}


public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//Skrzynki
		new iSkrzynka = csgo_get_crate_by_name(NAZWA_SKRZYNKI);
		csgo_set_user_crates(id, iSkrzynka, csgo_get_user_crates(id, iSkrzynka) + ILOSC_SKRZYNEK);
	}
}



