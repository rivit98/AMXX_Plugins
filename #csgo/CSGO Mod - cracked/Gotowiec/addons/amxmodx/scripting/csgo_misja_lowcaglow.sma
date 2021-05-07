#include <amxmodx>
#include <amxmisc>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Lowca glow" //Nazwa misji
#define OPIS_MISJI "Zabij 20 przeciwnikow z HeadShota" //Opis misji
#define NAGRODA_MISJI "2.50 Euro" //Nagroda za misje
#define WYMAGANA_RANGA "SILVER II" //Wymagana ranga
#define WYMAGANY_POSTEP 20 //Wymagany postep

//Euro
#define NAGRODA_EURO 250

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
	
	if(read_data(3) && csgo_get_user_active_mission(iAtt) == g_iMisja) {
		csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
	
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
	}
}



