#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Obsluga pistoletu" //Nazwa misji
#define OPIS_MISJI "Zabij 250 graczy z Glocka badz USP" //Opis misji
#define NAGRODA_MISJI "Skin USP - Tiger, Skin GLOCK18 - Vulcan" //Nagroda za misje
#define WYMAGANA_RANGA "MASTER GUARDIAN ELITE" //Wymagana ranga
#define WYMAGANY_POSTEP 250 //Wymagany postep


//SKINY
#define NAZWA_SKINA1 "Tiger"
#define INDEX_BRONI1 CSW_USP
#define ILOSC_SKINOW1 1

#define NAZWA_SKINA2 "Vulcan"
#define INDEX_BRONI2 CSW_GLOCK18
#define ILOSC_SKINOW2 1

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
		new szBron[16]; read_data(4, szBron, 15);
		
		if(equal(szBron, "usp") || equal(szBron, "glock18")) {
			csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
		}
	}
}


public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//SKINY
		new iSkin1 = csgo_get_skin_by_name(INDEX_BRONI1, NAZWA_SKINA1);
		csgo_set_user_skins(id, INDEX_BRONI1, iSkin1, csgo_get_user_skins(id, INDEX_BRONI1, iSkin1) + ILOSC_SKINOW1);
		
		//SKINY
		new iSkin2 = csgo_get_skin_by_name(INDEX_BRONI2, NAZWA_SKINA2);
		csgo_set_user_skins(id, INDEX_BRONI2, iSkin2, csgo_get_user_skins(id, INDEX_BRONI2, iSkin2) + ILOSC_SKINOW2);
	}
}



