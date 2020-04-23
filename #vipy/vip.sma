#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <StripWeapons>

forward amxbans_admin_connect(id);

new bool:g_Vip[33], gRound=0

public plugin_init(){
	register_plugin("VIP Ultimate", "12.3.0.2", "benio101 & speedkill");
	RegisterHam(Ham_Spawn, "player", "SpawnedEventPre", 1);
	register_event("DeathMsg", "DeathMsg", "a");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
}

public client_authorized(id){
	if(get_user_flags(id) & ADMIN_LEVEL_H){
		client_authorized_vip(id);
	}
}

public client_authorized_vip(id){
	g_Vip[id]=true;
}
public client_disconnect(id){
	if(g_Vip[id]){
		client_disconnect_vip(id);
	}
}
public client_disconnect_vip(id){
	g_Vip[id]=false;
}
public SpawnedEventPre(id){
	if(g_Vip[id]){
		if(is_user_alive(id)){
			SpawnedEventPreVip(id);
		}
	}
}
public SpawnedEventPreVip(id){
	cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);

	if(gRound > 1){
		give_item(id, "weapon_hegrenade");
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_smokegrenade");
		StripWeapons(id, Secondary);
		give_item(id, "weapon_deagle");
		cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	}
	if(gRound > 2){
		show_vip_menu(id);
	}
	if(get_user_team(id) == 2){
		give_item(id, "item_thighpack");
	}
}
public DeathMsg(){
	new killer=read_data(1);
	new victim=read_data(2);
	
	if(is_user_alive(killer) && g_Vip[killer] && get_user_team(killer) != get_user_team(victim)){
		DeathMsgVip(killer,victim,read_data(3));
	}
}
public DeathMsgVip(kid,vid,hs){
	set_user_health(kid, min(get_user_health(kid)+(hs?10:5),150));
}
public show_vip_menu(id){
	new menu=menu_create("\rMenu VIPa","menu_handler");
	menu_additem(menu, "ak47")
	menu_additem(menu, "m4a1")
	menu_additem(menu, "famas")
	menu_additem(menu, "awp")

	menu_display(id, menu);
}

public event_new_round(){
	++gRound;
}
public GameCommencing(){
	gRound=0;
}

public menu_handler(id, menu, item){
	if(item == MENU_EXIT || !is_user_connected(id)){
		menu_destroy(menu);
		return 1;
	}
	StripWeapons(id, Primary);
	switch(item){
		case 0:{
			give_item(id, "weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 90);
		}
		case 1:{
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 90);
		}
		case 2:{
			give_item(id, "weapon_famas");
			cs_set_user_bpammo(id, CSW_FAMAS, 90);
		}
		case 3:{
			give_item(id, "weapon_awp");
			cs_set_user_bpammo(id, CSW_AWP, 30);
		}
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public amxbans_admin_connect(id){
	client_authorized(id);
}