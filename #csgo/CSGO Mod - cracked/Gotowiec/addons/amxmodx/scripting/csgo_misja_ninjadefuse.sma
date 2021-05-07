#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo>
#include <csx>

new g_iMisja;

#define NAZWA_MISJI "Ninja defuse" //Nazwa misji
#define OPIS_MISJI "Rozbroj bome 20 razy w towarzystwie terrorystow" //Opis misji
#define NAGRODA_MISJI "16000$, 6.00 Euro" //Nagroda za misje
#define WYMAGANA_RANGA "GOLD NOVA II" //Wymagana ranga
#define WYMAGANY_POSTEP 20 //Wymagany postep

//Dolary
#define NAGRODA_DOLARY 16000

//Euro
#define NAGRODA_EURO 500

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
}

public bomb_defused(id) {
	if(csgo_get_user_active_mission(id) == g_iMisja) {
		static iIloscSlotow;
		if(!iIloscSlotow) {
			iIloscSlotow = get_maxplayers();
		}
		
		for(new i = 1; i <= iIloscSlotow; i++) {
			if(is_user_alive(i) && get_user_team(i) == 1) {
				csgo_set_user_mission_progress(id, csgo_get_user_mission_progress(id) + 1);
			}
		}
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//DOLARY
		cs_set_user_money(id, cs_get_user_money(id) + NAGRODA_DOLARY);
		
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
	}
}



