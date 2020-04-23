#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
static const COLOR[] = "^x04" //green
static const CONTACT[] = ""
new maxplayers
new gmsgSayText
new mpd, mkb, mhb
new health_add
new health_hs_add
new health_max
new nKiller_hp
new nHp_add
new nHp_max
new g_vip_active
new g_menu
new ile_razy_bronvip
new model
new g_menu_active
new uzylem[33];
new bool:HasC4[33]

#define FLAGA ADMIN_FLAG_X

#define ADMIN_FLAG_X (1<<23)
#define DAMAGE_RECIEVED
new round;

public plugin_init()
{
	register_plugin("VIP", "3.2.5", "KariiO")
	mpd = register_cvar("money_per_damage","3")
	mkb = register_cvar("money_kill_bonus","500")
	mhb = register_cvar("money_hs_bonus","300")
	health_add = register_cvar("amx_vip_hp", "15")
	health_hs_add = register_cvar("amx_vip_hp_hs", "30")
	health_max = register_cvar("amx_vip_max_hp", "900")
	g_vip_active = register_cvar("vip_active", "0")
	g_menu = register_cvar("menu_bronvip", "1")
	ile_razy_bronvip = register_cvar("vip_iloscuzyc_bronvip", "0")
	model = register_cvar("model_active", "1")
	g_menu_active = register_cvar("menu_active", "1")
	
	
	register_event("Damage","Damage","b")
	register_event("DeathMsg","death_msg","a")
	register_logevent("Round_Start", 2, "1=Round_Start")
	register_logevent("Round_Reset", 2, "1=Game_Commencing")
	register_event("TextMsg", "Round_Reset", "a", "2&Game_will_restart_in")
	register_event("DeathMsg", "hook_death", "a", "1>0")
	
	maxplayers = get_maxplayers()
	
	
	
	register_event("CurWeapon", "CurWeapon_Bron_VIPowska", "be", "1=1")
	register_clcmd("say /vip","ShowMotd")
	register_clcmd("say /bronvip","vipmenu1")
	gmsgSayText = get_user_msgid("SayText")
	register_clcmd("say", "handle_say")
	register_cvar("sv_contact", CONTACT, FCVAR_SERVER)
}

public plugin_precache()
{
	if(get_pcvar_num(model)>0) precache_model("models/player/vip/vip.mdl")
}

public Damage(id)
{
	new weapon, hitpoint, attacker = get_user_attacker(id,weapon,hitpoint)
	if(attacker<=maxplayers && is_user_alive(attacker) && attacker!=id)
		if (get_user_flags(attacker) & FLAGA) 
	{
		new money = read_data(2) * get_pcvar_num(mpd)
		if(hitpoint==1) money += get_pcvar_num(mhb)
		cs_set_user_money(attacker,cs_get_user_money(attacker) + money)
	}
}

public death_msg()
{
	new zabojca = read_data(1)
	new ofiara = read_data(2)
	new hs = read_data(3)

	if(zabojca<=maxplayers && zabojca && zabojca!=ofiara)
		cs_set_user_money(zabojca,cs_get_user_money(zabojca) + get_pcvar_num(mkb) - 300)

	if (hs) nHp_add = get_pcvar_num (health_hs_add)
	else nHp_add = get_pcvar_num (health_add)

	nHp_max = get_pcvar_num (health_max)


	if(!(get_user_flags(zabojca) & FLAGA))
		return;
	
	nKiller_hp = get_user_health(zabojca)
	nKiller_hp += nHp_add
	// sprawdzanie maksymalnej ilosc HP
	if (nKiller_hp > nHp_max) nKiller_hp = nHp_max
	if(zabojca != ofiara)
	{
		set_user_health(zabojca, nKiller_hp)
		// podleczony o ile
		set_hudmessage(0, 255, 0, -1.0, 0.15, 0, 1.0, 1.0, 0.1, 0.1, -1)
		show_hudmessage(zabojca, "Dostales +%d HP [VIP]", nHp_add)
		// kolorowy ekran \/
	}
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, zabojca)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0x0000)
	write_byte(0)
	write_byte(0)
	write_byte(200)
	write_byte(75)
	message_end()
}

public addNades(id){
	give_item(id, "weapon_hegrenade");
	cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	give_item(id, "weapon_flashbang");
	cs_set_user_bpammo(id, CSW_FLASHBANG, 2);
	give_item(id, "weapon_smokegrenade");
	cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 1)
}

public Round_Start()
{
	round++;
	new players[32], player, pnum;
	get_players(players, pnum, "a");
	for(new i = 0; i < pnum; i++)
	{
		player = players[i];
		if(get_user_flags(player) & FLAGA)
		{
			uzylem[player] = 0;
			
			if(!is_user_hltv(player) && !is_user_bot(player))
			{
				addNades(player)
				give_item(player, "item_assaultsuit");
				give_item(player, "item_thighpack");
			}
			if(get_pcvar_num(model)>0) cs_set_user_model(player,"vip")
			if(round > 1 && (get_pcvar_num(g_menu_active)>0)) vipmenu(player)
		}
	}
	return PLUGIN_HANDLED
}

public Round_Reset()
{
	round = 0;
}

public client_connect(id)
{
	uzylem[id] = 0;
}

public vipmenu(id)
{
	new menu = menu_create("\rVIP Menu", "KlasyHandle");
	
	menu_additem(menu, "\wWez \yM4A1+Deagle\d(Granaty+Armor)");
	menu_additem(menu, "\wWez \yAK47+Deagle\d(Granaty+Armor)");
	menu_additem(menu, "\wWez \yAWP+Deagle\d(Granaty+Armor)");
	
	menu_setprop(menu, MPROP_EXITNAME,"Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}


public KlasyHandle(id, menu, item)
{
	Czy_ma_pake(id)
	strip_user_weapons(id) //usuwanie broni
	switch(item){
		case 0: { 
			give_item(id,"weapon_m4a1")
			cs_set_user_bpammo(id, CSW_M4A1, 90)
		}
		case 1: { 
			give_item(id,"weapon_ak47")
			cs_set_user_bpammo(id, CSW_AK47, 90)
		}
		case 2: { 
			give_item(id,"weapon_awp")
			cs_set_user_bpammo(id, CSW_AWP, 30)
		}
	}
	//standardowo - granaty+kamizelka i helm+deagle
	give_item(id,"weapon_deagle")
	give_item(id,"weapon_knife")  
	give_item(id, "item_assaultsuit");
	give_item(id, "item_thighpack");
	cs_set_user_bpammo(id, CSW_DEAGLE, 35)
	addNades(id)
	Mial_pake(id)

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public Czy_ma_pake(id)
{
	if (user_has_weapon(id, CSW_C4) && get_user_team(id) == 1) HasC4[id] = true;
	else HasC4[id] = false;
}

public Mial_pake(id)
{
	if (HasC4[id]==true)
	{
		give_item(id, "weapon_c4");
		cs_set_user_plant( id );
	}
}

public CurWeapon_Bron_VIPowska(id)
{
	new bron=get_user_weapon(id)
	
	if (!get_pcvar_num(g_vip_active))
		return PLUGIN_CONTINUE
	
	if((bron == CSW_G3SG1) || (bron == CSW_SG550) || (bron == CSW_SG550) || (bron == CSW_M249) || (bron == CSW_AWP))
	{
		if(!(get_user_flags(id) & FLAGA))
		{
			new weaponname[32]; get_weaponname(bron, weaponname, 31 ); replace(weaponname, 31, "weapon_", "")
			client_print(id, print_center, "Bron '%s' tylko dla VIPow!",weaponname)
			client_cmd(id, "drop")
		}
	}
	return PLUGIN_HANDLED
}

public ShowMotd(id) show_motd(id, "vip.txt")

public handle_say(id) {
	new said[192]
	read_args(said,192)
	if( ( containi(said, "who") != -1 && containi(said, "admin") != -1 ) || contain(said, "/vips") != -1 )
		set_task(0.1,"print_adminlist",id)
	return PLUGIN_CONTINUE
}

public print_adminlist(user) 
{
	new adminnames[33][32]
	new message[256]
	new contactinfo[256], contact[112]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id) && (get_user_flags(id) & FLAGA))
		get_user_name(id, adminnames[count++], 31)
	
	len = format(message, 255, "%s VIP'y ONLINE: ",COLOR)
	if(count > 0) 
	{
		for(x = 0 ; x < count ; x++) 
		{
			len += format(message[len], 255-len, "%s%s%s ", COLOR, adminnames[x], x < (count-1) ? "^x01, ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "%s ",COLOR)
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "Brak VIP'ow Online")
		print_message(user, message)
	}
	
	get_cvar_string("amx_contactinfo", contact, 63)
	if(contact[0])  {
		format(contactinfo, 111, "%s Kontakt z Adminem -- %s", COLOR, contact)
		print_message(user, contactinfo)
	}
	return PLUGIN_HANDLED;
}

print_message(id, msg[]) {
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

public vipmenu1(id)
{
	if(!get_pcvar_num(g_menu))
		return PLUGIN_CONTINUE
	if(!(get_user_flags(id) & FLAGA))
		return PLUGIN_CONTINUE
	if (!get_pcvar_num(ile_razy_bronvip)) //czy w ogole mozna uzywac kilka razy
		return PLUGIN_CONTINUE
	if (uzylem[id]>get_pcvar_num(ile_razy_bronvip)) //ograniczenie uzywania menu broni
		return PLUGIN_CONTINUE


	new menu = menu_create("\rVIP Menu", "Opcje");
	
	menu_additem(menu, "\wWez \yM4A1+Deagle\d(Granaty+Armor)");
	menu_additem(menu, "\wWez \yAK47+Deagle\d(Granaty+Armor)");
	menu_additem(menu, "\wWez \yAWP+Deagle\d(Granaty+Armor)");
	
	menu_setprop(menu, MPROP_EXITNAME,"Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}


public Opcje(id, menu, item)
{
	Czy_ma_pake(id)
	strip_user_weapons(id) //usuwanie broni
	switch(item){
		case 0: { 
			give_item(id,"weapon_m4a1")
			cs_set_user_bpammo(id, CSW_M4A1, 90)
		}
		case 1: { 
			give_item(id,"weapon_ak47")
			cs_set_user_bpammo(id, CSW_AK47, 90)
		}
		case 2: { 
			give_item(id,"weapon_awp")
			cs_set_user_bpammo(id, CSW_AWP, 30)
		}
	}
	//standardowo - granaty+kamizelka i helm+deagle
	give_item(id,"weapon_deagle")
	give_item(id,"weapon_knife")  
	give_item(id, "item_assaultsuit");
	give_item(id, "item_thighpack");
	cs_set_user_bpammo(id, CSW_DEAGLE, 35)
	addNades(id)
	Mial_pake(id)

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}