#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csgo>
#include <hamsandwich>

new g_iMisja;

#define NAZWA_MISJI "W stylu ninja" //Nazwa misji
#define OPIS_MISJI "Zabij 25 przeciwnikow tak, aby Ci nawet nie zdazyli Cie zaatakowac" //Opis misji
#define NAGRODA_MISJI "5.00 Euro, Skin Deagle - Conspiracy" //Nagroda za misje
#define WYMAGANA_RANGA "SILVER ELITE" //Wymagana ranga
#define WYMAGANY_POSTEP 25 //Wymagany postep

//Euro
#define NAGRODA_EURO 1000

//SKINY
#define NAZWA_SKINA "Conspiracy"
#define INDEX_BRONI CSW_DEAGLE
#define ILOSC_SKINOW 1

new g_iAtakujacyGracza[33];

public plugin_init() {
	register_plugin(NAZWA_MISJI, "1.0", "donaciak.pl");
	
	g_iMisja = csgo_register_mission(NAZWA_MISJI, OPIS_MISJI, NAGRODA_MISJI, WYMAGANY_POSTEP, csgo_get_rank_by_name(WYMAGANA_RANGA));
	
	RegisterHam(Ham_TakeDamage, "player", "fw_Obrazenia_Post", 1);
	RegisterHam(Ham_Killed, "player", "fw_Smierc_Post", 1);
	register_logevent("ev_KoniecRundy", 2, "1=Round_End");
}

public ev_KoniecRundy() {
	static iIloscSlotow;
	
	if(!iIloscSlotow) {
		iIloscSlotow = get_maxplayers();
	}
	
	for(new i = 1; i <= iIloscSlotow; i++) {
		g_iAtakujacyGracza[i] = 0;
	}
}

public fw_Obrazenia_Post(id, iEnt, iAtt, Float:fDmg, iDmgBits) {
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt)) {
		return;
	}
	
	g_iAtakujacyGracza[id] |= (1<<iAtt);
}

public fw_Smierc_Post(id, iAtt, iShGb) {
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt)) {
		return;
	}
	
	if(csgo_get_user_active_mission(iAtt) == g_iMisja && !(g_iAtakujacyGracza[iAtt] & (1<<id))) {
		csgo_set_user_mission_progress(iAtt, csgo_get_user_mission_progress(iAtt) + 1);
	}
}

public csgo_user_mission_complete(id, iMisja) {
	if(iMisja == g_iMisja) {
		//EURO
		csgo_set_user_euro(id, csgo_get_user_euro(id) + NAGRODA_EURO);

		//SKINY
		new iSkin = csgo_get_skin_by_name(INDEX_BRONI, NAZWA_SKINA);
		csgo_set_user_skins(id, INDEX_BRONI, iSkin, csgo_get_user_skins(id, INDEX_BRONI, iSkin) + ILOSC_SKINOW);
	}
}



