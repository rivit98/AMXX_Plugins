#include <amxmodx>
#include <cstrike>
#include fakemeta
#include hamsandwich

#define m_pPlayer 41

public plugin_init()
{
	register_plugin("Modele", "1.0", "riviT")

	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "fwHamItemDeployPost", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "fwHamItemDeployPost", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_awp", "fwHamItemDeployPost", 1)
}
 
public plugin_precache()
{
	precache_model("models/vip/v_ak47vip.mdl");
	precache_model("models/vip/v_m4a1vip2.mdl");
	precache_model("models/vip/v_awp.mdl");
}
 
public fwHamItemDeployPost(ent)
{
	static id;
	id = get_pdata_cbase(ent, m_pPlayer, 4);
	
	if(!is_user_alive(id)) return;
	
	if(get_user_flags(id) & ADMIN_LEVEL_H){ //vip
		switch(cs_get_weapon_id(ent))
		{
			case CSW_M4A1: set_pev(id, pev_viewmodel2, "models/vip/v_m4a1vip2.mdl")
			case CSW_AK47: set_pev(id, pev_viewmodel2, "models/vip/v_ak47vip.mdl")
			case CSW_AWP: set_pev(id, pev_viewmodel2, "models/vip/v_awp.mdl")
		}
	}else{ //zwykly gracz
		switch(cs_get_weapon_id(ent))
		{
			case CSW_M4A1: set_pev(id, pev_viewmodel2, "models/vip/v_m4a1vip2.mdl")
			case CSW_AK47: set_pev(id, pev_viewmodel2, "models/vip/v_ak47vip.mdl")
			case CSW_AWP: set_pev(id, pev_viewmodel2, "models/vip/v_awp.mdl")
		}
	}

}
	
