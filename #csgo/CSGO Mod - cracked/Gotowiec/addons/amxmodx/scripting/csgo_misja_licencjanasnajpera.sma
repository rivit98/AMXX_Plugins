#include <amxmodx>
#include <amxmisc>
#include <csgo>

new g_iMisja;

#define NAZWA_MISJI "Licencja na snajpera" //Nazwa misji
#define OPIS_MISJI "Zabij 150 przeciwnikow przy uzyciu AWP lub Scouta" //Opis misji
#define NAGRODA_MISJI "1x klucz, Skin AWP - ZBL" //Nagroda za misje
#define WYMAGANA_RANGA "GOLD NOVA MASTER" //Wymagana ranga
#define WYMAGANY_POSTEP 150 //Wymagany postep

//KLUCZE
#define ILOSC_KLUCZY 1

//SKINY
#define NAZWA_SKINA "ZBL"
#define INDEX_BRONI CSW_AWP
#define ILOSC_SKINOW 1

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
		
		if(equal(szBron, "scout") || equal(szBron, "awp")) {
			csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
		}
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//KLUCZE
		csgo_set_user_keys(id, csgo_get_user_keys(id) + ILOSC_KLUCZY);
		
		//SKINY
		new iSkin = csgo_get_skin_by_name(INDEX_BRONI, NAZWA_SKINA);
		csgo_set_user_skins(id, INDEX_BRONI, iSkin, csgo_get_user_skins(id, INDEX_BRONI, iSkin) + ILOSC_SKINOW);
	}
}



