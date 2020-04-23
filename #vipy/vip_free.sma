#include <amxmodx>
#include <colorchat>
#include <cstrike>
#include <csx>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>

forward amxbans_admin_connect(id);

new Array:g_Array, CsArmorType:armortype, bool:g_Vip[33], gRound=0, menu,
menu_callback_handler, weapon_id;

new const g_Langcmd[][]={"say /vips","say_team /vips","say /vipy","say_team /vipy"};

new bool:g_bDarmowyVip = false;

public plugin_init(){
	register_plugin("VIP Ultimate", "12.3.0.2", "benio101 & speedkill");
	RegisterHam(Ham_Spawn, "player", "SpawnedEventPre", 1);
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	register_event("DeathMsg", "DeathMsg", "a");
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
	g_Array=ArrayCreate(64,32);
	for(new i;i<sizeof g_Langcmd;i++){
		register_clcmd(g_Langcmd[i], "ShowVips");
	}
	register_clcmd("say /vip", "ShowMotd");
	register_message(get_user_msgid("SayText"),"handleSayText");
	freevip_check();
}

#define OD_GODZINY 21
#define DO_GODZINY 9
public freevip_check(){
    new szGodzina[4], iGodzina;
    get_time("%H", szGodzina, 3);
    iGodzina = str_to_num(szGodzina);
    
    if(OD_GODZINY <= iGodzina || iGodzina <= DO_GODZINY)
        g_bDarmowyVip = true;
}

public client_authorized(id , const authid[]){
	if(get_user_flags(id) & ADMIN_LEVEL_H || g_bDarmowyVip){
		client_authorized_vip(id);
	}
}
public client_authorized_vip(id){
	g_Vip[id]=true;
	new g_Name[64];
	get_user_name(id,g_Name,charsmax(g_Name));
	
	new g_Size = ArraySize(g_Array);
	new szName[64];
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, szName, charsmax(szName));
		
		if(equal(g_Name, szName)){
			return 0;
		}
	}
	ArrayPushString(g_Array,g_Name);
	
	return PLUGIN_CONTINUE;
}
public client_disconnected(id){
	if(g_Vip[id]){
		client_disconnect_vip(id);
	}
}
public client_disconnect_vip(id){
	g_Vip[id]=false;
	new Name[64];
	get_user_name(id,Name,charsmax(Name));
	
	new g_Size = ArraySize(g_Array);
	new g_Name[64];
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
		if(equal(g_Name,Name)){
			ArrayDeleteItem(g_Array,i);
			break;
		}
	}
}
public SpawnedEventPre(id){
	if(g_Vip[id]){
		if(is_user_alive(id)){
			SpawnedEventPreVip(id);
		}
	}
}
public SpawnedEventPreVip(id){
	cs_set_user_armor(id, min(cs_get_user_armor(id,armortype)+100, 100), armortype);
	new henum=(user_has_weapon(id,CSW_HEGRENADE)?cs_get_user_bpammo(id,CSW_HEGRENADE):0);
	give_item(id, "weapon_hegrenade");
	++henum;
	new fbnum=(user_has_weapon(id,CSW_FLASHBANG)?cs_get_user_bpammo(id,CSW_FLASHBANG):0);
	give_item(id, "weapon_flashbang");
	++fbnum;
	cs_set_user_bpammo(id, CSW_FLASHBANG, 2);
	new sgnum=(user_has_weapon(id,CSW_SMOKEGRENADE)?cs_get_user_bpammo(id,CSW_SMOKEGRENADE):0);
	give_item(id, "weapon_smokegrenade");
	++sgnum;
	cs_set_user_nvg(id);
	show_vip_menu(id);
	new g_Model[64];
	formatex(g_Model,charsmax(g_Model),"%s",get_user_team(id) == 1 ? "ttvip1" : "ctvip1");
	cs_set_user_model(id,g_Model);
	if(gRound>=1){
		StripWeapons(id, Secondary);
		give_item(id, "weapon_deagle");
		give_item(id, "ammo_50ae");
		weapon_id=find_ent_by_owner(-1, "weapon_deagle", id);
		if(weapon_id)cs_set_weapon_ammo(weapon_id, 7);
		cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	}
	if(get_user_team(id)==2){
		give_item(id, "item_thighpack");
	}
}
public event_new_round(){
	++gRound;
}
public GameCommencing(){
	gRound=0;
}
public menu_7_handler(id){
	StripWeapons(id, Primary);
	give_item(id, "weapon_xm1014");
	give_item(id, "ammo_buckshot");
	weapon_id=find_ent_by_owner(-1, "weapon_xm1014", id);
	if(weapon_id)cs_set_weapon_ammo(weapon_id, 7);
	cs_set_user_bpammo(id, CSW_XM1014, 32);
}
public menu_4_handler(id){
	StripWeapons(id, Primary);
	give_item(id, "weapon_galil");
	give_item(id, "ammo_556nato");
	weapon_id=find_ent_by_owner(-1, "weapon_galil", id);
	if(weapon_id)cs_set_weapon_ammo(weapon_id, 35);
	cs_set_user_bpammo(id, CSW_GALI, 90);
}
public menu_5_handler(id){
	StripWeapons(id, Primary);
	give_item(id, "weapon_famas");
	give_item(id, "ammo_556nato");
	weapon_id=find_ent_by_owner(-1, "weapon_famas", id);
	if(weapon_id)cs_set_weapon_ammo(weapon_id, 25);
	cs_set_user_bpammo(id, CSW_FAMAS, 90);
}
public menu_1_handler(id){
	StripWeapons(id, Primary);
	give_item(id, "weapon_ak47");
	give_item(id, "ammo_762nato");
	weapon_id=find_ent_by_owner(-1, "weapon_ak47", id);
	if(weapon_id)cs_set_weapon_ammo(weapon_id, 30);
	cs_set_user_bpammo(id, CSW_AK47, 90);
}
public menu_2_handler(id){
	StripWeapons(id, Primary);
	give_item(id, "weapon_m4a1");
	give_item(id, "ammo_556nato");
	weapon_id=find_ent_by_owner(-1, "weapon_m4a1", id);
	if(weapon_id)cs_set_weapon_ammo(weapon_id, 30);
	cs_set_user_bpammo(id, CSW_M4A1, 90);
}
public menu_3_handler(id){
	StripWeapons(id, Primary);
	give_item(id, "weapon_awp");
	give_item(id, "ammo_338magnum");
	weapon_id=find_ent_by_owner(-1, "weapon_awp", id);
	if(weapon_id)cs_set_weapon_ammo(weapon_id, 10);
	cs_set_user_bpammo(id, CSW_AWP, 30);
}
public menu_6_handler(id){
	StripWeapons(id, Primary);
	give_item(id, "weapon_m249");
	give_item(id, "ammo_556natobox");
	weapon_id=find_ent_by_owner(-1, "weapon_m249", id);
	if(weapon_id)cs_set_weapon_ammo(weapon_id, 100);
	cs_set_user_bpammo(id, CSW_M249, 200);
}
public DeathMsg(){
	new killer=read_data(1);
	new victim=read_data(2);
	
	if(is_user_alive(killer) && g_Vip[killer] && get_user_team(killer) != get_user_team(victim)){
		DeathMsgVip(killer,victim,read_data(3));
	}
}
public DeathMsgVip(kid,vid,hs){
	set_user_health(kid, min(get_user_health(kid)+(hs?15:10),100));
	cs_set_user_money(kid, cs_get_user_money(kid)+(hs?100:50));
}
public show_vip_menu(id){
	menu=menu_create("\rMenu VIPa","menu_handler");
	menu_callback_handler=menu_makecallback("menu_callback");
	new bool:active=false, num=-1;
	menu_additem(menu,"\wAK47","",0,menu_callback_handler);
	if(menu_callback(id, menu, ++num)==ITEM_ENABLED){
		active=true;
	}
	menu_additem(menu,"\wM4A1","",0,menu_callback_handler);
	if(menu_callback(id, menu, ++num)==ITEM_ENABLED){
		active=true;
	}
	menu_additem(menu,"\wAWP","",0,menu_callback_handler);
	if(menu_callback(id, menu, ++num)==ITEM_ENABLED){
		active=true;
	}
	menu_additem(menu,"\wGALIL","",0,menu_callback_handler);
	if(menu_callback(id, menu, ++num)==ITEM_ENABLED){
		active=true;
	}
	menu_additem(menu,"\wFAMAS","",0,menu_callback_handler);
	if(menu_callback(id, menu, ++num)==ITEM_ENABLED){
		active=true;
	}
	menu_additem(menu,"\wKROWA","",0,menu_callback_handler);
	if(menu_callback(id, menu, ++num)==ITEM_ENABLED){
		active=true;
	}
	menu_additem(menu,"\wXM1014","",0,menu_callback_handler);
	if(menu_callback(id, menu, ++num)==ITEM_ENABLED){
		active=true;
	}
	if(active){
		menu_setprop(menu,MPROP_EXITNAME,"Wyjscie");
		menu_setprop(menu,MPROP_TITLE,"\yMenu Vipa");
		menu_setprop(menu,MPROP_NUMBER_COLOR,"\r");
		menu_display(id, menu);
	} else {
		menu_destroy(menu);
	}
}
public menu_callback(id, menu, item){
	if(is_user_alive(id)){
		if(gRound>=3){
			if(item==0){
				return ITEM_ENABLED;
			}
			if(item==1){
				return ITEM_ENABLED;
			}
			if(item==2){
				return ITEM_ENABLED;
			}
			if(item==3){
				return ITEM_ENABLED;
			}
			if(item==4){
				return ITEM_ENABLED;
			}
			if(item==5){
				return ITEM_ENABLED;
			}
			if(item==6){
				return ITEM_ENABLED;
			}
		}
	}
	return ITEM_DISABLED;
}
public menu_handler(id, menu, item){
	if(is_user_alive(id)){
		if(gRound>=3){
			if(item==0){
				menu_1_handler(id);
			}
			if(item==1){
				menu_2_handler(id);
			}
			if(item==2){
				menu_3_handler(id);
			}
			if(item==3){
				menu_4_handler(id);
			}
			if(item==4){
				menu_5_handler(id);
			}
			if(item==5){
				menu_6_handler(id);
			}
			if(item==6){
				menu_7_handler(id);
			}
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
public VipStatus(){
	new id=get_msg_arg_int(1);
	if(is_user_alive(id) && g_Vip[id]){
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
	}
}
public ShowVips(id){
	new g_Name[64],g_Message[192];
	
	new g_Size=ArraySize(g_Array);
	
	for(new i = 0; i < g_Size; i++){
		ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
		
		add(g_Message, charsmax(g_Message), g_Name);
		
		if(i == g_Size - 1){
			add(g_Message, charsmax(g_Message), ".");
		}
		else{
			add(g_Message, charsmax(g_Message), ", ");
		}
	}
	ColorChat(id,GREEN,"^x03Vipy ^x04na ^x03serwerze: ^x04%s", g_Message);
	return PLUGIN_CONTINUE;
}
public client_infochanged(id){
	if(g_Vip[id]){
		new szName[64];
		get_user_info(id,"name",szName,charsmax(szName));
		
		new Name[64];
		get_user_name(id,Name,charsmax(Name));
		
		if(!equal(szName,Name)){
			ArrayPushString(g_Array,szName);
			
			new g_Size=ArraySize(g_Array);
			new g_Name[64];
			for(new i = 0; i < g_Size; i++){
				ArrayGetString(g_Array, i, g_Name, charsmax(g_Name));
				
				if(equal(g_Name,Name)){
					ArrayDeleteItem(g_Array,i);
					break;
				}
			}
		}
	}
}
public plugin_end(){
	ArrayDestroy(g_Array);
}
public ShowMotd(id){
	show_motd(id, "vip.txt", "Informacje o vipie");
}
public handleSayText(msgId,msgDest,msgEnt){
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id) && g_Vip[id]){
		new szTmp[256],szTmp2[256];
		get_msg_arg_string(2,szTmp, charsmax(szTmp))
		
		new szPrefix[64] = "^x04[VIP]";
		
		if(!equal(szTmp,"#Cstrike_Chat_All")){
			add(szTmp2,charsmax(szTmp2),szPrefix);
			add(szTmp2,charsmax(szTmp2)," ");
			add(szTmp2,charsmax(szTmp2),szTmp);
		}
		else{
			add(szTmp2,charsmax(szTmp2),szPrefix);
			add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
		}
		set_msg_arg_string(2,szTmp2);
	}
	return PLUGIN_CONTINUE;
}
public bomb_planted(id){
	if(is_user_alive(id) && g_Vip[id]){
		cs_set_user_money(id,cs_get_user_money(id) + 100);
	}
}
public bomb_defused(id){
	if(is_user_alive(id) && g_Vip[id]){
		cs_set_user_money(id,cs_get_user_money(id) + 100);
	}
}
public plugin_precache(){
	precache_model("models/player/ctvip1/ctvip1.mdl");
	precache_model("models/player/ttvip1/ttvip1.mdl");
}
public amxbans_admin_connect(id){
	client_authorized(id,"");
}