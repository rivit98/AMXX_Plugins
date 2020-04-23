#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <StripWeapons>
#include <ColorChat>

forward amxbans_admin_connect(id);

new bool:g_Vip[33], gRound=0,g_Hudmsg;
new const g_Prefix[] = "Vip Chat"
new g_od, g_do;

public plugin_init(){
	register_plugin("VIP Ultimate", "12.3.0.2", "benio101 & speedkill");
	RegisterHam(Ham_Spawn, "player", "SpawnedEventPre", 1);
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_logevent("GameCommencing", 2, "1=Game_Commencing");
	register_event("TextMsg", "GameCommencing", "a", "2=#Game_will_restart_in") // register game restart
	register_message(get_user_msgid("SayText"), "handleSayText");
	register_clcmd("say_team", "VipChat");
	g_Hudmsg=CreateHudSyncObj();
	register_message(get_user_msgid("ScoreAttrib"), "VipStatus");

	g_od = register_cvar("freevip_od", "6");
	g_do = register_cvar("freevip_do", "22");
}

public handleSayText(msgId, msgDest, msgEnt)
{
	new index = get_msg_arg_int(1);

	if(!is_user_connected(index) || !g_Vip[index])
		return PLUGIN_CONTINUE;

	new chatString[2][192], name[33];

	get_user_name(index, name, 33);
	get_msg_arg_string(2, chatString[0], charsmax(chatString[]));

	if(!equal(chatString[0], "#Cstrike_Chat_All"))
		formatex(chatString[1], charsmax(chatString[]), "^x03[^x04VIP^x03] %s", chatString[0]);
	else
	{
		get_msg_arg_string(4, chatString[0], charsmax(chatString[]));
		set_msg_arg_string(4, "");

		formatex(chatString[1], charsmax(chatString[]), "^x03[^x04VIP^x03] %s^x01 : %s", name, chatString[0]);
	}

	set_msg_arg_string(2, chatString[1]);

	return PLUGIN_CONTINUE;
}

//od 2 do 18
public client_authorized(id){
	if(get_user_flags(id) & ADMIN_LEVEL_H){
		client_authorized_vip(id, true);
		return;
	}

	new szGodzina[4], iGodzina;    
    get_time("%H", szGodzina, 3);
    iGodzina = str_to_num(szGodzina);
    new odgodziny = get_pcvar_num(g_od);
    new dogodziny = get_pcvar_num(g_do);
    new bool:aktywne = false;

    if(odgodziny > dogodziny)
	{
		if(iGodzina >= odgodziny || iGodzina < dogodziny)
			aktywne = true;
	}
	else
	{
		if(iGodzina >= odgodziny && iGodzina < dogodziny)
			aktywne = true;
	}
    if(aktywne){
    	client_authorized_vip(id, false);
    }
}

public client_authorized_vip(id, bool:info){
	g_Vip[id]=true;

	if(!info) return;

	new g_Name[64];
	get_user_name(id,g_Name,charsmax(g_Name));
	set_hudmessage(24, 190, 220, 0.25, 0.2, 0, 6.0, 6.0);
	ShowSyncHudMsg(0, g_Hudmsg, "VIP %s wbija na serwer, Witamy",g_Name);
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
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	cs_set_user_bpammo(id, CSW_FLASHBANG, 2);
	give_item(id, "weapon_smokegrenade");

	if(gRound > 2){
		show_vip_menu(id);
	}
	if(get_user_team(id) == 2){
		give_item(id, "item_thighpack");
	}
}

public show_vip_menu(id){
	new menu=menu_create("\rMenu VIPa","menu_handler");
	menu_additem(menu, "AK47 + DEAGLE + GRANATY")
	menu_additem(menu, "M4A1 + DEAGLE + GRANATY")
	menu_additem(menu, "AWP + DEAGLE + GRANATY")

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

	StripWeapons(id, Secondary);
	give_item(id, "weapon_deagle");
	cs_set_user_bpammo(id, CSW_DEAGLE, 35);
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

public VipChat(id){
	if(g_Vip[id]){
		new g_Msg[256],
		g_Text[256];
		
		read_args(g_Msg,charsmax(g_Msg));
		remove_quotes(g_Msg);
		
		if(g_Msg[0] == '*' && g_Msg[1]){
			new g_Name[64];
			get_user_name(id,g_Name,charsmax(g_Name));
			
			formatex(g_Text,charsmax(g_Text),"^x01(%s) ^x03%s : ^x04%s",g_Prefix, g_Name, g_Msg[1]);
			
			for(new i=1;i<33;i++){
				if(is_user_connected(i) && g_Vip[i])
					ColorChat(i, GREEN, "%s", g_Text);
			}
			return PLUGIN_HANDLED_MAIN;
		}
	}
	return PLUGIN_CONTINUE;
}

public VipStatus(){
	new id=get_msg_arg_int(1);
	if(is_user_alive(id) && g_Vip[id]){
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
	}
}