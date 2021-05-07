#include <amxmodx>
#include <amxmisc>
#include <csgo>
#include <csx>
#include <engine>

new g_iMisja;

#define NAZWA_MISJI "Straznik jak sie patrzy" //Nazwa misji
#define OPIS_MISJI "Nie dopusc 100 razy aby anty-terrorysta probowal rozbroic bombe" //Opis misji
#define NAGRODA_MISJI "Skrzynka z karabinami maszynowymi" //Nagroda za misje
#define WYMAGANA_RANGA "MASTER GUARDIAN II" //Wymagana ranga
#define WYMAGANY_POSTEP 100 //Wymagany postep

//Skrzynki
#define NAZWA_SKRZYNKI "Skrzynka z karabinami maszynowymi"
#define ILOSC_SKRZYNEK 1

new g_iIloscSlotow;

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	register_event("SendAudio", "ev_WygranaTerro" , "a", "2&%!MRAD_terwin");
	g_iIloscSlotow = get_maxplayers();
}

public bomb_explode(id, iDefuser) {
	if(!iDefuser) {
		for(new i = 1; i <= g_iIloscSlotow; i++) {
			if(is_user_connected(i) && get_user_team(i) == 1 && csgo_get_user_active_mission(i) == g_iMisja) {
				csgo_set_user_mission_progress(i, csgo_get_user_mission_progress(i) + 1);
			}
		}
	}
}

public ev_WygranaTerro() {
	new iIloscCt = PobierzIloscGraczy(2);
	new iEnt = find_ent_by_model(-1, "grenade", "models/w_c4.mdl");
	
	if(!is_valid_ent(iEnt) || iIloscCt)
		return;
	
	for(new i = 1; i <= g_iIloscSlotow; i++) {
		if(is_user_connected(i) && get_user_team(i) == 1 && csgo_get_user_active_mission(i) == g_iMisja) {
			csgo_set_user_mission_progress(i, csgo_get_user_mission_progress(i) + 1);
		}
	}
}


stock PobierzIloscGraczy(iTeam) { 
	new iIlosc;
	for(new i = 1; i <= g_iIloscSlotow; i++) {
		if(is_user_alive(i) && get_user_team(i) == iTeam) {
			iIlosc ++;
		}
	}
	
	return iIlosc;
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//Skrzynki
		new iSkrzynka = csgo_get_crate_by_name(NAZWA_SKRZYNKI);
		csgo_set_user_crates(id, iSkrzynka, csgo_get_user_crates(id, iSkrzynka) + ILOSC_SKRZYNEK);
	}
}



