#include <amxmodx>
#include <amxmisc>
#include <csgo>
#include <csx>

new g_iMisja;

#define NAZWA_MISJI "Dla dobra terroru" //Nazwa misji
#define OPIS_MISJI "Podloz bombe 30 razy" //Opis misji
#define NAGRODA_MISJI "2x Skrzynka broni krotkich, 1x klucz" //Nagroda za misje
#define WYMAGANA_RANGA "SILVER IV" //Wymagana ranga
#define WYMAGANY_POSTEP 30 //Wymagany postep

//Skrzynki
#define NAZWA_SKRZYNKI "Skrzynka broni krotkich"
#define ILOSC_SKRZYNEK 2

//KLUCZE
#define ILOSC_KLUCZY 1

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
}

public bomb_planted(id) {
	if(csgo_get_user_active_mission(id) == g_iMisja) {
		csgo_set_user_mission_progress(id, csgo_get_user_mission_progress(id) + 1);
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//Skrzynki
		new iSkrzynka = csgo_get_crate_by_name(NAZWA_SKRZYNKI);
		csgo_set_user_crates(id, iSkrzynka, csgo_get_user_crates(id, iSkrzynka) + ILOSC_SKRZYNEK);
		
		//KLUCZE
		csgo_set_user_keys(id, csgo_get_user_keys(id) + ILOSC_KLUCZY);
	}
}



