#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>

#define PLUGIN "Call of Duty: MW Mod"
#define VERSION "1.0-3"
#define AUTHOR "QTM_Peyote"

#define MAX_WIELKOSC_NAZWY 32
#define MAX_WIELKOSC_OPISU 256
#define MAX_ILOSC_PERKOW 120
#define MAX_ILOSC_KLAS 100

#define STANDARDOWA_SZYBKOSC 250.0

#define ZADANIE_POKAZ_INFORMACJE 672
#define ZADANIE_POKAZ_REKLAME 768
#define ZADANIE_USTAW_SZYBKOSC 832

new const maxAmmo[31] = {0, 52, 0, 90, 1, 31, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 31, 90, 120,
 90, 2, 35, 90, 90,0, 100};

new MsgScreenfade;

new vault;

new SyncHudObj, SyncHudObj2;
 
new cvar_doswiadczenie_za_zabojstwo,
     cvar_doswiadczenie_za_obrazenia,
     cvar_doswiadczenie_za_wygrana,
     cvar_typ_zapisu,
     cvar_limit_poziomu,
     cvar_proporcja_poziomu,
     cvar_blokada_broni;

     
new perk_zmieniony,
     klasa_zmieniona;

     
new nazwy_perkow[MAX_ILOSC_PERKOW+1][MAX_WIELKOSC_NAZWY+1],
     opisy_perkow[MAX_ILOSC_PERKOW+1][MAX_WIELKOSC_OPISU+1],
     max_wartosci_perkow[MAX_ILOSC_PERKOW+1],
     min_wartosci_perkow[MAX_ILOSC_PERKOW+1],
     pluginy_perkow[MAX_ILOSC_PERKOW+1],
     ilosc_perkow;

     
new nazwa_gracza[33][64],
     klasa_gracza[33],
     nowa_klasa_gracza[33],
     poziom_gracza[33],
     doswiadczenie_gracza[33],
     perk_gracza[33],
     wartosc_perku_gracza[33];

new Float:maksymalne_zdrowie_gracza[33],
     Float:szybkosc_gracza[33],
     Float:redukcja_obrazen_gracza[33];
     
new punkty_gracza[33],
     zdrowie_gracza[33],
     inteligencja_gracza[33],
     wytrzymalosc_gracza[33],
     kondycja_gracza[33];

new bool:gracz_ma_tarcze[33],
     bool:gracz_ma_noktowizor[33];     

new bonusowe_bronie_gracza[33],
     bonusowe_zdrowie_gracza[33],
     bonusowa_inteligencja_gracza[33],
     bonusowa_wytrzymalosc_gracza[33],
     bonusowa_kondycja_gracza[33];

new bronie_klasy[MAX_ILOSC_KLAS+1], 
     zdrowie_klas[MAX_ILOSC_KLAS+1],
     kondycja_klas[MAX_ILOSC_KLAS+1], 
     inteligencja_klas[MAX_ILOSC_KLAS+1], 
     wytrzymalosc_klas[MAX_ILOSC_KLAS+1],
     nazwy_klas[MAX_ILOSC_KLAS+1][MAX_WIELKOSC_NAZWY+1],
     opisy_klas[MAX_ILOSC_KLAS+1][MAX_WIELKOSC_OPISU+1],
     pluginy_klas[MAX_ILOSC_KLAS+1],
     ilosc_klas;

new bronie_druzyny[] = {0, 1<<CSW_GLOCK18, 1<<CSW_USP},
     bronie_dozwolone = 1<<CSW_KNIFE | 1<<CSW_C4;

new bool:freezetime = true;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	cvar_doswiadczenie_za_zabojstwo = register_cvar("cod_killxp", "10");
	cvar_doswiadczenie_za_obrazenia = register_cvar("cod_damagexp", "1"); // ilosc doswiadczenia za 20 obrazen 
	cvar_doswiadczenie_za_wygrana = register_cvar("cod_winxp", "50");
	cvar_typ_zapisu = register_cvar("cod_savetype", "2");  // 1-Nick; 2-SID dla Steam; 3-IP
	cvar_limit_poziomu = register_cvar("cod_maxlevel", "200"); 
	cvar_proporcja_poziomu = register_cvar("cod_levelratio", "35"); 
	cvar_blokada_broni = register_cvar("cod_weaponsblocking", "1"); 
	
	register_clcmd("say /klasa", "WybierzKlase");
	register_clcmd("say /class", "WybierzKlase");
	register_clcmd("say /klasy", "OpisKlasy");
	register_clcmd("say /classinfo", "OpisKlasy");
	register_clcmd("say /perk", "KomendaOpisPerku");
	register_clcmd("say /perki", "OpisPerkow");
	register_clcmd("say /perks", "OpisPerkow");
	register_clcmd("say /item", "Pomoc");
	register_clcmd("say /przedmiot", "OpisPerku");
	register_clcmd("say /drop", "WyrzucPerk");
	register_clcmd("say /wyrzuc", "WyrzucPerk");
	register_clcmd("say /reset", "KomendaResetujPunkty");
	register_clcmd("say /statystyki", "PrzydzielPunkty");
	register_clcmd("say /staty", "PrzydzielPunkty");
	register_clcmd("say /pomoc", "Pomoc");
	register_clcmd("useperk", "UzyjPerku");
	register_clcmd("radio3", "UzyjPerku");
	register_clcmd("fullupdate", "BlokujKomende");
	
	register_menucmd(register_menuid("Klasa:"), 1023, "OpisKlasy");
	
	RegisterHam(Ham_TakeDamage, "player", "Obrazenia");
	RegisterHam(Ham_TakeDamage, "player", "ObrazeniaPost", 1);
	RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
	RegisterHam(Ham_Killed, "player", "SmiercGraczaPost", 1);
	
	RegisterHam(Ham_Touch, "armoury_entity", "DotykBroni");
	RegisterHam(Ham_Touch, "weapon_shield", "DotykTarczy");
	RegisterHam(Ham_Touch, "weaponbox", "DotykBroni");
	
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_EmitSound, "EmitSound");
	
	register_message(get_user_msgid("Health"),"MessageHealth");
	
	register_logevent("PoczatekRundy", 2, "1=Round_Start"); 
	
	register_event("SendAudio", "WygranaTerro" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "WygranaCT", "a", "2&%!MRAD_ctwin");
	register_event("CurWeapon","CurWeapon","be", "1=1");
	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
	
	vault = nvault_open("CodMod");
	
	MsgScreenfade = get_user_msgid("ScreenFade");
	
	SyncHudObj = CreateHudSyncObj();
	SyncHudObj2 = CreateHudSyncObj();
	
	perk_zmieniony = CreateMultiForward("cod_perk_changed", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	klasa_zmieniona = CreateMultiForward("cod_class_changed", ET_CONTINUE, FP_CELL, FP_CELL);

	copy(nazwy_perkow[0], MAX_WIELKOSC_NAZWY, "Brak");
	copy(opisy_perkow[0], MAX_WIELKOSC_OPISU, "Zabij kogos, aby otrzymac przedmiot");
	copy(nazwy_klas[0], MAX_WIELKOSC_NAZWY, "Brak");
	
	set_task(1.0, "plugin_cfg");
}		

public plugin_cfg()
{
	new lokalizacja_cfg[33];
	get_configsdir(lokalizacja_cfg, charsmax(lokalizacja_cfg));
	server_cmd("exec %s/codmod.cfg", lokalizacja_cfg);
	server_exec();
}
	

public plugin_precache()
{	
	precache_sound("QTM_CodMod/select.wav");
	precache_sound("QTM_CodMod/start.wav");
	precache_sound("QTM_CodMod/start2.wav");
	precache_sound("QTM_CodMod/levelup.wav");
}

public plugin_natives()
{
	register_native("cod_set_user_xp", "UstawDoswiadczenie", 1);
	register_native("cod_set_user_class", "UstawKlase", 1);
	register_native("cod_set_user_perk", "UstawPerk", 1);
	register_native("cod_set_user_bonus_health", "UstawBonusoweZdrowie", 1);
	register_native("cod_set_user_bonus_intelligence", "UstawBonusowaInteligencje", 1);
	register_native("cod_set_user_bonus_trim", "UstawBonusowaKondycje", 1);
	register_native("cod_set_user_bonus_stamina", "UstawBonusowaWytrzymalosc", 1);
	
	register_native("cod_points_to_health", "PrzydzielZdrowie", 1);	
	register_native("cod_points_to_intelligence", "PrzydzielInteligencje", 1);	
	register_native("cod_points_to_trim", "PrzydzielKondycje", 1);	
	register_native("cod_points_to_stamina", "PrzydzielWytrzymalosc", 1);	
	
	register_native("cod_get_user_xp", "PobierzDoswiadczenie", 1);
	register_native("cod_get_user_level", "PobierzPoziom", 1);
	register_native("cod_get_user_points", "PobierzPunkty", 1);
	register_native("cod_get_user_class", "PobierzKlase", 1);
	register_native("cod_get_user_perk", "PobierzPerk", 1);
	register_native("cod_get_user_health", "PobierzZdrowie", 1);
	register_native("cod_get_user_intelligence", "PobierzInteligencje", 1);
	register_native("cod_get_user_trim", "PobierzKondycje", 1);
	register_native("cod_get_user_stamina", "PobierzWytrzymalosc", 1);
	
	register_native("cod_get_level_xp", "PobierzDoswiadczeniePoziomu", 1);
	
	register_native("cod_get_perkid", "PobierzPerkPrzezNazwe", 1);
	register_native("cod_get_perks_num", "PobierzIloscPerkow", 1);
	register_native("cod_get_perk_name", "PobierzNazwePerku", 1);
	register_native("cod_get_perk_desc", "PobierzOpisPerku", 1);
	
	register_native("cod_get_classid", "PobierzKlasePrzezNazwe", 1);
	register_native("cod_get_classes_num", "PobierzIloscKlas", 1);
	register_native("cod_get_class_name", "PobierzNazweKlasy", 1);
	register_native("cod_get_class_desc", "PobierzOpisKlasy", 1);
	
	register_native("cod_get_class_health", "PobierzZdrowieKlasy", 1);
	register_native("cod_get_class_intelligence", "PobierzInteligencjeKlasy", 1);
	register_native("cod_get_class_trim", "PobierzKondycjeKlasy", 1);
	register_native("cod_get_class_stamina", "PobierzWytrzymaloscKlasy", 1);
	
	register_native("cod_give_weapon", "DajBron", 1);
	register_native("cod_take_weapon", "WezBron", 1);
	register_native("cod_set_user_shield", "UstawTarcze", 1);
	register_native("cod_set_user_nightvision", "UstawNoktowizor", 1);
	
	register_native("cod_inflict_damage", "ZadajObrazenia", 1);
	
	register_native("cod_register_perk", "ZarejestrujPerk");
	register_native("cod_register_class", "ZarejestrujKlase");
}

public CmdStart(id, uc_handle)
{		
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	new Float: velocity[3];
	pev(id, pev_velocity, velocity);
	new Float: speed = vector_length(velocity);
	if(szybkosc_gracza[id] > speed*1.8)
		set_pev(id, pev_flTimeStepSound, 300);
	
	return FMRES_IGNORED;
}

public Odrodzenie(id)
{	
	if(!task_exists(id+ZADANIE_POKAZ_INFORMACJE))
		set_task(0.1, "PokazInformacje", id+ZADANIE_POKAZ_INFORMACJE, _, _, "b");
	
	if(nowa_klasa_gracza[id])
		UstawNowaKlase(id);
	
	if(!klasa_gracza[id])
	{
		WybierzKlase(id);
		return PLUGIN_CONTINUE;
	}
	
	DajBronie(id);
	ZastosujAtrybuty(id);
	
	if(punkty_gracza[id] > 0)
		PrzydzielPunkty(id);

	return PLUGIN_CONTINUE;
}

public UstawNowaKlase(id)
{
	new ret;
		
	new forward_handle = CreateOneForward(pluginy_klas[klasa_gracza[id]], "cod_class_disabled", FP_CELL, FP_CELL);
	ExecuteForward(forward_handle, ret, id, klasa_gracza[id]);
	DestroyForward(forward_handle);
		
	forward_handle = CreateOneForward(pluginy_klas[nowa_klasa_gracza[id]], "cod_class_enabled", FP_CELL, FP_CELL);
	ExecuteForward(forward_handle, ret, id, nowa_klasa_gracza[id]);
	DestroyForward(forward_handle);
	
	
	if(ret == 4)	
	{
		klasa_gracza[id] = 0;
		return PLUGIN_CONTINUE;
	}

	ExecuteForward(klasa_zmieniona, ret, id, klasa_gracza[id]);
	
	if(ret == 4)	
	{
		klasa_gracza[id] = 0;
		return PLUGIN_CONTINUE;
	}
	
	klasa_gracza[id] = nowa_klasa_gracza[id];
	nowa_klasa_gracza[id] = 0;
	UstawPerk(id, perk_gracza[id], wartosc_perku_gracza[id], 0);
	
	WczytajDane(id, klasa_gracza[id]);
	return PLUGIN_CONTINUE;
}

public DajBronie(id)
{
	for(new i=1; i < 32; i++)
	{
		if((1<<i) & (bronie_klasy[klasa_gracza[id]] | bonusowe_bronie_gracza[id]))
		{
			new weaponname[22];
			get_weaponname(i, weaponname, 21);
			fm_give_item(id, weaponname);
		}
	}
	
	if(gracz_ma_tarcze[id])
		fm_give_item(id, "weapon_shield");
		
	if(gracz_ma_noktowizor[id])
		cs_set_user_nvg(id, 1);
	
	new weapons[32];
	new weaponsnum;
	get_user_weapons(id, weapons, weaponsnum);
	for(new i=0; i<weaponsnum; i++)
		if(is_user_alive(id))
			if(maxAmmo[weapons[i]] > 0)
				cs_set_user_bpammo(id, weapons[i], maxAmmo[weapons[i]]);
}

public ZastosujAtrybuty(id)
{
	redukcja_obrazen_gracza[id] = 0.7*(1.0-floatpower(1.1, -0.112311341*PobierzWytrzymalosc(id, 1, 1, 1)));
	
	maksymalne_zdrowie_gracza[id] = 100.0+PobierzZdrowie(id, 1, 1, 1);
	
	szybkosc_gracza[id] = STANDARDOWA_SZYBKOSC+PobierzKondycje(id, 1, 1, 1)*1.3;
	
	set_pev(id, pev_health, maksymalne_zdrowie_gracza[id]);
}

public PoczatekRundy()	
{
	freezetime = false;
	for(new id=0;id<=32;id++)
	{
		if(!is_user_alive(id))
			continue;

		Display_Fade(id, 1<<9, 1<<9, 1<<12, 0, 255, 70, 100);
		
		set_task(0.1, "UstawSzybkosc", id+ZADANIE_USTAW_SZYBKOSC);
		
		switch(get_user_team(id))
		{
			case 1: client_cmd(id, "spk QTM_CodMod/start2");
			case 2: client_cmd(id, "spk QTM_CodMod/start");
		}
	}
}

public NowaRunda()
	freezetime = true;

public Obrazenia(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_alive(idattacker))
		return HAM_IGNORED;

	if(get_user_team(this) == get_user_team(idattacker))
		return HAM_IGNORED;
		
	if(get_user_health(this) <= 1)
		return HAM_IGNORED;
	
	SetHamParamFloat(4, damage*(1.0-redukcja_obrazen_gracza[this]));
		
	return HAM_IGNORED;
}

public ObrazeniaPost(id, idinflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_connected(attacker) || !klasa_gracza[attacker])
		return HAM_IGNORED;
	
	if(get_user_team(id) != get_user_team(attacker))
	{
		new doswiadczenie_za_obrazenia = get_pcvar_num(cvar_doswiadczenie_za_obrazenia);
		while(damage>20)
		{
			damage -= 20;
			doswiadczenie_gracza[attacker] += doswiadczenie_za_obrazenia;
		}
	}
	SprawdzPoziom(attacker);
	return HAM_IGNORED;
}

public SmiercGraczaPost(id, attacker, shouldgib)
{	
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
		
	if(get_user_team(id) != get_user_team(attacker) && klasa_gracza[attacker])
	{
		new doswiadczenie_za_zabojstwo = get_pcvar_num(cvar_doswiadczenie_za_zabojstwo);
		new nowe_doswiadczenie = get_pcvar_num(cvar_doswiadczenie_za_zabojstwo);
		
		if(poziom_gracza[id] > poziom_gracza[attacker])
			nowe_doswiadczenie += (poziom_gracza[id]-poziom_gracza[attacker])*(doswiadczenie_za_zabojstwo/10);
			
		if(!perk_gracza[attacker])
			UstawPerk(attacker, -1, -1, 1);
		doswiadczenie_gracza[attacker] += nowe_doswiadczenie;
	}
	
	SprawdzPoziom(attacker);
	
	return HAM_IGNORED;
}


public MessageHealth(msg_id, msg_dest, msg_entity)
{
	static health;
	health = get_msg_arg_int(1);
	
	if (health < 256) return;
	
	if (!(health % 256))
		set_pev(msg_entity, pev_health, pev(msg_entity, pev_health)-1);
	
	set_msg_arg_int(1, get_msg_argtype(1), 255);
}

public client_authorized(id)
{
	UsunUmiejetnosci(id);

	get_user_name(id, nazwa_gracza[id], 63);
	
	UsunZadania(id);
	
	set_task(10.0, "PokazReklame", id+ZADANIE_POKAZ_REKLAME);
}

public client_disconnect(id)
{
	ZapiszDane(id);
	UsunUmiejetnosci(id);
	UsunZadania(id);
}

public UsunUmiejetnosci(id)
{
	nowa_klasa_gracza[id] = 0;
	UstawNowaKlase(id);
	klasa_gracza[id] = 0;
	poziom_gracza[id] = 0;
	doswiadczenie_gracza[id] = 0;
	punkty_gracza[id] = 0;
	zdrowie_gracza[id] = 0;
	inteligencja_gracza[id] = 0;
	wytrzymalosc_gracza[id] = 0;
	kondycja_gracza[id] = 0;
	bonusowe_zdrowie_gracza[id] = 0;
	bonusowa_wytrzymalosc_gracza[id] = 0;
	bonusowa_inteligencja_gracza[id] = 0;
	bonusowa_kondycja_gracza[id] = 0;
	maksymalne_zdrowie_gracza[id] = 0.0;
	szybkosc_gracza[id] = 0.0;
	UstawPerk(id, 0, 0, 0);
}

public UsunZadania(id)
{
	remove_task(id+ZADANIE_POKAZ_INFORMACJE);
	remove_task(id+ZADANIE_POKAZ_REKLAME);	
	remove_task(id+ZADANIE_USTAW_SZYBKOSC);
}
	
public WygranaTerro()
	WygranaRunda("TERRORIST");
	
public WygranaCT()
	WygranaRunda("CT");

public WygranaRunda(const Team[])
{
	new Players[32], playerCount, id;
	get_players(Players, playerCount, "aeh", Team);
	new doswiadczenie_za_wygrana = get_pcvar_num(cvar_doswiadczenie_za_wygrana);
	
	if(get_playersnum() < 3)
		return;
		
	for (new i=0; i<playerCount; i++) 
	{
		id = Players[i];
		if(!klasa_gracza[id])
			continue;
		
		doswiadczenie_gracza[id] += doswiadczenie_za_wygrana;
		client_print(id, print_chat, "[COD:MW] Dostales %i doswiadczenia za wygrana runde.", doswiadczenie_za_wygrana);
		SprawdzPoziom(id);
	}
}

public KomendaOpisPerku(id)
	OpisPerku(id, perk_gracza[id], wartosc_perku_gracza[id]);
	
public OpisPerku(id, perk, wartosc)
{
	new opis_perku[MAX_WIELKOSC_OPISU];
	new losowa_wartosc[15];
	if(wartosc > -1)
		num_to_str(wartosc, losowa_wartosc, 14);
	else
		format(losowa_wartosc, charsmax(losowa_wartosc), "%i-%i", min_wartosci_perkow[perk], max_wartosci_perkow[perk]);
		
	format(opis_perku, charsmax(opis_perku), opisy_perkow[perk]);
	replace_all(opis_perku, charsmax(opis_perku), "LW", losowa_wartosc);
	
	client_print(id, print_chat, "Perk: %s.", nazwy_perkow[perk]);
	client_print(id, print_chat, "Opis: %s.", opis_perku);
}

public OpisPerkow(id)
{
	new menu = menu_create("Wybierz Perk:", "OpisPerkow_Handle");
	for(new i=1; i <= ilosc_perkow; i++)
		menu_additem(menu, nazwy_perkow[i]);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
	client_cmd(id, "spk QTM_CodMod/select");
}

public OpisPerkow_Handle(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	OpisPerku(id, item, -1);
	OpisPerkow(id);
	return PLUGIN_CONTINUE;
}


public OpisKlasy(id)
{
	new menu = menu_create("Wybierz klase:", "OpisKlasy_Handle");
	for(new i=1; i <= ilosc_klas; i++)
		menu_additem(menu, nazwy_klas[i]);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
	
	client_cmd(id, "spk QTM_CodMod/select");
}

public OpisKlasy_Handle(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new bronie[320];
	for(new i=1, n=1; i <= 32; i++)
	{
		if((1<<i) & bronie_klasy[item])
		{
			new weaponname[22];
			get_weaponname(i, weaponname, 21);
			replace_all(weaponname, 21, "weapon_", " ");
			if(n > 1)	
				add(bronie, charsmax(bronie), ",");
			add(bronie, charsmax(bronie), weaponname);
			n++;
		}
	}
	
	new opis[416+MAX_WIELKOSC_OPISU];
	format(opis, charsmax(opis), "\yKlasa: \w%s^n\yInteligencja: \w%i^n\yZdrowie: \w%i^n\yWytrzymalosc: \w%i^n\yKondycja: \w%i^n\yBronie:\w%s^n\yDodatkowy opis: \w%s^n%s", nazwy_klas[item], inteligencja_klas[item], zdrowie_klas[item], wytrzymalosc_klas[item], kondycja_klas[item], bronie, opisy_klas[item], opisy_klas[item][79]);
	show_menu(id, 1023, opis);
	
	return PLUGIN_CONTINUE;
}

public WybierzKlase(id)
{
	new menu = menu_create("Wybierz klase:", "WybierzKlase_Handle");
	new klasa[50];
	for(new i=1; i <= ilosc_klas; i++)
	{
		WczytajDane(id, i);
		format(klasa, charsmax(klasa), "%s \yPoziom: %i", nazwy_klas[i], poziom_gracza[id]);
		menu_additem(menu, klasa);
	}
	
	WczytajDane(id, klasa_gracza[id]);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	menu_display(id, menu);
		
	client_cmd(id, "spk QTM_CodMod/select");
}

public WybierzKlase_Handle(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}	
	
	if(item == klasa_gracza[id] && !nowa_klasa_gracza[id])
		return PLUGIN_CONTINUE;
	
	nowa_klasa_gracza[id] = item;
	
	if(klasa_gracza[id])
		client_print(id, print_chat, "[COD:MW] Klasa zostanie zmieniona w nastepnej rundzie.");
	else
	{
		UstawNowaKlase(id);
		DajBronie(id);
		ZastosujAtrybuty(id);
	}
	
	return PLUGIN_CONTINUE;
}

public PrzydzielPunkty(id)
{
	new inteligencja[65];
	new zdrowie[60];
	new wytrzymalosc[60];
	new kondycja[60];
	new tytul[25];
	format(inteligencja, charsmax(inteligencja), "Inteligencja: \r%i \y(Zwieksza sile perkow i umiejetnosci klasy)", PobierzInteligencje(id, 1, 1, 1));
	format(zdrowie, charsmax(zdrowie), "Zdrowie: \r%i \y(Zwieksza zdrowie)", PobierzZdrowie(id, 1, 1, 1));
	format(wytrzymalosc, charsmax(wytrzymalosc), "Wytrzymalosc: \r%i \y(Zmniejsza obrazenia)", PobierzWytrzymalosc(id, 1, 1, 1));
	format(kondycja, charsmax(kondycja), "Kondycja: \r%i \y(Zwieksza tempo chodu)", PobierzKondycje(id, 1, 1, 1));
	format(tytul, charsmax(tytul), "Przydziel Punkty(%i):", punkty_gracza[id]);
	new menu = menu_create(tytul, "PrzydzielPunkty_Handler");
	menu_additem(menu, inteligencja);
	menu_additem(menu, zdrowie);
	menu_additem(menu, wytrzymalosc);
	menu_additem(menu, kondycja);
	menu_setprop(menu, MPROP_EXIT, 0);
	menu_display(id, menu);
}

public PrzydzielPunkty_Handler(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if(punkty_gracza[id] < 1)
		return PLUGIN_CONTINUE;
	
	new limit_poziomu = get_pcvar_num(cvar_limit_poziomu);
	
	switch(item) 
	{ 
		case 0: 
		{	
			if(inteligencja_gracza[id] < limit_poziomu/2)
			{
				inteligencja_gracza[id]++;
				punkty_gracza[id]--;
			}
			else 
				client_print(id, print_chat, "[COD:MW] Maxymalny poziom inteligencji osiagniety");

			
		}
		case 1: 
		{	
			if(zdrowie_gracza[id] < limit_poziomu/2)
			{
				zdrowie_gracza[id]++;
				punkty_gracza[id]--;
			}
			else 
				client_print(id, print_chat, "[COD:MW] Maxymalny poziom sily osiagniety");
		}
		case 2: 
		{	
			if(wytrzymalosc_gracza[id] < limit_poziomu/2)
			{
				wytrzymalosc_gracza[id]++;
				punkty_gracza[id]--;
			}
			else 
				client_print(id, print_chat, "[COD:MW] Maxymalny poziom zrecznosci osiagniety");
			
		}
		case 3: 
		{	
			if(kondycja_gracza[id] < limit_poziomu/2)
			{
				kondycja_gracza[id]++;
				punkty_gracza[id]--;
			}
			else
				client_print(id, print_chat, "[COD:MW] Maxymalny poziom kondycji osiagniety");
		}
	}
	
	if(punkty_gracza[id] > 0)
		PrzydzielPunkty(id);
		
	return PLUGIN_CONTINUE;
}

public KomendaResetujPunkty(id)
{	
	client_print(id, print_chat, "[COD:MW] Umiejetnosci zostana zresetowane.");
	client_cmd(id, "spk QTM_CodMod/select");
	
	ResetujPunkty(id);
}

public ResetujPunkty(id)
{
	punkty_gracza[id] = (poziom_gracza[id]-1)*2;
	inteligencja_gracza[id] = 0;
	zdrowie_gracza[id] = 0;
	kondycja_gracza[id] = 0;
	wytrzymalosc_gracza[id] = 0;
	
	if(punkty_gracza[id])
		PrzydzielPunkty(id);
}

public CurWeapon(id)
{
	if(!is_user_connected(id))
		return;
		
	new team = get_user_team(id);
	
	if(team > 2)
		return;
		
	new bron = read_data(2);
		
	new bronie = (bronie_klasy[klasa_gracza[id]] | bonusowe_bronie_gracza[id] | bronie_druzyny[team] | bronie_dozwolone);
	
	if(!(1<<bron & bronie))
	{
		new weaponname[22];
		
		get_weaponname(bron, weaponname, 21);
		ham_strip_weapon(id, weaponname);
	}
	
	if(cs_get_user_shield(id) && !gracz_ma_tarcze[id])
		engclient_cmd(id, "drop", "weapon_shield");	
		
	UstawSzybkosc(id);
}

public EmitSound(id, iChannel, szSound[], Float:fVol, Float:fAttn, iFlags, iPitch ) 
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
		
	if(equal(szSound, "common/wpn_denyselect.wav"))
	{
		new forward_handle = CreateOneForward(pluginy_klas[klasa_gracza[id]], "cod_class_skill_used", FP_CELL);
		ExecuteForward(forward_handle, id, id);
		DestroyForward(forward_handle);
		return FMRES_SUPERCEDE;
	}

	if(equal(szSound, "items/ammopickup2.wav"))
	{
		cs_set_user_armor(id, 0, CS_ARMOR_NONE);
		return FMRES_SUPERCEDE;
	}
	
	if(equal(szSound, "items/equip_nvg.wav") && !gracz_ma_noktowizor[id])
	{
		cs_set_user_nvg(id, 0);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public UzyjPerku(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
		
	new forward_handle = CreateOneForward(pluginy_perkow[perk_gracza[id]], "cod_perk_used", FP_CELL);
	ExecuteForward(forward_handle, id, id);
	DestroyForward(forward_handle);
	return PLUGIN_HANDLED;
}

public ZapiszDane(id)
{
	if(!klasa_gracza[id])
		return PLUGIN_CONTINUE;
		
	new vaultkey[128],vaultdata[256], identyfikator[64];
	format(vaultdata, charsmax(vaultdata),"#%i#%i#%i#%i#%i#%i", doswiadczenie_gracza[id], poziom_gracza[id], inteligencja_gracza[id], zdrowie_gracza[id], wytrzymalosc_gracza[id], kondycja_gracza[id]);
	
	new typ_zapisu = get_pcvar_num(cvar_typ_zapisu);
	
	switch(typ_zapisu)
	{
		case 1: copy(identyfikator, charsmax(identyfikator), nazwa_gracza[id]);
		case 2: get_user_authid(id, identyfikator, charsmax(identyfikator));
		case 3: get_user_ip(id, identyfikator, charsmax(identyfikator));
	}
		
	format(vaultkey, charsmax(vaultkey),"%s-%s-%i-cod", identyfikator, nazwy_klas[klasa_gracza[id]], typ_zapisu);
	nvault_set(vault,vaultkey,vaultdata);
	
	return PLUGIN_CONTINUE;
}

public WczytajDane(id, klasa)
{
	new vaultkey[128],vaultdata[256], identyfikator[64];
	
	new typ_zapisu = get_pcvar_num(cvar_typ_zapisu);
	
	switch(typ_zapisu)
	{
		case 1: copy(identyfikator, charsmax(identyfikator), nazwa_gracza[id]);
		case 2: get_user_authid(id, identyfikator, charsmax(identyfikator));
		case 3: get_user_ip(id, identyfikator, charsmax(identyfikator));
	}
	
	format(vaultkey, charsmax(vaultkey),"%s-%s-%i-cod", identyfikator, nazwy_klas[klasa], typ_zapisu);
	

	if(!nvault_get(vault,vaultkey,vaultdata,255)) // Jezeli nie ma danych gracza sprawdza stary zapis. 
	{
		format(vaultkey, charsmax(vaultkey), "%s-%i-cod", nazwa_gracza[id], klasa);
		nvault_get(vault,vaultkey,vaultdata,255);
	}

	replace_all(vaultdata, 255, "#", " ");
	 
	new danegracza[6][32];
	
	parse(vaultdata, danegracza[0], 31, danegracza[1], 31, danegracza[2], 31, danegracza[3], 31, danegracza[4], 31, danegracza[5], 31);
	
	doswiadczenie_gracza[id] = str_to_num(danegracza[0]);
	poziom_gracza[id] = str_to_num(danegracza[1])>0?str_to_num(danegracza[1]):1;
	inteligencja_gracza[id] = str_to_num(danegracza[2]);
	zdrowie_gracza[id] = str_to_num(danegracza[3]);
	wytrzymalosc_gracza[id] = str_to_num(danegracza[4]);
	kondycja_gracza[id] = str_to_num(danegracza[5]);
	punkty_gracza[id] = (poziom_gracza[id]-1)*2-inteligencja_gracza[id]-zdrowie_gracza[id]-wytrzymalosc_gracza[id]-kondycja_gracza[id];
	
	return PLUGIN_CONTINUE;
} 


public WyrzucPerk(id)
{
	if(perk_gracza[id])
	{
		client_print(id, print_chat, "[COD:MW] Wyrzuciles %s.", nazwy_perkow[perk_gracza[id]]);
		UstawPerk(id, 0, 0, 0);
	}
	else
		client_print(id, print_chat, "[COD:MW] Nie masz zadnego perku.");
}

public SprawdzPoziom(id)
{	
	if(!is_user_connected(id))
		return;
		
	new limit_poziomu = get_pcvar_num(cvar_limit_poziomu);
	
	new bool:zdobyl_poziom = false, bool:stracil_poziom = false;
	
	while(doswiadczenie_gracza[id] >= PobierzDoswiadczeniePoziomu(poziom_gracza[id]) && poziom_gracza[id] < limit_poziomu)
	{
		poziom_gracza[id]++;
		punkty_gracza[id] = (poziom_gracza[id]-1)*2-inteligencja_gracza[id]-zdrowie_gracza[id]-wytrzymalosc_gracza[id]-kondycja_gracza[id];
		zdobyl_poziom = true;
	}
		
	while(doswiadczenie_gracza[id] < PobierzDoswiadczeniePoziomu(poziom_gracza[id]-1))
	{
		poziom_gracza[id]--;
		stracil_poziom = true;
	}
		
	if(poziom_gracza[id] > limit_poziomu)
	{
		poziom_gracza[id] = limit_poziomu;
		ResetujPunkty(id);
	}
	
	if(stracil_poziom)
	{
		ResetujPunkty(id);
		set_hudmessage(212, 255, 85, 0.31, 0.32, 0, 6.0, 5.0);
		ShowSyncHudMsg(id, SyncHudObj2,"Spadles do %i poziomu!", poziom_gracza[id]);
	}
	else if(zdobyl_poziom)
	{
		punkty_gracza[id] = (poziom_gracza[id]-1)*2-inteligencja_gracza[id]-zdrowie_gracza[id]-wytrzymalosc_gracza[id]-kondycja_gracza[id];
		set_hudmessage(212, 255, 85, 0.31, 0.32, 0, 6.0, 5.0);
		ShowSyncHudMsg(id, SyncHudObj2,"Awansowales do %i poziomu!", poziom_gracza[id]);
		client_cmd(id, "spk QTM_CodMod/levelup");
	}
		
			
	ZapiszDane(id);
}

public PokazInformacje(id) 
{
	id -= ZADANIE_POKAZ_INFORMACJE;
		
	if(!is_user_connected(id))
	{
		remove_task(id+ZADANIE_POKAZ_INFORMACJE);
		return PLUGIN_CONTINUE;
	}
	
	if(!is_user_alive(id))
	{
		new target = pev(id, pev_iuser2);
	
		if(!target)
			return PLUGIN_CONTINUE;
			
		set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.3, 0.0, 0.0, 2);
		ShowSyncHudMsg(id, SyncHudObj, "Klasa : %s^nDoswiadczenie : %i / %i^nPoziom : %i^nPerk : %s", nazwy_klas[klasa_gracza[target]], doswiadczenie_gracza[target], PobierzDoswiadczeniePoziomu(poziom_gracza[target]), poziom_gracza[target], nazwy_perkow[perk_gracza[target]]);
		return PLUGIN_CONTINUE;
	}
	
	set_hudmessage(0, 255, 0, 0.02, 0.23, 0, 0.0, 0.3, 0.0, 0.0);
	ShowSyncHudMsg(id, SyncHudObj, "[Klasa : %s]^n[Doswiadczenie : %i / %i]^n[Poziom : %i]^n[Perk : %s]", nazwy_klas[klasa_gracza[id]], doswiadczenie_gracza[id], PobierzDoswiadczeniePoziomu(poziom_gracza[id]), poziom_gracza[id], nazwy_perkow[perk_gracza[id]]);
	
	return PLUGIN_CONTINUE;
}  

public PokazReklame(id)
{
	id-=ZADANIE_POKAZ_REKLAME;
	client_print(id, print_chat, "[COD:MW] Witaj w Modyfikacji Call of Duty stworzonej przez QTM_Peyote");
	client_print(id, print_chat, "[COD:MW] W celu uzyskania informacji o komendach napisz /pomoc.");
}

public Pomoc(id)
	show_menu(id, 1023, "\y/reset\w - resetuje statystyki^n\y/statystyki\w - wyswietla statystyki^n\y/klasa\w - uruchamia menu wyboru klas^n\y/wyrzuc\w - wyrzuca perk^n\y/perk\w - pokazuje opis twojego perku^n\y/klasy\w - pokazuje opisy klas^n\y+use\w - Uzycie umiejetnosci klasy^n\yradio3\w (standardowo C) lub  \yuseperk\w - Uzycie perku", -1, "Pomoc");

public UstawSzybkosc(id)
{
	id -= id>32? ZADANIE_USTAW_SZYBKOSC: 0;
	
	if(klasa_gracza[id] && !freezetime)
		set_pev(id, pev_maxspeed, szybkosc_gracza[id]);
}

public DotykBroni(weapon, id)
{
	if(get_pcvar_num(cvar_blokada_broni) < 1)
		return HAM_IGNORED;
	
	if(!is_user_connected(id))
		return HAM_IGNORED;
		
	new model[23];
	pev(weapon, pev_model, model, 22);
	if (pev(weapon, pev_owner) == id || containi(model, "w_backpack") != -1)
		return HAM_IGNORED;
	return HAM_SUPERCEDE;
}

public DotykTarczy(weapon, id)
{
	if(get_pcvar_num(cvar_blokada_broni) < 1)
		return HAM_IGNORED;
	
	if(!is_user_connected(id))
		return HAM_IGNORED;
		
	if(gracz_ma_tarcze[id])
		return HAM_IGNORED;
		
	return HAM_SUPERCEDE;
}
	
public UstawPerk(id, perk, wartosc, pokaz_info)
{
	if(!ilosc_perkow)
		return PLUGIN_CONTINUE;
	
	static obroty[33];
	
	if(obroty[id]++ >= 5)
	{
		UstawPerk(id, 0, 0, 0);
		obroty[id] = 0;
		return PLUGIN_CONTINUE;
	}
	
	perk = (perk == -1)? random_num(1, ilosc_perkow): perk;
	wartosc = (wartosc == -1 || min_wartosci_perkow[perk] > wartosc ||  wartosc > max_wartosci_perkow[perk])? random_num(min_wartosci_perkow[perk], max_wartosci_perkow[perk]): wartosc; 
	
	new ret;
	
	new forward_handle = CreateOneForward(pluginy_perkow[perk_gracza[id]], "cod_perk_disabled", FP_CELL, FP_CELL);
	ExecuteForward(forward_handle, ret, id, perk);
	DestroyForward(forward_handle);
	
	perk_gracza[id] = 0;
	
	forward_handle = CreateOneForward(pluginy_perkow[perk], "cod_perk_enabled", FP_CELL, FP_CELL, FP_CELL);
	ExecuteForward(forward_handle, ret, id, wartosc, perk);
	DestroyForward(forward_handle);
	
	if(ret == 4)
	{
		UstawPerk(id, -1, -1, 1);
		return PLUGIN_CONTINUE;
	}
	
	ExecuteForward(perk_zmieniony, ret, id, perk, wartosc);
	
	if(ret == 4)
	{
		UstawPerk(id, -1, -1, 1);
		return PLUGIN_CONTINUE;
	}
	
	perk_gracza[id] = perk;	
	wartosc_perku_gracza[id] = wartosc;
	
	obroty[id] = 0;
	
	if(pokaz_info && perk_gracza[id]) 
		client_print(id, print_chat, "[COD:MW] Zdobyles %s.", nazwy_perkow[perk_gracza[id]]);
	
	return PLUGIN_CONTINUE;
}

public UstawDoswiadczenie(id, wartosc)
{
	doswiadczenie_gracza[id] = wartosc;
	SprawdzPoziom(id);
}

public UstawKlase(id, klasa, zmien)
{
	nowa_klasa_gracza[id] = klasa;
	if(zmien)
	{
		UstawNowaKlase(id);
		DajBronie(id);
		ZastosujAtrybuty(id);
	}
}

public UstawTarcze(id, wartosc)
{
	if((gracz_ma_tarcze[id] = (wartosc > 0)))
		fm_give_item(id, "weapon_shield");
}

public UstawNoktowizor(id, wartosc)
{
	if((gracz_ma_noktowizor[id] = (wartosc > 0)))
		cs_set_user_nvg(id, 1);
}

public DajBron(id, bron)
{
	bonusowe_bronie_gracza[id] |= (1<<bron);
	new weaponname[22];
	get_weaponname(bron, weaponname, 21);
	return fm_give_item(id, weaponname);
}

public WezBron(id, bron)
{
	bonusowe_bronie_gracza[id] &= ~(1<<bron);
	
	if((1<<bron) & (bronie_dozwolone | bronie_klasy[get_user_team(id)] | bronie_klasy[klasa_gracza[id]])) 
		return;
	
	new weaponname[22];
	get_weaponname(bron, weaponname, 21);
	if(!((1<<bron) & (1<<CSW_HEGRENADE | 1<<CSW_SMOKEGRENADE | 1<<CSW_FLASHBANG)))
		engclient_cmd(id, "drop", weaponname);
}

public UstawBonusoweZdrowie(id, wartosc)
	bonusowe_zdrowie_gracza[id] = wartosc;


public UstawBonusowaInteligencje(id, wartosc)
	bonusowa_inteligencja_gracza[id] = wartosc;

	
public UstawBonusowaKondycje(id, wartosc)
	bonusowa_kondycja_gracza[id] = wartosc;

	
public UstawBonusowaWytrzymalosc(id, wartosc)
	bonusowa_wytrzymalosc_gracza[id] = wartosc;

public PrzydzielZdrowie(id, wartosc)
{
	new max_statystyka = get_pcvar_num(cvar_limit_poziomu)/2;
	wartosc = min(min(punkty_gracza[id], wartosc), max_statystyka-zdrowie_gracza[id]);
	
	punkty_gracza[id] -= wartosc;
	zdrowie_gracza[id] += wartosc;
}

public PrzydzielInteligencje(id, wartosc)
{
	new max_statystyka = get_pcvar_num(cvar_limit_poziomu)/2;
	wartosc = min(min(punkty_gracza[id], wartosc), max_statystyka-inteligencja_gracza[id]);
	
	punkty_gracza[id] -= wartosc;
	inteligencja_gracza[id] += wartosc;
}

public PrzydzielKondycje(id, wartosc)
{
	new max_statystyka = get_pcvar_num(cvar_limit_poziomu)/2;
	wartosc = min(min(punkty_gracza[id], wartosc), max_statystyka-kondycja_gracza[id]);
	
	punkty_gracza[id] -= wartosc;
	kondycja_gracza[id] += wartosc;
}

public PrzydzielWytrzymalosc(id, wartosc)
{
	new max_statystyka = get_pcvar_num(cvar_limit_poziomu)/2;
	wartosc = min(min(punkty_gracza[id], wartosc), max_statystyka-wytrzymalosc_gracza[id]);
	
	punkty_gracza[id] -= wartosc;
	wytrzymalosc_gracza[id] += wartosc;
}

public PobierzPerk(id, &wartosc)
{
	wartosc = wartosc_perku_gracza[id];
	return perk_gracza[id];
}
	
public PobierzIloscPerkow()
	return ilosc_perkow;
	
	
public PobierzNazwePerku(perk, Return[], len)
{
	if(perk <= ilosc_perkow)
	{
		param_convert(2);
		copy(Return, len, nazwy_perkow[perk]);
	}
}
		
public PobierzOpisPerku(perk, Return[], len)
{
	if(perk <= ilosc_perkow)
	{
		param_convert(2);
		copy(Return, len, opisy_perkow[perk]);
	}
}
	
public PobierzPerkPrzezNazwe(const nazwa[])
{
	param_convert(1);
	for(new i=1; i <= ilosc_perkow; i++)
		if(equal(nazwa, nazwy_perkow[i]))
			return i;
	return 0;
}

public PobierzDoswiadczeniePoziomu(poziom)
	return power(poziom, 2)*get_pcvar_num(cvar_proporcja_poziomu);

public PobierzDoswiadczenie(id)
	return doswiadczenie_gracza[id];
	
public PobierzPunkty(id)
	return punkty_gracza[id];
	
public PobierzPoziom(id)
	return poziom_gracza[id];

public PobierzZdrowie(id, zdrowie_zdobyte, zdrowie_klasy, zdrowie_bonusowe)
{
	new zdrowie;
	
	if(zdrowie_zdobyte)
		zdrowie += zdrowie_gracza[id];
	if(zdrowie_bonusowe)
		zdrowie += bonusowe_zdrowie_gracza[id];
	if(zdrowie_klasy)
		zdrowie += zdrowie_klas[klasa_gracza[id]];
	
	return zdrowie;
}

public PobierzInteligencje(id, inteligencja_zdobyta, inteligencja_klasy, inteligencja_bonusowa)
{
	new inteligencja;
	
	if(inteligencja_zdobyta)
		inteligencja += inteligencja_gracza[id];
	if(inteligencja_bonusowa)
		inteligencja += bonusowa_inteligencja_gracza[id];
	if(inteligencja_klasy)
		inteligencja += inteligencja_klas[klasa_gracza[id]];
	
	return inteligencja;
}

public PobierzKondycje(id, kondycja_zdobyta, kondycja_klasy, kondycja_bonusowa)
{
	new kondycja;
	
	if(kondycja_zdobyta)
		kondycja += kondycja_gracza[id];
	if(kondycja_bonusowa)
		kondycja += bonusowa_kondycja_gracza[id];
	if(kondycja_klasy)
		kondycja += kondycja_klas[klasa_gracza[id]];
	
	return kondycja;
}

public PobierzWytrzymalosc(id, wytrzymalosc_zdobyta, wytrzymalosc_klasy, wytrzymalosc_bonusowa)
{
	new wytrzymalosc;
	
	if(wytrzymalosc_zdobyta)
		wytrzymalosc += wytrzymalosc_gracza[id];
	if(wytrzymalosc_bonusowa)
		wytrzymalosc += bonusowa_wytrzymalosc_gracza[id];
	if(wytrzymalosc_klasy)
		wytrzymalosc += wytrzymalosc_klas[klasa_gracza[id]];
	
	return wytrzymalosc;
}

public PobierzKlase(id)
	return klasa_gracza[id];
	
public PobierzIloscKlas()
	return ilosc_klas;
	
public PobierzNazweKlasy(klasa, Return[], len)
{
	if(klasa <= ilosc_klas)
	{
		param_convert(2);
		copy(Return, len, nazwy_klas[klasa]);
	}
}

public PobierzOpisKlasy(klasa, Return[], len)
{
	if(klasa <= ilosc_klas)
	{
		param_convert(2);
		copy(Return, len, opisy_klas[klasa]);
	}
}

public PobierzKlasePrzezNazwe(const nazwa[])
{
	param_convert(1);
	for(new i=1; i <= ilosc_klas; i++)
		if(equal(nazwa, nazwy_klas[i]))
			return i;
	return 0;
}

public PobierzZdrowieKlasy(klasa)
{
	if(klasa <= ilosc_klas)
		return zdrowie_klas[klasa];
	return -1;
}

public PobierzInteligencjeKlasy(klasa)
{
	if(klasa <= ilosc_klas)
		return inteligencja_klas[klasa];
	return -1;
}

public PobierzKondycjeKlasy(klasa)
{
	if(klasa <= ilosc_klas)
		return kondycja_klas[klasa];
	return -1;
}

public PobierzWytrzymaloscKlasy(klasa)
{
	if(klasa <= ilosc_klas)
		return wytrzymalosc_klas[klasa];
	return -1;
}

public ZadajObrazenia(atakujacy, ofiara, Float:obrazenia, Float:czynnik_inteligencji, byt_uszkadzajacy, dodatkowe_flagi)
	ExecuteHam(Ham_TakeDamage, ofiara, byt_uszkadzajacy, atakujacy, obrazenia+PobierzInteligencje(atakujacy, 1, 1, 1)*czynnik_inteligencji, (1<<31) | dodatkowe_flagi);
	
public ZarejestrujPerk(plugin, params)
{
	if(params != 4)
		return PLUGIN_CONTINUE;
		
	if(++ilosc_perkow > MAX_ILOSC_PERKOW)
		return -1;
		
	pluginy_perkow[ilosc_perkow] = plugin;
	get_string(1, nazwy_perkow[ilosc_perkow], MAX_WIELKOSC_NAZWY);
	get_string(2, opisy_perkow[ilosc_perkow], MAX_WIELKOSC_OPISU);
	min_wartosci_perkow[ilosc_perkow] = get_param(3);
	max_wartosci_perkow[ilosc_perkow] = get_param(4);
	
	return ilosc_perkow;
}

public ZarejestrujKlase(plugin, params)
{
	if(params != 7)
		return PLUGIN_CONTINUE;
		
	if(++ilosc_klas > MAX_ILOSC_KLAS)
		return -1;

	pluginy_klas[ilosc_klas] = plugin;
	
	get_string(1, nazwy_klas[ilosc_klas], MAX_WIELKOSC_NAZWY);
	get_string(2, opisy_klas[ilosc_klas], MAX_WIELKOSC_OPISU);
	
	bronie_klasy[ilosc_klas] = get_param(3);
	zdrowie_klas[ilosc_klas] = get_param(4);
	kondycja_klas[ilosc_klas] = get_param(5);
	inteligencja_klas[ilosc_klas] = get_param(6);
	wytrzymalosc_klas[ilosc_klas] = get_param(7);
	
	return ilosc_klas;
}

stock ham_strip_weapon(id, weapon[])
{
	if(!equal(weapon, "weapon_", 7) ) return 0
	new wId = get_weaponid(weapon)
	if(!wId) return 0
	new wEnt
	while( (wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname", weapon) ) && pev(wEnt, pev_owner) != id) {}
	if(!wEnt) return 0
	
	if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt)
	
	if(!ExecuteHamB(Ham_RemovePlayerItem, id, wEnt)) return 0
	ExecuteHamB(Ham_Item_Kill ,wEnt)
	
	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId) )
	return 1
}

stock Display_Fade(id,duration,holdtime,fadetype,red,green,blue,alpha)
{
	message_begin( MSG_ONE, MsgScreenfade,{0,0,0},id );
	write_short( duration );	// Duration of fadeout
	write_short( holdtime );	// Hold time of color
	write_short( fadetype );	// Fade type
	write_byte ( red );		// Red
	write_byte ( green );		// Green
	write_byte ( blue );		// Blue
	write_byte ( alpha );	// Alpha
	message_end();
}

stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

public BlokujKomende()
	return PLUGIN_HANDLED;
