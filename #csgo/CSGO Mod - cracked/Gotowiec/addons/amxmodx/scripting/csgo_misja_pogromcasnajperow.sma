#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Pogromca snajperow" //Nazwa misji
#define OPIS_MISJI "Zabij 100 razy gracza, ktory w reku trzyma AWP lub Scouta" //Opis misji
#define NAGRODA_MISJI "15.00 Euro" //Nagroda za misje
#define WYMAGANA_RANGA "LEGENDARY EAGLE MASTER" //Wymagana ranga
#define WYMAGANY_POSTEP 5 //Wymagany postep

//Euro
#define NAGRODA_EURO 1500

new g_iOstatniRozbrajajacy;
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
	
	if(csgo_get_user_active_mission(iAtt) == g_iMisja) {
		new iBron = get_user_weapon(id);
		
		if(iBron == CSW_AWP || iBron == CSW_SCOUT) {
			csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
		}
	}
}


public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
	}
}

public bomb_defusing(id) {
	g_iOstatniRozbrajajacy = id;
}
	
stock is_user_defusing(id) {
	if(id != g_iOstatniRozbrajajacy) {
		return 0;
	}
	
	new iEnt = find_ent_by_model(-1, "grenade", "models/w_c4.mdl");
	
	if(is_valid_ent(iEnt)) {
		if(cs_get_c4_defusing(iEnt)) {
			return 1;
		}
	}
	
	return 0;
}
