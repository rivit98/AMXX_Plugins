#include <amxmodx>
#include <amxmisc>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "First Blood" //Nazwa misji
#define OPIS_MISJI "Zabij jako pierwszy w rundzie 3 razy" //Opis misji
#define NAGRODA_MISJI "1x klucz do skrzynki, 1.00 Euro" //Nagroda za misje
#define WYMAGANA_RANGA "SILVER III" //Wymagana ranga
#define WYMAGANY_POSTEP 3 //Wymagany postep

//KLUCZE
#define ILOSC_KLUCZY 1

//Euro
#define NAGRODA_EURO 100

new bool:g_bPierwszyFrag
public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	
	register_event("DeathMsg", "ev_DeathMsg", "a");
	register_event("HLTV", "ev_NowaRunda", "a", "1=0", "2=0")
}

public ev_NowaRunda() {
	g_bPierwszyFrag = false;
}

public ev_DeathMsg() {
	new iAtt = read_data(1);
	new id = read_data(2);
	
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt)) {
		return;
	}
	
	if(csgo_get_user_active_mission(iAtt) == g_iMisja && !g_bPierwszyFrag) {
		csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
	}
	
	g_bPierwszyFrag = true;
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//KLUCZE
		csgo_set_user_keys(id, csgo_get_user_keys(id) + ILOSC_KLUCZY);
		
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);
	}
}



