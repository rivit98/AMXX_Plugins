#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Pierwsze kroki" //Nazwa misji
#define OPIS_MISJI "Zabij 20 przeciwnikow" //Opis misji
#define NAGRODA_MISJI "3000$, 1x klucz" //Nagroda za misje
#define WYMAGANA_RANGA "SILVER I" //Wymagana ranga
#define WYMAGANY_POSTEP 20 //Wymagany postep

//Dolary
#define NAGRODA_DOLARY 3000

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
	
	if(csgo_get_user_active_mission(iAtt) == g_iMisja) {
		csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//DOLARY
		cs_set_user_money(id, cs_get_user_money(id) + NAGRODA_DOLARY);
		
		//KLUCZE
		csgo_set_user_keys(id, csgo_get_user_keys(id) + ILOSC_KLUCZY);
	}
}



/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
