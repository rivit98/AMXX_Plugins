#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Wprowadzenie" //Nazwa misji
#define OPIS_MISJI "Rozegraj 10 rund" //Opis misji
#define NAGRODA_MISJI "3000$" //Nagroda za misje
#define WYMAGANA_RANGA "UNRANKED" //Wymagana ranga
#define WYMAGANY_POSTEP 10 //Wymagany postep
/*
//Dolary
#define NAGRODA_DOLARY 3000
*/


//Euro
#define NAGRODA_EURO 100

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	
	register_logevent("ev_KoniecRundy", 2, "1=Round_End");
}

public ev_KoniecRundy() {
	static iIloscSlotow;
	
	if(!iIloscSlotow) {
		iIloscSlotow = get_maxplayers();
	}
	
	for(new i = 1; i <= iIloscSlotow; i++) {
		if(is_user_connected(i) && csgo_get_user_active_mission(i) == g_iMisja) {
			csgo_set_user_mission_progress(i, csgo_get_user_mission_progress(i) + 1);
		}
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//DOLARY
		//cs_set_user_money(id, cs_get_user_money(id) + NAGRODA_DOLARY);
		
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
		
	}
}



