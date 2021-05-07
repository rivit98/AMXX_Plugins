#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta>

new const CSW_MAXAMMO[]= {-2, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100, -1, -1}

public plugin_init() {
	
	new const nazwy_broni[][] = {
		"weapon_scout", "weapon_mac10", "weapon_aug", "weapon_ump45", 
		"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_awp", 
		"weapon_mp5navy", "weapon_m249", "weapon_m4a1", "weapon_tmp", 
		"weapon_g3sg1", "weapon_sg552", "weapon_ak47", "weapon_p90",
		"weapon_p228", "weapon_xm1014", "weapon_elite", "weapon_fiveseven", 
		"weapon_usp", "weapon_glock18",  "weapon_deagle"
	}
	register_plugin("CSGO Mod: Ammo", "1.0", "donaciak"); 
	
	for(new i = 0; i < sizeof nazwy_broni; i++) {
		RegisterHam(Ham_Item_AddToPlayer, nazwy_broni[i], "fw_DostalBron_Post", 1);
	}
}

public fw_DostalBron_Post(iEnt, id) {
	if(!pev_valid(iEnt) || !is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	if(!pev(iEnt, pev_owner)) {
		new bron = cs_get_weapon_id(iEnt);
		cs_set_user_bpammo(id, bron, CSW_MAXAMMO[bron]);
	}
	
	return HAM_IGNORED;
}