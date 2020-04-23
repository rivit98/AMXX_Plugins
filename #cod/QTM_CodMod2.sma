#include <amxmodx>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <nvault>
#include <codmod>

#define STANDARDOWA_SZYBKOSC 250.0
#define ZADANIE_POKAZ_INFORMACJE 672

#define m_pPlayer 41
#define m_flTimeWeaponIdle 48
#define m_fInReload 54
#define m_flNextAttack 83

/*-----------------KONFIGURACJA-----------------*/

#define EXP_PODNIESIENIE_UPUSZCZENIE      // jesli chcesz wylaczyc dawanie expa za podniesienie/upuszczenie paki to przed ta linijka daj //
#define MIN_PLAYERS_EXP_PAKA 4            // minimalna ilosc graczy zeby dawalo expa za podlozenie, rozbrojenie paki, uratowanie hostow, wygranie rundy
#define WYTRZYMALOSC_PERKU                // jesli chcesz wylaczyc wytrzymalosc perku to przed ta linijka daj // (WAZNE!! jezeli wylaczysz wytrzymalosc perku to zajrzyj takze do aukcje_cod.sma i bonusowe_paczki.sma !!)
#define VAULT_EXPIREDAYS 28               // po ilu dniach nieobecnosci na serwerze ma usuwac dane gracza (lvl, staty)
#define MAX_PLAYERS 32                    // max ilosc graczy (chcesz mniej zuzycia pamieci? ustaw wartosc: ilosc slotow+1
#define FLAGA_PREMIUM ADMIN_LEVEL_A       // flaga na ktora ma byc premium (zmieniasz tu to zmienia sie we wszystkich klasach (dolaczonych do tego cod))
#define FLAGA_SUPERPREMIUM ADMIN_LEVEL_B  // jak wyzej tylko dla super premium
#define MAX_WIELKOSC_NAZWY 32             // max dlugosc nazwy klasy, perku, frakcji
#define MAX_WIELKOSC_OPISU 200            // max wielkosc opisu klasy lub perku
//#define ZAPIS_NA_STEAM                    // jezeli chcesz zapis na nick to daj przed ta linijka //

#if defined WYTRZYMALOSC_PERKU
      #define MAX_WYTRZYMALOSC_PERKU 5    // max wytrzymalosc perku
      #define USZKODZENIA_ZA_SMIERC 1     // ile wytrzymalosci perku ma zabierac po smierci
#endif

//LIMITY STATOW
#define LIMIT_ZDROWIA 60 
#define LIMIT_INTELIGENCJI 70 
#define LIMIT_KONDYCJI 90 
#define LIMIT_WYTRZYMALOSCI 80 
#define LIMIT_OBRAZEN 100 
#define LIMIT_EXPA 200 
#define LIMIT_KEVLARU 100 
#define LIMIT_EKONOMII 50 
#define LIMIT_RELOADU 50 
#define LIMIT_KAMUFLAZU 60 
#define LIMIT_UNIKU 20 
#define LIMIT_KRYTYKU 25

new const co_ile[] = {1, 5, 20, 50, 100} // szybkie rozdawanie statystyk (ile pkt dodawac)
new const prefix[] = "^4[CoD]^1";
new const szPrefixPremium[] = "[Premium]";
new const szPrefixSPremium[] = "[Super Premium]";
new const szStatus[4][16] = { "", "Premium", "Super Premium", "Super Premium"}

/*--------------KONIEC KONFIGURACJI--------------*/

new szybkosc_rozdania[MAX_PLAYERS+1];

new vault, SyncHudObj;

#if defined WYTRZYMALOSC_PERKU
new wytrzymalosc_perku[MAX_PLAYERS+1];
#endif

new
cvar_doswiadczenie_za_zabojstwo, 
cvar_doswiadczenie_za_obrazenia, 
cvar_limit_poziomu, 
cvar_exp_za_hs, 
cvar_proporcja_poziomu, 
cvar_doswiadczenie_za_wygrana, 
cvar_dodatkowy_exp[3], 
cvar_forum;

#if defined EXP_PODNIESIENIE_UPUSZCZENIE
new cvar_podniesienie, 
cvar_upuszczenie;
#endif

new perk_zmieniony, klasa_zmieniona;

new
Array:nazwy_perkow, 
Array:opisy_perkow, 
Array:max_wartosci_perkow, 
Array:min_wartosci_perkow, 
Array:pluginy_perkow

new
nazwa_gracza[MAX_PLAYERS+1][33], 
klasa_gracza[MAX_PLAYERS+1], 
nowa_klasa_gracza[MAX_PLAYERS+1], 
poziom_gracza[MAX_PLAYERS+1], 
doswiadczenie_gracza[MAX_PLAYERS+1], 
perk_gracza[MAX_PLAYERS+1], 
wartosc_perku_gracza[MAX_PLAYERS+1], 
klan_gracza[MAX_PLAYERS+1][33]

new Array:gRender[MAX_PLAYERS+1],
Array:gRenderPlugin[MAX_PLAYERS+1]

new Float:szybkosc_gracza[MAX_PLAYERS+1]

enum _:typ_statystyk
{
      PUNKTY, 
      INTELIGENCJA, 
      ZDROWIE, 
      WYTRZYMALOSC, 
      KONDYCJA, 
      OBRAZENIA, 
      EXP, 
      KEVLAR, 
      EKONOMIA, 
      RELOAD, 
      KAMUFLAZ, 
      UNIK, 
      KRYTYK
}

new g_statystyki[MAX_PLAYERS+1][typ_statystyk];

new bonusowe_bronie_gracza[MAX_PLAYERS+1], 
bonusowe_zdrowie_gracza[MAX_PLAYERS+1], 
bonusowa_inteligencja_gracza[MAX_PLAYERS+1], 
bonusowa_wytrzymalosc_gracza[MAX_PLAYERS+1], 
bonusowa_kondycja_gracza[MAX_PLAYERS+1];

new
Array:bronie_klasy, 
Array:zdrowie_klas, 
Array:kondycja_klas, 
Array:inteligencja_klas, 
Array:wytrzymalosc_klas, 
Array:opisy_klas, 
Array:nazwy_klas, 
Array:pluginy_klas, 
Array:frakcja_klas, 
Array:typ_frakcji

new bronie_dozwolone = ((1<<CSW_KNIFE) | (1<<CSW_C4));

new g_status[MAX_PLAYERS+1];
new killstreak_gracza[MAX_PLAYERS+1];
new bool:szybki_reload[MAX_PLAYERS+1];

new forum[64], limit_poziomu, za_obrazenia;

new bool:freezetime;
new msgScreenFade;

new const Float:g_fDelay[CSW_P90+1] = { 0.00, 2.70, 0.00, 2.00, 0.00, 0.55, 0.00, 3.15, 3.30, 0.00, 4.50, 2.70, 3.50, 3.35, 2.45, 3.30, 2.70, 2.20, 2.50, 2.63, 4.70, 0.55, 3.05, 2.12, 3.50, 0.00, 2.20, 3.00, 2.45, 0.00, 3.40 }
new const maxAmmo[CSW_P90+1] = {0, 52, 0, 90, 1, 31, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 31, 90, 120, 90, 1, 35, 90, 90, 0, 100};
new const Nazwy_broni[][] = {
	"", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", 
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", 
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", 
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", 
	"weapon_ak47", "weapon_knife", "weapon_p90" }
	
new const msg[][] = { "podlozenie paki", "rozbrojenie paki", "uratowanie hostow" }

new g_buffer[1024];
new sizeArray_typ_frakcji;
new iloscKlas;
new iloscPerkow;

public plugin_init() 
{
      register_plugin("CoD MoD", "ID - 1", "RiviT");

      cvar_doswiadczenie_za_zabojstwo = register_cvar("cod_killxp", "140"); //exp za kill
      cvar_doswiadczenie_za_obrazenia = register_cvar("cod_damagexp", "4"); //exp za 20 dmg
      cvar_limit_poziomu = register_cvar("cod_maxlevel", "401");            //max lvl
      cvar_doswiadczenie_za_wygrana = register_cvar("cod_winxp", "20");     //exp za wygrana runde
      cvar_exp_za_hs = register_cvar("cod_hsxp", "75");                     //exp za HS
      cvar_dodatkowy_exp[0] = register_cvar("cod_plantexp", "60");          //exp za podlozenie paki
      cvar_dodatkowy_exp[1] = register_cvar("cod_defuseexp", "60");         //exp za rozbrojenie
      cvar_dodatkowy_exp[2] = register_cvar("cod_rescueexp", "30");         //exp za uratowanie hostow
      cvar_proporcja_poziomu = register_cvar("cod_levelratio", "45");       //proprcja poziomu
      cvar_forum = register_cvar("cod_forum", "Forum");                     //nazwa forum wyswietlana w hud

      #if defined EXP_PODNIESIENIE_UPUSZCZENIE
      cvar_podniesienie = register_cvar("cod_bombget", "25");               //ile exp'a za podniesienie paki (mniej niz za upuszczenie)
      cvar_upuszczenie = register_cvar("cod_bombdrop", "30");               //ile exp'a za wyrzucenie paki (wiecej niz za podniesienie)
      #endif

      register_clcmd("say /klasa", "WybierzKlase");
      register_clcmd("say /class", "WybierzKlase");
      register_clcmd("say /klasy", "OpisKlasy_Frakcje");
      register_clcmd("say /classinfo", "OpisKlasy_Frakcje");
      register_clcmd("say /perk", "KomendaOpisPerku");
      register_clcmd("say /p", "KomendaOpisPerku");
      register_clcmd("say /drop", "SprzedajPerk");
	register_clcmd("say /d", "SprzedajPerk");
      register_clcmd("say /wyrzuc", "SprzedajPerk");
      register_clcmd("say /sprzedaj", "SprzedajPerk");
      register_clcmd("say /sell", "SprzedajPerk");
	register_clcmd("say /premium", "ShowMotdP");
      register_clcmd("say /spremium", "ShowMotdSP");
      register_clcmd("say /statystyki", "PrzydzielPunkty");
      register_clcmd("say /staty", "PrzydzielPunkty");
      register_clcmd("say /pomoc", "Pomoc");
      register_clcmd("say /hud", "Hud");
      register_clcmd("say /reset", "KomendaResetujPunkty");
      register_clcmd("say /vips", "ShowVips")
	register_clcmd("say /vipy", "ShowVips")

      register_clcmd("useperk", "UzyjPerku");
      register_clcmd("radio3", "UzyjPerku");
      register_clcmd("fullupdate", "BlokujKomende");

      RegisterHam(Ham_TakeDamage, "player", "Obrazenia");
      RegisterHam(Ham_TakeDamage, "player", "ObrazeniaPost", 1);
      RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
      RegisterHam(Ham_Touch, "weapon_shield", "HamSupercede");
      RegisterHam(Ham_Touch, "weaponbox", "DotykBroni");
      RegisterHam(Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Pre", 0)
      RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "UstawSzybkosc", 1)

	new suma_bitowa = (1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4)|(1<<CSW_M3)|(1<<CSW_XM1014)|(1<<2)
	new i;
      for(i = CSW_P228; i <= CSW_P90; i++)
      {
            if(suma_bitowa & (1<<i)) continue;
            
            RegisterHam(Ham_Weapon_Reload, Nazwy_broni[i], "PrzeladowanieBroniPost", 1)
	}
	
      register_forward(FM_EmitSound, "EmitSound");
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_ClientKill, "ClientKill")

      register_logevent("ExpPakaHosty", 3, "1=triggered");
      register_logevent("RoundEnd", 2, "1=Round_End");

      #if defined EXP_PODNIESIENIE_UPUSZCZENIE
      register_logevent("bomb_drop", 3, "2=Dropped_The_Bomb")
      register_logevent("bomb_get", 3, "2=Got_The_Bomb")
      #endif
      
      register_logevent("PoczatekRundy", 2, "1=Round_Start"); 

      register_event("SendAudio", "WygranaTerro" , "a", "2&%!MRAD_terwin");
      register_event("SendAudio", "WygranaCT", "a", "2&%!MRAD_ctwin");
      register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
      register_event("DeathMsg", "DeathMsg", "a")
      
      register_message(get_user_msgid("SayText"), "handleSayText");
      register_message(get_user_msgid("ScoreAttrib"), "VipStatus");
      register_message(get_user_msgid("Health"), "Health")
   
      vault = nvault_open("CoD_by_Rivit");
	if(vault == INVALID_HANDLE)
		log_error(AMX_ERR_NATIVE, "Otwieranie pliku .vault nie powiodlo sie!")
 
      SyncHudObj = CreateHudSyncObj();
 
      perk_zmieniony = CreateMultiForward("cod_perk_changed", ET_CONTINUE, FP_CELL, FP_CELL);
      klasa_zmieniona = CreateMultiForward("cod_class_changed", ET_CONTINUE, FP_CELL, FP_CELL);

      msgScreenFade = get_user_msgid("ScreenFade")
      
      bronie_klasy = ArrayCreate(1)
      zdrowie_klas = ArrayCreate(1)
      kondycja_klas = ArrayCreate(1)
      inteligencja_klas = ArrayCreate(1)
      wytrzymalosc_klas = ArrayCreate(1)
      pluginy_klas = ArrayCreate(1)
      opisy_klas = ArrayCreate(MAX_WIELKOSC_OPISU+1)
      nazwy_klas = ArrayCreate(MAX_WIELKOSC_NAZWY+1)
      typ_frakcji = ArrayCreate(MAX_WIELKOSC_NAZWY+1, 2)
      frakcja_klas = ArrayCreate(MAX_WIELKOSC_NAZWY+1)
      nazwy_perkow = ArrayCreate(MAX_WIELKOSC_NAZWY+1)
      opisy_perkow = ArrayCreate(MAX_WIELKOSC_OPISU+1)
      min_wartosci_perkow = ArrayCreate(1)
      max_wartosci_perkow = ArrayCreate(1)
      pluginy_perkow = ArrayCreate(1)
      
      for(i = 1; i <= MAX_PLAYERS; i++)
      {
		gRender[i] = ArrayCreate(1, 2)
		gRenderPlugin[i] = ArrayCreate(1, 2)
	}
	
      ArrayPushCell(pluginy_klas, 0)
	ArrayPushCell(bronie_klasy, 0)
	ArrayPushCell(zdrowie_klas, 0)
	ArrayPushCell(kondycja_klas, 0)
	ArrayPushCell(inteligencja_klas, 0)
	ArrayPushCell(wytrzymalosc_klas, 0)
	ArrayPushString(opisy_klas, "")
	ArrayPushString(nazwy_klas, "Brak")
	ArrayPushString(frakcja_klas, "")
	ArrayPushString(opisy_perkow, "Zabij kogos, aby dostac perk")
	ArrayPushString(nazwy_perkow, "Brak")
	ArrayPushCell(pluginy_perkow, 0)
	ArrayPushCell(min_wartosci_perkow, 0)
	ArrayPushCell(max_wartosci_perkow, 0)

	set_task(0.5, "UsunDuplikaty")
}

public ShowVips(id)
{
	new buffer[1536], i;
	
	add(buffer, 1535, "<html><body bgcolor=Black><font color=^"#E0A518^">");

	for(i = 1; i <= MAX_PLAYERS; i++)
	{
		if(is_user_connected(i))
			format(buffer, 1535, "%s%s - Gracz %s<br>", buffer, nazwa_gracza[i], szStatus[g_status[i]])
	}

	add(buffer, 1535, "</font></body></html>");
	
	show_motd(id, buffer, "Statusy graczy");
}

public UsunDuplikaty()
{
      server_cmd("exec addons/amxmodx/configs/codmod.cfg");
	server_exec();

      new temp[MAX_WIELKOSC_NAZWY+1], j, i;
      for(i = 0; i < ArraySize(typ_frakcji); i++)
      {
            ArrayGetString(typ_frakcji, i, g_buffer, MAX_WIELKOSC_NAZWY)
            for(j = i+1; j < ArraySize(typ_frakcji); j++)
            {
                  ArrayGetString(typ_frakcji, j, temp, MAX_WIELKOSC_NAZWY)
                  if(equali(g_buffer, temp))
                  {
                        ArrayDeleteItem(typ_frakcji, j)
                        j--
                  }
            }
      }
      
      sizeArray_typ_frakcji = ArraySize(typ_frakcji)
      iloscKlas = ArraySize(zdrowie_klas) // klas jest w rzeczywistosci jedna mniej bo "Brak"
      iloscPerkow = ArraySize(nazwy_perkow) // perkow jest w rzeczywistosci jeden mniej bo "Brak"
	get_pcvar_string(cvar_forum, forum, charsmax(forum))
      limit_poziomu = get_pcvar_num(cvar_limit_poziomu)
	za_obrazenia = get_pcvar_num(cvar_doswiadczenie_za_obrazenia)

	nvault_prune(vault, 0, get_systime() - (86400 * VAULT_EXPIREDAYS));
}

public plugin_precache()
{
      RegisterHam(Ham_Spawn, "func_buyzone", "HamSupercede")
      RegisterHam(Ham_Spawn, "armoury_entity", "HamSupercede")
      
	precache_sound("QTM_CodMod/select.wav");
	precache_sound("QTM_CodMod/levelup.wav");
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id)) return;

	static Float:velocity[3];
	pev(id, pev_velocity, velocity);
	if(szybkosc_gracza[id] > vector_length(velocity) * 1.8)
		set_pev(id, pev_flTimeStepSound, 300);
}

public Health(msgid, msgdest, id) 
{
	if(!is_user_alive(id)) return;
	
	static hp;
	hp = get_msg_arg_int(1);

	if(hp > 255 && !(hp % 256))
		set_msg_arg_int(1, ARG_BYTE, ++hp);
}

public Hud(id)
{
      if(task_exists(id+ZADANIE_POKAZ_INFORMACJE))
            remove_task(id+ZADANIE_POKAZ_INFORMACJE)
      else
            set_task(0.7, "PokazInformacje", id+ZADANIE_POKAZ_INFORMACJE, _, _, "b");
}

public Odrodzenie(id)
{
      if(!is_user_alive(id)) return;

	if(nowa_klasa_gracza[id])
		UstawNowaKlase(id);
	else
	{
		if(g_statystyki[id][PUNKTY] > 0)
			PrzydzielPunkty(id, 0);
	}
	
	if(!klasa_gracza[id])
	{
		WybierzKlase(id);
		return;
	}
	
	DajBronie(id)
	set_task(0.3, "ZastosujAtrybuty", id)
	
	if(g_status[id] == STATUS_PREMIUM)
	{
            if(get_user_team(id) == 2)
                  cs_set_user_defuse(id, 1)

            cs_set_user_money(id, min(cs_get_user_money(id)+300, 16000), 1);
      }
      else if(g_status[id] > STATUS_PREMIUM)
      {
            if(get_user_team(id) == 2)
                  cs_set_user_defuse(id, 1)

            cs_set_user_money(id, min(cs_get_user_money(id)+500, 16000), 1);
      }
}

UstawNowaKlase(id)
{
      ZapiszDane(id);

	static ret, forward_handle;
	
	forward_handle = CreateOneForward(ArrayGetCell(pluginy_klas, klasa_gracza[id]), "cod_class_disabled", FP_CELL);
	ExecuteForward(forward_handle, ret, id);
	DestroyForward(forward_handle);
	
	forward_handle = CreateOneForward(ArrayGetCell(pluginy_klas, nowa_klasa_gracza[id]), "cod_class_enabled", FP_CELL);
	ExecuteForward(forward_handle, ret, id);
	DestroyForward(forward_handle);
	
	if(ret == COD_STOP)
	{
		nowa_klasa_gracza[id] = 0;
		return;
	}
	
	ExecuteForward(klasa_zmieniona, ret, id, klasa_gracza[id]);

	if(ret == COD_STOP)	
	{
		nowa_klasa_gracza[id] = 0;
		return;
	}

	klasa_gracza[id] = nowa_klasa_gracza[id];
	nowa_klasa_gracza[id] = 0;

	#if defined WYTRZYMALOSC_PERKU
	static cache_durability;
      cache_durability = wytrzymalosc_perku[id]
	#endif

	UstawPerk(id, perk_gracza[id], wartosc_perku_gracza[id], 0);
	
	#if defined WYTRZYMALOSC_PERKU
	wytrzymalosc_perku[id] = cache_durability
	#endif
  
      ArrayGetString(nazwy_klas, klasa_gracza[id], g_buffer, MAX_WIELKOSC_NAZWY)
	WczytajDane(id);
}

DajBronie(id)
{
	static suma_bitowa, i;
	suma_bitowa = ArrayGetCell(bronie_klasy, klasa_gracza[id]) | bonusowe_bronie_gracza[id]
	
      for(i = CSW_P228; i <= CSW_P90; ++i)
      {
            if((1<<i) & suma_bitowa)
            {
                  fm_give_item(id, Nazwy_broni[i]);
                  cs_set_user_bpammo(id, i, maxAmmo[i]);
            }
            else
            {
                  if((1<<i) & ~bronie_dozwolone && user_has_weapon(id, i))
                        ham_strip_weapon(id, i)
            }
      }
}

ham_strip_weapon(id, wId)
{
	static wEnt;
	wEnt = -1
	
	while ((wEnt = engfunc(EngFunc_FindEntityByString, wEnt, "classname", Nazwy_broni[wId])) && pev(wEnt, pev_owner) != id) {}

      if(!wEnt) return

      if(get_user_weapon(id) == wId) ExecuteHam(Ham_Weapon_RetireWeapon, wEnt);

      if(ExecuteHam(Ham_RemovePlayerItem, id, wEnt))
      {
		ExecuteHam(Ham_Item_Kill, wEnt);

		set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId));
      }
}

public ZastosujAtrybuty(id)
{
	szybkosc_gracza[id] = STANDARDOWA_SZYBKOSC+PobierzKondycje(id, 1, 1, 1)*1.3;

	set_pev(id, pev_health, 100.0+PobierzZdrowie(id, 1, 1, 1));
	
	if(g_statystyki[id][KEVLAR])
            cs_set_user_armor(id, min(get_user_armor(id) + g_statystyki[id][KEVLAR], 150), CS_ARMOR_KEVLAR)

	ArraySetCell(gRender[id], 0, 255 - (3 * g_statystyki[id][KAMUFLAZ]))
	ZastosujRender(id)
}

#if defined EXP_PODNIESIENIE_UPUSZCZENIE
public bomb_drop()
{
	static id, za_upuszczenie;

	id = get_loguser_index()
	za_upuszczenie = get_pcvar_num(cvar_upuszczenie);
	if(is_user_alive(id) && doswiadczenie_gracza[id] >= za_upuszczenie)
	{
		doswiadczenie_gracza[id] -= za_upuszczenie;
		client_print_color(id, print_team_red, "%s Straciles %i expa za upuszczenie paki", prefix, za_upuszczenie)
		set_dhudmessage(122, 255, 228, -1.0, 0.63, 0, 0.0, 1.5, 0.0, 0.0)
		show_dhudmessage(id, "-%i", za_upuszczenie);
		SprawdzPoziom(id);
	}
}

public bomb_get()
{
	static id, za_podniesienie;
	id = get_loguser_index()
	
	if(is_user_alive(id))
	{
		za_podniesienie = get_pcvar_num(cvar_podniesienie)
		doswiadczenie_gracza[id] += za_podniesienie;
		client_print_color(id, print_team_red, "%s Dostales %i expa za podniesienie paki", prefix, za_podniesienie)
		set_dhudmessage(122, 255, 228, -1.0, 0.63, 0, 0.0, 1.5, 0.0, 0.0)
		show_dhudmessage(id, "+%i", za_podniesienie);
		SprawdzPoziom(id);
	}
}
#endif

public ExpPakaHosty()
{
      if(get_playersnum() < MIN_PLAYERS_EXP_PAKA) return;
      
	static loguser[80], name[33], id, akcja[20];
	read_logargv(0, loguser, 79);
	parse_loguser(loguser, name, 32);
	
	id = get_user_index(name);
	
	if(!is_user_connected(id)) return;
	
      read_logargv(2, akcja, 19);

	if(equal(akcja, "Planted_The_Bomb"))
		PrzydzielExp(id, 0);
	
	else if(equal(akcja, "Defused_The_Bomb"))
		PrzydzielExp(id, 1);
	
	else if(equal(akcja, "Rescued_A_Hostage"))
		PrzydzielExp(id, 2);
}

PrzydzielExp(id, typ)
{
	static exp;
	exp = get_pcvar_num(cvar_dodatkowy_exp[typ]);

	if(g_status[id] == STATUS_PREMIUM)
            exp += 300
      else if(g_status[id] > STATUS_PREMIUM)
            exp += 400

      doswiadczenie_gracza[id] += exp;

      client_print_color(id, print_team_red, "%s Dostales %d expa za %s", prefix, exp, msg[typ])
      set_dhudmessage(122, 255, 228, -1.0, 0.68, 0, 0.0, 1.5, 0.0, 0.0)
      show_dhudmessage(id, "+%i", exp);

      SprawdzPoziom(id);
}

public WygranaTerro()
	WygranaRunda(1);

public WygranaCT()
	WygranaRunda(2);

WygranaRunda(team)
{
	if(get_playersnum() < MIN_PLAYERS_EXP_PAKA) return;

	static doswiadczenie_za_wygrana, id;
      doswiadczenie_za_wygrana = get_pcvar_num(cvar_doswiadczenie_za_wygrana);

	for(id = 1; id <= MAX_PLAYERS; id++)
	{
            if(get_user_team(id) != team) continue;
            if(!klasa_gracza[id]) continue;
            
            doswiadczenie_gracza[id] += doswiadczenie_za_wygrana;
            client_print_color(id, print_team_red, "%s Dostales %i expa za wygrana runde!", prefix, doswiadczenie_za_wygrana)
		SprawdzPoziom(id);
	}
}

public RoundEnd()
{
	static i;
	for(i = 1; i <= MAX_PLAYERS; i++)
	{
		if(is_user_alive(i))
		{
                  if(g_status[i] == STATUS_PREMIUM)
                        cs_set_user_money(i, min(cs_get_user_money(i)+100, 16000));
                  else if(g_status[i] > STATUS_PREMIUM)
                        cs_set_user_money(i, min(cs_get_user_money(i)+200, 16000));
		}
	}
}

public PrzeladowanieBroniPost(iEnt)
{
	static id, Float:fDelay;
	id = get_pdata_cbase(iEnt, m_pPlayer, 4)
	
	if(szybki_reload[id]) return;

	if(g_statystyki[id][RELOAD] && get_pdata_int(iEnt, m_fInReload, 4))
	{
		fDelay = g_fDelay[cs_get_weapon_id(iEnt)] * (1.0 - (float(g_statystyki[id][RELOAD]) / 100.0))
		set_pdata_float(id, m_flNextAttack, fDelay, 5)
		set_pdata_float(iEnt, m_flTimeWeaponIdle, fDelay + 0.5, 4)
	}
}

public Ham_AddPlayerItem_Pre(id, ent)
{
      if(~(ArrayGetCell(bronie_klasy, klasa_gracza[id]) | bonusowe_bronie_gracza[id] | bronie_dozwolone) & 1<<cs_get_weapon_id(ent))
      {
            ExecuteHam(Ham_Item_Kill, ent)
            return HAM_SUPERCEDE
      }

	return HAM_IGNORED
}

public PoczatekRundy()	
	freezetime = false;

public NowaRunda()
	freezetime = true;

public UstawSzybkosc(id)
{
	if(is_user_alive(id) && !freezetime)
            fm_set_user_maxspeed(id, klasa_gracza[id] ? szybkosc_gracza[id] : 20.0)
}

public Obrazenia(vid, idinflictor, kid, Float:damage)
{
	if(!is_user_connected(kid) || get_user_team(vid) == get_user_team(kid))
		return HAM_IGNORED;
		
	if(g_statystyki[vid][UNIK])
	{
            if(random(100) < floatround(g_statystyki[vid][UNIK] * 0.5, floatround_floor))
            {
                  set_dhudmessage(122, 255, 228, -1.0, 0.55, 0, 0.0, 1.5, 0.0, 0.0)
                  show_dhudmessage(vid, "UNIK!");
                  show_dhudmessage(kid, "%s - UNIK!", nazwa_gracza[vid]);
                  
                  Display_Fade(vid, 0, 0, 250)
                  
                  return HAM_SUPERCEDE;
            }
      }
	
      if(g_statystyki[kid][KRYTYK])
	{
            if(random(100) < floatround(g_statystyki[kid][KRYTYK] * 0.4, floatround_floor))
            {
                  set_dhudmessage(122, 255, 228, -1.0, 0.55, 0, 0.0, 1.5, 0.0, 0.0)
                  show_dhudmessage(kid, "CIOS KRYTYCZNY!");
                  show_dhudmessage(vid, "%s - CIOS KRYTYCZNY!", nazwa_gracza[kid]);
                  Display_Fade(vid, 255, 0, 0)
                  damage *= 3
            }
      }

      damage += (damage * float(g_statystyki[kid][OBRAZENIA]) * 0.005)
      
	SetHamParamFloat(4, damage * (1.0 - (PobierzWytrzymalosc(vid, 1, 1, 1) * 0.0025)));
	
	return HAM_HANDLED;
}

public ObrazeniaPost(id, idinflictor, attacker, Float:damage)
{
	if(!is_user_connected(attacker) || get_user_team(id) == get_user_team(attacker) || !attacker) return;

      while(damage >= 20)
      {
		damage -= 20;
            doswiadczenie_gracza[attacker] += za_obrazenia;
      }
      
      SprawdzPoziom(attacker);
}

public DeathMsg()
{
	static kid, vid, nowe_doswiadczenie, hs, nowa_kasa;

	kid = read_data(1);
      if(!is_user_connected(kid)) return;

	vid = read_data(2);
	killstreak_gracza[vid] = 0
	if(kid && kid != vid && get_user_team(kid) != get_user_team(vid))
	{
		killstreak_gracza[kid]++

		nowe_doswiadczenie = get_pcvar_num(cvar_doswiadczenie_za_zabojstwo) + (2 * g_statystyki[kid][EXP]) + killstreak_gracza[kid] * 10;
		
		hs = read_data(3)
		if(hs)
			nowe_doswiadczenie += get_pcvar_num(cvar_exp_za_hs);

		if(!perk_gracza[kid])
			UstawPerk(kid, -1, -1, 1);

            if(g_status[kid] == STATUS_PREMIUM)
                  nowe_doswiadczenie += hs ? 40 : 25
            else if(g_status[kid] > STATUS_PREMIUM)
                  nowe_doswiadczenie += hs ? 50 : 35

		set_dhudmessage(122, 255, 228, -1.0, 0.66, 0, 0.0, 1.5, 0.0, 0.0)
		show_dhudmessage(kid, "+%i", nowe_doswiadczenie);
		
		doswiadczenie_gracza[kid] += nowe_doswiadczenie;
		
            SprawdzPoziom(kid);
		
		if(g_statystyki[kid][EKONOMIA] || g_status[kid])
		{
			nowa_kasa = g_statystyki[kid][EKONOMIA] * 14;
                  if(g_status[kid] == STATUS_PREMIUM)
                        nowa_kasa += hs ? 450 : 250
                  else if(g_status[kid] > STATUS_PREMIUM)
                        nowa_kasa += hs ? 550 : 350

                  cs_set_user_money(kid, min(cs_get_user_money(kid) + nowa_kasa, 16000))
                  set_dhudmessage(122, 255, 228, 0.8, 0.63, 0, 0.0, 1.5, 0.0, 0.0)
                  show_dhudmessage(kid, "+%i$", nowa_kasa);
		}
	}
	
	#if defined WYTRZYMALOSC_PERKU
	if(perk_gracza[vid] && ((wytrzymalosc_perku[vid] -= USZKODZENIA_ZA_SMIERC) <= 0))
	{
		UstawPerk(vid, 0, 0, 0);
		client_print_color(vid, print_team_red, "%s Twoj perk ulegl zniszczeniu!", prefix)
	}
	#endif
}

public client_authorized(id)
{
      poziom_gracza[id] = 1;
	doswiadczenie_gracza[id] = 0;
	szybki_reload[id] = false
	szybkosc_gracza[id] = 0.0;
	killstreak_gracza[id] = 0
	g_status[id] = 0;
	
	get_user_name(id, nazwa_gracza[id], 32);
      set_task(0.7, "PokazInformacje", id+ZADANIE_POKAZ_INFORMACJE, _, _, "b")

	ArrayClear(gRender[id])
	ArrayClear(gRenderPlugin[id])
	ArrayPushCell(gRender[id], 255) //pierwszy to jest ze statystyki
	ArrayPushCell(gRenderPlugin[id], 1) //index pluginu, nie potrzebne, bo usuwanie jest od 1 indexu tablicy, a ten jest zerowy
      
      static a;
	for(a = 0; a < typ_statystyk; a++)
            g_statystyki[id][a] = 0;

      a = get_user_flags(id)
      if(a & FLAGA_PREMIUM)
            g_status[id] |= STATUS_PREMIUM
      if(a & FLAGA_SUPERPREMIUM)
      {
            g_status[id] |= STATUS_SPREMIUM
            set_hudmessage(24, 190, 220, 0.25, 0.2, 0, 6.0, 6.0);
            show_hudmessage(0, "[%s] %s wbija na serwer !", szStatus[g_status[id]], nazwa_gracza[id]);
      }
      
	client_cmd(id, "cl_forwardspeed 1000");
	client_cmd(id, "cl_backspeed 1000");
	client_cmd(id, "cl_sidespeed 1000");
	client_cmd(id, "cl_upspeed 1000");
	client_cmd(id, "cl_downspeed 1000");
}

public client_disconnect(id)
{
	ZapiszDane(id);

	remove_task(id+ZADANIE_POKAZ_INFORMACJE);
	remove_task(id) //zastosuj atrybuty
	
      nowa_klasa_gracza[id] = 0;
	UstawNowaKlase(id);
	UstawPerk(id, 0, 0, 0);
	
	//usuwanie bonusow musi byc w disconnect ze wzgledu na klany!!
      bonusowe_zdrowie_gracza[id] = 0;
	bonusowa_wytrzymalosc_gracza[id] = 0;
	bonusowa_inteligencja_gracza[id] = 0;
	bonusowa_kondycja_gracza[id] = 0;
}

public KomendaOpisPerku(id)
{
	static losowa_wartosc[MAX_WIELKOSC_NAZWY];
	num_to_str(wartosc_perku_gracza[id], losowa_wartosc, 14);

	ArrayGetString(opisy_perkow, perk_gracza[id], g_buffer, MAX_WIELKOSC_OPISU)
	replace_all(g_buffer, charsmax(g_buffer), "LW", losowa_wartosc);
	ArrayGetString(nazwy_perkow, perk_gracza[id], losowa_wartosc, MAX_WIELKOSC_NAZWY)

	client_print_color(id, print_team_red, "%s PERK: %s", prefix, losowa_wartosc);
	client_print_color(id, print_team_red, "%s OPIS: %s", prefix, g_buffer);
	
	return PLUGIN_HANDLED;
}

public OpisKlasy_Frakcje(id)
{
	static menu, i;
	menu = menu_create("\r===| \wWybierz frakcje: \r|===", "OpisKlasyFrakcje_Handle");

	for(i = 0; i < sizeArray_typ_frakcji; i++)
	{
            ArrayGetString(typ_frakcji, i, g_buffer, MAX_WIELKOSC_NAZWY)
		if(!equal(g_buffer, ""))
			menu_additem(menu, g_buffer)
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	
	menu_display(id, menu);
}

public OpisKlasyFrakcje_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
		
	static idKlasy[3], iNameFrakcji[MAX_WIELKOSC_NAZWY+1], i, menu2;
	menu_item_getinfo(menu, item, i, idKlasy, 1, iNameFrakcji, MAX_WIELKOSC_NAZWY, i)
	
	menu2 = menu_create("\r===| \wWybierz klase: \r|===", "OpisKlasy_Handle");

	for(i = 1; i < iloscKlas; i++)
	{
            ArrayGetString(frakcja_klas, i, g_buffer, MAX_WIELKOSC_NAZWY)
		if(equali(iNameFrakcji, g_buffer))
		{
			num_to_str(i, idKlasy, charsmax(idKlasy));
			ArrayGetString(nazwy_klas, i, g_buffer, MAX_WIELKOSC_NAZWY)
			menu_additem(menu2, g_buffer, idKlasy);
		}
	}
	
	menu_setprop(menu2, MPROP_EXITNAME, "Wstecz");
	menu_setprop(menu2, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu2, MPROP_NEXTNAME, "Nastepne");
	
	menu_display(id, menu2);
	
	menu_destroy(menu);
}

public OpisKlasy_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		OpisKlasy_Frakcje(id)
            menu_destroy(menu);
		return;
      }
	
      static ZmiennaNaOpisKlasy[MAX_WIELKOSC_OPISU+1], i, nazwa_klasy[MAX_WIELKOSC_NAZWY+1], bronie[320], n;
	menu_item_getinfo(menu, item, i, ZmiennaNaOpisKlasy, 2, nazwa_klasy, MAX_WIELKOSC_NAZWY, i)
	
	bronie = "";
	menu_display(id, menu, item/7)
	
	item = str_to_num(ZmiennaNaOpisKlasy);

	for(i = 1, n = 1; i <= CSW_P90; i++)
	{
		if((1<<i) & ArrayGetCell(bronie_klasy, item))
		{
			if(n > 1)	
				add(bronie, charsmax(bronie), ", ");
			add(bronie, charsmax(bronie), Nazwy_broni[i]);
			n++;
		}
	}
	
	replace_all(bronie, charsmax(bronie), "weapon_", "");
	
	ArrayGetString(opisy_klas, item, ZmiennaNaOpisKlasy, charsmax(ZmiennaNaOpisKlasy))

	formatex(g_buffer, charsmax(g_buffer), "<body bgcolor=#000><font color=#33CCFF><font size=^"5^"><font face=^"Verdana^"><center>Opis: %s</center><br><br>Bronie: %s<br>Opis: %s", nazwa_klasy, bronie, ZmiennaNaOpisKlasy)
	
	show_motd(id, g_buffer, "Opis klasy");
}

public WybierzKlase(id)
{
	static menu, i;
	menu = menu_create("\r===| \wWybierz frakcje: \r|===", "WybierzKlase_Frakcje");

      for(i = 0; i < sizeArray_typ_frakcji; i++)
	{
            ArrayGetString(typ_frakcji, i, g_buffer, MAX_WIELKOSC_NAZWY)
		if(!equal(g_buffer, ""))
			menu_additem(menu, g_buffer)
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public WybierzKlase_Frakcje(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	static iNameFrakcji[MAX_WIELKOSC_NAZWY+1], i, menu2, klasa[MAX_WIELKOSC_NAZWY+20];
	menu_item_getinfo(menu, item, i, klasa, 1, iNameFrakcji, MAX_WIELKOSC_NAZWY, i)
	
	menu2 = menu_create("\r===| \wWybierz klase: \r|===", "WybierzKlase_Handle");

      ZapiszDane(id);
	
	for(i = 1; i < iloscKlas; i++)
	{
            ArrayGetString(frakcja_klas, i, g_buffer, MAX_WIELKOSC_NAZWY)

		if(equali(iNameFrakcji, g_buffer))
		{
                  ArrayGetString(nazwy_klas, i, g_buffer, MAX_WIELKOSC_NAZWY)
			formatex(klasa, charsmax(klasa), "\w%s \r| \y%i \r|", g_buffer, WczytajPoziom(id));
			num_to_str(i, g_buffer, 3);
			menu_additem(menu2, klasa, g_buffer);
		}
	}

      ArrayGetString(nazwy_klas, klasa_gracza[id], g_buffer, MAX_WIELKOSC_NAZWY)
	WczytajDane(id);

	menu_setprop(menu2, MPROP_EXITNAME, "Wroc");
	menu_setprop(menu2, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu2, MPROP_NEXTNAME, "Nastepne");
	menu_display(id, menu2);

	menu_destroy(menu);
}

public WybierzKlase_Handle(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");

	if(item == MENU_EXIT)
	{
            WybierzKlase(id)
		menu_destroy(menu);
		return;
	}	  
	
	static data[3];
	menu_item_getinfo(menu, item, item, data, 2, _, _, item)
	
	item = str_to_num(data);
	
	if(item == klasa_gracza[id] && !nowa_klasa_gracza[id]) return;
	
	nowa_klasa_gracza[id] = item;
	
	if(klasa_gracza[id])
		client_print_color(id, print_team_red, "%s Klasa zostanie zmieniona w nastepnej rundzie", prefix)
	else
	{
		UstawNowaKlase(id);
		DajBronie(id);
		ZastosujAtrybuty(id);
		fm_set_user_maxspeed(id, szybkosc_gracza[id])
	}

	menu_destroy(menu);
}

public PrzydzielPunkty(id, strona)
{
      static temp[80], temp2[30], menu, mcb;

      formatex(temp, charsmax(temp), "\r===| \wStaty | \y(%i)\w: \r|===", g_statystyki[id][PUNKTY]);
	menu = menu_create(temp, "PrzydzielPunkty_Handler");
	mcb = menu_makecallback("PrzydzielPunkty_cb")

      formatex(temp2, charsmax(temp2), "Po ile dodawac?: \r%d", co_ile[szybkosc_rozdania[id]]);
      menu_additem(menu, temp2);

	formatex(temp, charsmax(temp), "Inteligencja: \r%i/%i \w(+%i) \y|Zwieksza moc perkow i klas", g_statystyki[id][INTELIGENCJA], LIMIT_INTELIGENCJI, PobierzInteligencje(id, 0, 1, 1));
	menu_additem(menu, temp, "", 0, mcb);
	formatex(temp, charsmax(temp), "Zdrowie: \r%i/%i \y|+%i HP", g_statystyki[id][ZDROWIE], LIMIT_ZDROWIA, PobierzZdrowie(id, 1, 1, 1));
	menu_additem(menu, temp, "", 0, mcb);
	g_buffer[666] = PobierzWytrzymalosc(id, 1, 1, 1)*25
	formatex(temp, charsmax(temp), "Wytrzymalosc: \r%i/%i \w(+%i) \y|Otrzymujesz o %d.%02d%% mniej dmg", g_statystyki[id][WYTRZYMALOSC], LIMIT_WYTRZYMALOSCI, PobierzWytrzymalosc(id, 0, 1, 1), g_buffer[666]/100, g_buffer[666]%100);
	menu_additem(menu, temp, "", 0, mcb);
	g_buffer[666] = PobierzKondycje(id, 1, 1, 1)*130
	formatex(temp, charsmax(temp), "Kondycja: \r%i/%i \w(+%i) \y|Zwieksza szybkosc o %d.%02d%%", g_statystyki[id][KONDYCJA], LIMIT_KONDYCJI, PobierzKondycje(id, 0, 1, 1), g_buffer[666]/100, g_buffer[666]%100);
	menu_additem(menu, temp, "", 0, mcb);
	g_buffer[666] = g_statystyki[id][OBRAZENIA]*50
	formatex(temp, charsmax(temp), "Obrazenia: \r%i/%i \y|%d.%02d%% wieksze dmg", g_statystyki[id][OBRAZENIA], LIMIT_OBRAZEN, g_buffer[666]/100, g_buffer[666]%100);
	menu_additem(menu, temp, "", 0, mcb);
	formatex(temp, charsmax(temp), "Exp: \r%i/%i \y|+%i exp za frag", g_statystyki[id][EXP], LIMIT_EXPA, g_statystyki[id][EXP]*2);
	menu_additem(menu, temp, "", 0, mcb);
	menu_additem(menu, temp2);
	formatex(temp, charsmax(temp), "Kevlar: \r%i/%i \y|+%i kamizelki", g_statystyki[id][KEVLAR], LIMIT_KEVLARU, g_statystyki[id][KEVLAR]);
	menu_additem(menu, temp, "", 0, mcb);
	formatex(temp, charsmax(temp), "Ekonomia: \r%i/%i \y|+%i$ za frag", g_statystyki[id][EKONOMIA], LIMIT_EKONOMII, g_statystyki[id][EKONOMIA]*14);
	menu_additem(menu, temp, "", 0, mcb);
	formatex(temp, charsmax(temp), "Reload: \r%i/%i \y|%i%% szybszy reload", g_statystyki[id][RELOAD], LIMIT_RELOADU, g_statystyki[id][RELOAD]);
	menu_additem(menu, temp, "", 0, mcb);
	formatex(temp, charsmax(temp), "Kamuflaz: \r%i/%i \y|Masz %i%% widocznosci", g_statystyki[id][KAMUFLAZ], LIMIT_KAMUFLAZU, (255-(g_statystyki[id][KAMUFLAZ]*3))*100/255);
	menu_additem(menu, temp, "", 0, mcb);
	g_buffer[666] = g_statystyki[id][UNIK]*50
	formatex(temp, charsmax(temp), "Unik \r%i/%i \y|%d.%02d%% na unik obrazen", g_statystyki[id][UNIK], LIMIT_UNIKU, g_buffer[666]/100, g_buffer[666]%100)
	menu_additem(menu, temp, "", 0, mcb);
      g_buffer[666] = g_statystyki[id][KRYTYK]*40
	formatex(temp, charsmax(temp), "Krytyk \r%i/%i \y|%d.%02d%% na potrojne obrazenia", g_statystyki[id][KRYTYK], LIMIT_KRYTYKU, g_buffer[666]/100, g_buffer[666]%100)
	menu_additem(menu, temp, "", 0, mcb);
	

	menu_setprop(menu, MPROP_PERPAGE, 7)
	menu_setprop(menu, MPROP_EXIT, 1);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	menu_display(id, menu, strona);
}

public PrzydzielPunkty_cb(id, menu, item)
{
      if(!g_statystyki[id][PUNKTY]) return ITEM_DISABLED
      
      switch(item)
      {
            case 1:
                  if(g_statystyki[id][INTELIGENCJA] >= LIMIT_INTELIGENCJI) return ITEM_DISABLED
            case 2:
                  if(g_statystyki[id][ZDROWIE] >= LIMIT_ZDROWIA) return ITEM_DISABLED
            case 3:
                  if(g_statystyki[id][WYTRZYMALOSC] >= LIMIT_WYTRZYMALOSCI) return ITEM_DISABLED
            case 4:
                  if(g_statystyki[id][KONDYCJA] >= LIMIT_KONDYCJI) return ITEM_DISABLED
            case 5:
                  if(g_statystyki[id][OBRAZENIA] >= LIMIT_OBRAZEN) return ITEM_DISABLED
            case 6:
                  if(g_statystyki[id][EXP] >= LIMIT_EXPA) return ITEM_DISABLED
            case 8:
                  if(g_statystyki[id][KEVLAR] >= LIMIT_KEVLARU) return ITEM_DISABLED
            case 9:
                  if(g_statystyki[id][EKONOMIA] >= LIMIT_EKONOMII) return ITEM_DISABLED
            case 10:
                  if(g_statystyki[id][RELOAD] >= LIMIT_RELOADU) return ITEM_DISABLED
            case 11:
                  if(g_statystyki[id][KAMUFLAZ] >= LIMIT_KAMUFLAZU) return ITEM_DISABLED
            case 12:
                  if(g_statystyki[id][UNIK] >= LIMIT_UNIKU) return ITEM_DISABLED
            case 13:
                  if(g_statystyki[id][KRYTYK] >= LIMIT_KRYTYKU) return ITEM_DISABLED
      }
      
      return ITEM_ENABLED
}


public PrzydzielPunkty_Handler(id, menu, item)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	static ilosc;
      ilosc = (co_ile[szybkosc_rozdania[id]] > g_statystyki[id][PUNKTY]) ? g_statystyki[id][PUNKTY] : co_ile[szybkosc_rozdania[id]]
	
	switch(item) 
	{ 		
		case 0, 7: 
		{
			if(szybkosc_rozdania[id] < charsmax(co_ile))
				szybkosc_rozdania[id]++;
			else
				szybkosc_rozdania[id] = 0;
			
			PrzydzielPunkty(id, item/7)
		}
		case 1: 
		{	
                  if(ilosc > LIMIT_INTELIGENCJI - g_statystyki[id][INTELIGENCJA])
                        ilosc = LIMIT_INTELIGENCJI - g_statystyki[id][INTELIGENCJA];
                  g_statystyki[id][INTELIGENCJA]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 2: 
		{	
                  if(ilosc > LIMIT_ZDROWIA - g_statystyki[id][ZDROWIE])
                        ilosc = LIMIT_ZDROWIA - g_statystyki[id][ZDROWIE];
                  g_statystyki[id][ZDROWIE]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 3: 
		{	
                  if(ilosc > LIMIT_WYTRZYMALOSCI - g_statystyki[id][WYTRZYMALOSC])
                        ilosc = LIMIT_WYTRZYMALOSCI - g_statystyki[id][WYTRZYMALOSC];
                  g_statystyki[id][WYTRZYMALOSC]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 4: 
		{	
                  if(ilosc > LIMIT_KONDYCJI - g_statystyki[id][KONDYCJA])
                        ilosc = LIMIT_KONDYCJI - g_statystyki[id][KONDYCJA];
                  g_statystyki[id][KONDYCJA]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 5: 
		{	
                  if(ilosc > LIMIT_OBRAZEN - g_statystyki[id][OBRAZENIA])
                        ilosc = LIMIT_OBRAZEN - g_statystyki[id][OBRAZENIA];
                  g_statystyki[id][OBRAZENIA]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 6: 
		{	
                  if(ilosc > LIMIT_EXPA - g_statystyki[id][EXP])
                        ilosc = LIMIT_EXPA - g_statystyki[id][EXP];
                  g_statystyki[id][EXP]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 8: 
		{
                  if(ilosc > LIMIT_KEVLARU - g_statystyki[id][KEVLAR])
                        ilosc = LIMIT_KEVLARU - g_statystyki[id][KEVLAR];
                  g_statystyki[id][KEVLAR]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 9: 
		{
                  if(ilosc > LIMIT_EKONOMII - g_statystyki[id][EKONOMIA])
                        ilosc = LIMIT_EKONOMII - g_statystyki[id][EKONOMIA];
                  g_statystyki[id][EKONOMIA]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 10:	
		{
                  if(ilosc > LIMIT_RELOADU - g_statystyki[id][RELOAD])
                        ilosc = LIMIT_RELOADU - g_statystyki[id][RELOAD];
                  g_statystyki[id][RELOAD]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
		case 11:	
		{
                  if(ilosc > LIMIT_KAMUFLAZU - g_statystyki[id][KAMUFLAZ])
                        ilosc = LIMIT_KAMUFLAZU - g_statystyki[id][KAMUFLAZ];
                  g_statystyki[id][KAMUFLAZ]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;
		}
            case 12:	
		{
                  if(ilosc > LIMIT_UNIKU - g_statystyki[id][UNIK])
                        ilosc = LIMIT_UNIKU - g_statystyki[id][UNIK];
                  g_statystyki[id][UNIK]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;	
		}
            case 13:	
		{
                  if(ilosc > LIMIT_KRYTYKU - g_statystyki[id][KRYTYK])
                        ilosc = LIMIT_KRYTYKU - g_statystyki[id][KRYTYK];
                  g_statystyki[id][KRYTYK]+=ilosc;
                  g_statystyki[id][PUNKTY]-=ilosc;	
		}
	}
	
	if(g_statystyki[id][PUNKTY] > 0)
            PrzydzielPunkty(id, item/7)
}

public KomendaResetujPunkty(id)
{
	client_cmd(id, "spk QTM_CodMod/select");
	
	ResetujPunkty(id);
}

ResetujPunkty(id)
{
	static i;
	
	for(i = 1; i < typ_statystyk; i++)
            g_statystyki[id][i] = 0;

	if((g_statystyki[id][PUNKTY] = (poziom_gracza[id]-1)*2))
		PrzydzielPunkty(id, 0);
}

public EmitSound(id, iChannel, szSound[]) 
{
	if(!is_user_alive(id)) return FMRES_IGNORED;
	
	if(equal(szSound, "common/wpn_denyselect.wav"))
	{
		static forward_handle
		forward_handle = CreateOneForward(ArrayGetCell(pluginy_klas, klasa_gracza[id]), "cod_class_skill_used", FP_CELL);
		ExecuteForward(forward_handle, id, id);
		DestroyForward(forward_handle);
	
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public UzyjPerku(id)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	
	static forward_handle
	forward_handle = CreateOneForward(ArrayGetCell(pluginy_perkow, perk_gracza[id]), "cod_perk_used", FP_CELL);
	ExecuteForward(forward_handle, id, id);
	DestroyForward(forward_handle);

	return PLUGIN_HANDLED;
}

ZapiszDane(id)
{
	if(!klasa_gracza[id] || doswiadczenie_gracza[id] < 1) return;

	static vaultkey[128];

	ArrayGetString(nazwy_klas, klasa_gracza[id], g_buffer, MAX_WIELKOSC_NAZWY)

      #if defined ZAPIS_NA_STEAM
      static sID[35]
	get_user_authid(id, sID, charsmax(sID));
	formatex(vaultkey, charsmax(vaultkey), "%s-%s", sID, g_buffer);
	#else
	formatex(vaultkey, charsmax(vaultkey), "%s-%s", nazwa_gracza[id], g_buffer);
	#endif
	
	formatex(g_buffer, 128, "%i %i %i %i %i %i %i %i %i %i %i %i %i", doswiadczenie_gracza[id], g_statystyki[id][INTELIGENCJA], g_statystyki[id][ZDROWIE], g_statystyki[id][WYTRZYMALOSC], g_statystyki[id][KONDYCJA], g_statystyki[id][OBRAZENIA], g_statystyki[id][EXP], g_statystyki[id][KEVLAR], g_statystyki[id][EKONOMIA], g_statystyki[id][RELOAD], g_statystyki[id][KAMUFLAZ], g_statystyki[id][UNIK], g_statystyki[id][KRYTYK]);
	
	nvault_set(vault, vaultkey, g_buffer);
}

WczytajPoziom(id)
{
	static vaultkey[128], poziom, xp
	
      #if defined ZAPIS_NA_STEAM
      static sID[35]
	get_user_authid(id, sID, charsmax(sID));
	formatex(vaultkey, charsmax(vaultkey), "%s-%s", sID, g_buffer);
	#else
	formatex(vaultkey, charsmax(vaultkey), "%s-%s", nazwa_gracza[id], g_buffer);
	#endif

	poziom = 1;
	if((xp = nvault_get(vault, vaultkey)))
	{
		while(xp >= PobierzDoswiadczeniePoziomu(poziom) && poziom < limit_poziomu)
			poziom++;
	}

	return poziom;
}

WczytajDane(id)
{
	static vaultkey[128], vaultdata[128]
	
      #if defined ZAPIS_NA_STEAM
      static sID[35]
	get_user_authid(id, sID, charsmax(sID));
	formatex(vaultkey, charsmax(vaultkey), "%s-%s", sID, g_buffer);
	#else
	formatex(vaultkey, charsmax(vaultkey), "%s-%s", nazwa_gracza[id], g_buffer);
	#endif
	
	poziom_gracza[id] = 1;
	
	if(nvault_get(vault, vaultkey, vaultdata, 127))
	{
		static danegracza[13][21];
		
		parse(vaultdata, danegracza[0], 20, danegracza[1], 20, danegracza[2], 20, danegracza[3], 20, danegracza[4], 20, danegracza[5], 20, danegracza[6], 20, danegracza[7], 20, danegracza[8], 20, danegracza[9], 20, danegracza[10], 20, danegracza[11], 20, danegracza[12], 20);
		
		doswiadczenie_gracza[id] = str_to_num(danegracza[0]);
		while(doswiadczenie_gracza[id] >= PobierzDoswiadczeniePoziomu(poziom_gracza[id]) && poziom_gracza[id] < limit_poziomu)
			poziom_gracza[id]++;

		g_statystyki[id][INTELIGENCJA] = str_to_num(danegracza[1]);
		g_statystyki[id][ZDROWIE] = str_to_num(danegracza[2]);
		g_statystyki[id][WYTRZYMALOSC] = str_to_num(danegracza[3]);
		g_statystyki[id][KONDYCJA] = str_to_num(danegracza[4]);
		g_statystyki[id][OBRAZENIA] = str_to_num(danegracza[5]);
		g_statystyki[id][EXP] = str_to_num(danegracza[6]);
		g_statystyki[id][KEVLAR] = str_to_num(danegracza[7]);
		g_statystyki[id][EKONOMIA] = str_to_num(danegracza[8]);
		g_statystyki[id][RELOAD] = str_to_num(danegracza[9]);
		g_statystyki[id][KAMUFLAZ] = str_to_num(danegracza[10]);
		g_statystyki[id][UNIK] = str_to_num(danegracza[11]);
		g_statystyki[id][KRYTYK] = str_to_num(danegracza[12]);
		g_statystyki[id][PUNKTY] = (poziom_gracza[id]-1)*2-g_statystyki[id][INTELIGENCJA]-g_statystyki[id][ZDROWIE]-g_statystyki[id][WYTRZYMALOSC]-g_statystyki[id][KONDYCJA]-g_statystyki[id][OBRAZENIA]-g_statystyki[id][EXP]-g_statystyki[id][KEVLAR]-g_statystyki[id][EKONOMIA]-g_statystyki[id][RELOAD]-g_statystyki[id][KAMUFLAZ]-g_statystyki[id][UNIK]-g_statystyki[id][KRYTYK];

		nvault_touch(vault, vaultkey);
	}
	else
	{
		doswiadczenie_gracza[id] = 0;
		static i;
            for(i = 1; i < typ_statystyk; i++)
                  g_statystyki[id][i] = 0;
	}
} 

public SprzedajPerk(id)
{
	if(perk_gracza[id])
	{
            static cena;
            cena = random_num(1, 1500);

		client_print_color(id, print_team_red, "%s Sprzedales perk za %i$!", prefix, cena)
            cs_set_user_money(id, min(16000, cs_get_user_money(id) + cena));
		
		UstawPerk(id, 0, 0, 0);
	}
	else
		client_print_color(id, print_team_red, "%s Nie masz zadnego perku", prefix)
	
	return PLUGIN_HANDLED;
}

SprawdzPoziom(id)
{	
	static bool:zdobyl_poziom, bool:stracil_poziom
	zdobyl_poziom = false;
	stracil_poziom = false;

	while(doswiadczenie_gracza[id] >= PobierzDoswiadczeniePoziomu(poziom_gracza[id]) && poziom_gracza[id] < limit_poziomu)
	{
		poziom_gracza[id]++;
		zdobyl_poziom = true;
	}
	
	while(doswiadczenie_gracza[id] < PobierzDoswiadczeniePoziomu(poziom_gracza[id]-1) && poziom_gracza[id] > 1)
	{
		poziom_gracza[id]--;
		stracil_poziom = true;
	}

	if(stracil_poziom)
		ResetujPunkty(id);
	
	else if(zdobyl_poziom)
	{
		g_statystyki[id][PUNKTY] = (poziom_gracza[id]-1)*2-g_statystyki[id][INTELIGENCJA]-g_statystyki[id][ZDROWIE]-g_statystyki[id][WYTRZYMALOSC]-g_statystyki[id][KONDYCJA]-g_statystyki[id][OBRAZENIA]-g_statystyki[id][EXP]-g_statystyki[id][KEVLAR]-g_statystyki[id][EKONOMIA]-g_statystyki[id][RELOAD]-g_statystyki[id][KAMUFLAZ]-g_statystyki[id][UNIK]-g_statystyki[id][KRYTYK];
		client_cmd(id, "spk QTM_CodMod/levelup");
	}
}

public cod_klan_changed(id, const nazwaKlanu[])
      formatex(klan_gracza[id], 32, nazwaKlanu)

public PokazInformacje(id) 
{
	id -= ZADANIE_POKAZ_INFORMACJE;

      static Time[7], klasa[MAX_WIELKOSC_NAZWY+1], perk[MAX_WIELKOSC_NAZWY+1], target, Float:fProcent;
      get_time("%H:%M", Time, 6)

      if(!is_user_alive(id))
      {
            target = pev(id, pev_iuser2);

            if(!target) return;

            ArrayGetString(nazwy_klas, klasa_gracza[target], klasa, MAX_WIELKOSC_NAZWY)
            ArrayGetString(nazwy_perkow, perk_gracza[target], perk, MAX_WIELKOSC_NAZWY)

            set_hudmessage(255, 255, 255, 0.01, 0.19, 0, _, 0.7, 0.4, 1.1, 2)
            #if defined WYTRZYMALOSC_PERKU
            ShowSyncHudMsg(id, SyncHudObj, "%s^n%s %i lvl | Perk [%i/%i]: %s^n%s | Killstreak: %i | Status: Gracz %s^nKlan: <%s>", forum, klasa, poziom_gracza[target], wytrzymalosc_perku[target], MAX_WYTRZYMALOSC_PERKU, perk, Time, killstreak_gracza[target], szStatus[g_status[target]], klan_gracza[target]);
            #else
            ShowSyncHudMsg(id, SyncHudObj, "%s^n%s %i lvl | Perk: %s^n%s | Killstreak: %i | Status: Gracz %s^nKlan: <%s>", forum, klasa, poziom_gracza[target], perk, Time, killstreak_gracza[target], szStatus[g_status[target]], klan_gracza[target]);
            #endif
            
            return;
      }
      
      if(!doswiadczenie_gracza[id])
            fProcent = 0.0;
      else if(poziom_gracza[id] >= limit_poziomu)
            fProcent = 100.0;
      else
      {
            target = PobierzDoswiadczeniePoziomu(poziom_gracza[id]-1);
            fProcent = 100.0 * (doswiadczenie_gracza[id] - target) / (PobierzDoswiadczeniePoziomu(poziom_gracza[id]) - target);
      }

      ArrayGetString(nazwy_klas, klasa_gracza[id], klasa, MAX_WIELKOSC_NAZWY)
      ArrayGetString(nazwy_perkow, perk_gracza[id], perk, MAX_WIELKOSC_NAZWY)

      set_hudmessage(90, 255, 50, -1.0, 0.0, 0, _, 0.7, 0.4, 1.1, 2);
      #if defined WYTRZYMALOSC_PERKU
      ShowSyncHudMsg(id, SyncHudObj, "%s^n%s %i lvl | XP : %0.2f%%^nPerk [%i/%i]: %s^n%s | KS: %i^nHP: %i | Klan: <%s>", forum, klasa, poziom_gracza[id], fProcent, wytrzymalosc_perku[id], MAX_WYTRZYMALOSC_PERKU, perk, Time, killstreak_gracza[id], get_user_health(id), klan_gracza[id]);
      #else
      ShowSyncHudMsg(id, SyncHudObj, "%s^n%s %i lvl | XP : %0.2f%%^nPerk: %s^n%s | KS: %i^nHP: %i | Klan: <%s>", forum, klasa, poziom_gracza[id], fProcent, perk, Time, killstreak_gracza[id], get_user_health(id), klan_gracza[id]);
      #endif
}

public Pomoc(id) show_motd(id, "addons/amxmodx/data/pomoc.txt", "Pomoc")
public ShowMotdSP(id) show_motd(id, "addons/amxmodx/data/spremium.txt", "Informacje o Super Premium");
public ShowMotdP(id) show_motd(id, "addons/amxmodx/data/premium.txt", "Informacje o Premium");

public DotykBroni(weapon, id)
{
	if(!is_user_connected(id) || pev(weapon, pev_owner) == id) return HAM_IGNORED;
	if((1<<cs_get_weapon_id(weapon)) & (ArrayGetCell(bronie_klasy, klasa_gracza[id]) | bonusowe_bronie_gracza[id] | bronie_dozwolone)) return HAM_IGNORED;

	static model[19]
      pev(weapon, pev_model, model, 18);
	if (containi(model, "w_backpack") != -1) return HAM_IGNORED;

	return HAM_SUPERCEDE;
}

public UstawPerk(id, perk, wartosc, pokaz_info)
{
	if(iloscPerkow == 1) return;
	
	static obroty[MAX_PLAYERS+1], ret, forward_handle, maxWartosc, minWartosc;
	
	if(obroty[id]++ >= 3)
	{
		ExecuteForward(perk_zmieniony, ret, id, 0);

		forward_handle = CreateOneForward(ArrayGetCell(pluginy_perkow, perk_gracza[id]), "cod_perk_disabled", FP_CELL);
		ExecuteForward(forward_handle, ret, id);
		DestroyForward(forward_handle);

		perk_gracza[id] = 0;    
		wartosc_perku_gracza[id] = 0;
		#if defined WYTRZYMALOSC_PERKU
		wytrzymalosc_perku[id] = 0
		#endif
		obroty[id] = 0;

		return;
	}

	if(perk == -1)
		perk = random_num(1, iloscPerkow-1)
		
	maxWartosc = ArrayGetCell(max_wartosci_perkow, perk), minWartosc = ArrayGetCell(min_wartosci_perkow, perk)

	if(wartosc == -1 || minWartosc < wartosc || wartosc > maxWartosc)
		wartosc = random_num(minWartosc, maxWartosc)

	ExecuteForward(perk_zmieniony, ret, id, perk);

	if(ret == COD_STOP)
	{
		UstawPerk(id, -1, -1, 1);
		return;
	}

	forward_handle = CreateOneForward(ArrayGetCell(pluginy_perkow, perk_gracza[id]), "cod_perk_disabled", FP_CELL);
	ExecuteForward(forward_handle, ret, id);
	DestroyForward(forward_handle);
	
	forward_handle = CreateOneForward(ArrayGetCell(pluginy_perkow, perk), "cod_perk_enabled", FP_CELL, FP_CELL);
	ExecuteForward(forward_handle, ret, id, wartosc);
	DestroyForward(forward_handle);
	
	if(ret == COD_STOP)
	{
		UstawPerk(id, -1, -1, 1);
		return;
	}
	
	#if defined WYTRZYMALOSC_PERKU
	wytrzymalosc_perku[id] = perk ? MAX_WYTRZYMALOSC_PERKU : 0
	#endif

	perk_gracza[id] = perk;    
	wartosc_perku_gracza[id] = wartosc;
      
	obroty[id] = 0;
	
	if(pokaz_info && perk_gracza[id])
	{
            ArrayGetString(nazwy_perkow, perk_gracza[id], g_buffer, MAX_WIELKOSC_NAZWY)
		client_print_color(id, print_team_red, "%s Zdobyles %s", prefix, g_buffer)
      }
}

public handleSayText()
{
	static szTmp[192], szTmp2[192], szPrefix[32], id;
	id = get_msg_arg_int(1);
	
	if(!g_status[id]) return;

	get_msg_arg_string(2, szTmp, charsmax(szTmp));
	
	if(g_status[id] == STATUS_PREMIUM)
		szPrefix = szPrefixPremium
	else if(g_status[id] > STATUS_PREMIUM)
		szPrefix = szPrefixSPremium		
   
	if(!equal(szTmp,"#Cstrike_Chat_All"))
		formatex(szTmp2, charsmax(szTmp2), "^4%s %s", szPrefix, szTmp)
	else
	{
		get_msg_arg_string(4, szTmp, charsmax(szTmp));
		set_msg_arg_string(4, "");

		formatex(szTmp2, charsmax(szTmp2), "^4%s^3 %s^1 : %s", szPrefix, nazwa_gracza[id], szTmp)
	}
    
	set_msg_arg_string(2, szTmp2);
}

public VipStatus()
{
	static id;
	id = get_msg_arg_int(1);
	if(is_user_alive(id) && g_status[id])
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | 4);
}

public UstawDoswiadczenie(id, wartosc)
{
	doswiadczenie_gracza[id] = wartosc;
	SprawdzPoziom(id);
}

public DodajDoswiadczenie(id, wartosc)
{
	doswiadczenie_gracza[id] += wartosc;
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

public DajBron(id, bron)
{
	bonusowe_bronie_gracza[id] |= (1<<bron);
	fm_give_item(id, Nazwy_broni[bron]);
	cs_set_user_bpammo(id, bron, maxAmmo[bron]);
}

public WezBron(id, bron)
{
	bonusowe_bronie_gracza[id] &= ~(1<<bron);
	
	if((1<<bron) & (bronie_dozwolone | ArrayGetCell(bronie_klasy, klasa_gracza[id]))) return;

	ham_strip_weapon(id, bron)
}

public UsunRender(plugin)
{
	static id;
	id = get_param(1)

	if(!is_user_connected(id)) return;

	static i, size;
	size = ArraySize(gRender[id])
	for(i = 1; i < size; i++)
	{
		if(ArrayGetCell(gRenderPlugin[id], i) == plugin)
		{
			ArrayDeleteItem(gRender[id], i)
			ArrayDeleteItem(gRenderPlugin[id], i)
			break;
		}
	}
	
	ZastosujRender(id)
}

public UstawRendering(plugin)
{
	static id;
	id = get_param(1)

	if(!is_user_connected(id)) return;

	ArrayPushCell(gRender[id], get_param(2))
	ArrayPushCell(gRenderPlugin[id], plugin)
	ZastosujRender(id)
}

public ZastosujRender(id)
{
	static i, min, size, cell;
	min = 255
	size = ArraySize(gRender[id])

	for(i = 0; i < size; i++)
	{
		cell = ArrayGetCell(gRender[id], i)
		if(min > cell)
			min = cell
	}

	fm_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, min);
}
	
public DodajBonusoweZdrowie(id, wartosc)
	bonusowe_zdrowie_gracza[id] += wartosc;

public DodajBonusowaInteligencje(id, wartosc)
	bonusowa_inteligencja_gracza[id] += wartosc;

public DodajBonusowaKondycje(id, wartosc)
{
	bonusowa_kondycja_gracza[id] += wartosc;
	szybkosc_gracza[id] = STANDARDOWA_SZYBKOSC+PobierzKondycje(id, 1, 1, 1)*1.3;
}

public DodajBonusowaWytrzymalosc(id, wartosc)
	bonusowa_wytrzymalosc_gracza[id] += wartosc;

public PobierzPerk()
{
	new id = get_param(1)
	set_param_byref(2, wartosc_perku_gracza[id])

	return perk_gracza[id];
}

public PobierzNazwePerku(perk, Return[], len)
{
	if(perk < iloscPerkow)
	{
		param_convert(2);
		ArrayGetString(nazwy_perkow, perk, Return, len)
	}
}

public PobierzOpisPerku(perk, Return[], len)
{
	if(perk < iloscPerkow)
	{
		param_convert(2);
		ArrayGetString(opisy_perkow, perk, Return, len)
	}
}

public PobierzPerkPrzezNazwe(const nazwa[])
{
	static i;
	param_convert(1);
	for(i = 1; i < iloscPerkow; i++)
	{
            ArrayGetString(nazwy_perkow, i, g_buffer, MAX_WIELKOSC_NAZWY)
		if(equal(nazwa, g_buffer))
                  return i;
      }

	return 0;
}

public PobierzDoswiadczeniePoziomu(poziom)
	return power(poziom, 2) * get_pcvar_num(cvar_proporcja_poziomu);

public PobierzDoswiadczenie(id)
	return doswiadczenie_gracza[id];

public PobierzPoziom(id)
	return poziom_gracza[id];

public PobierzZdrowie(id, zdrowie_zdobyte, zdrowie_klasy, zdrowie_bonusowe)
{
	static zdrowie;
	zdrowie = 0
	
	if(zdrowie_zdobyte)
		zdrowie += g_statystyki[id][ZDROWIE];
	if(zdrowie_bonusowe)
		zdrowie += bonusowe_zdrowie_gracza[id];
	if(zdrowie_klasy)
		zdrowie += ArrayGetCell(zdrowie_klas, klasa_gracza[id]);
	
	return zdrowie;
}

public PobierzInteligencje(id, inteligencja_zdobyta, inteligencja_klasy, inteligencja_bonusowa)
{
	static inteligencja;
	inteligencja = 0

	if(inteligencja_zdobyta)
		inteligencja += g_statystyki[id][INTELIGENCJA];
	if(inteligencja_bonusowa)
		inteligencja += bonusowa_inteligencja_gracza[id];
	if(inteligencja_klasy)
		inteligencja += ArrayGetCell(inteligencja_klas, klasa_gracza[id]);
	
	return inteligencja;
}

public PobierzKondycje(id, kondycja_zdobyta, kondycja_klasy, kondycja_bonusowa)
{
	static kondycja;
	kondycja = 0
	
	if(kondycja_zdobyta)
		kondycja += g_statystyki[id][KONDYCJA];
	if(kondycja_bonusowa)
		kondycja += bonusowa_kondycja_gracza[id];
	if(kondycja_klasy)
		kondycja += ArrayGetCell(kondycja_klas, klasa_gracza[id])
	
	return kondycja;
}

public PobierzWytrzymalosc(id, wytrzymalosc_zdobyta, wytrzymalosc_klasy, wytrzymalosc_bonusowa)
{
	static wytrzymalosc;
	wytrzymalosc = 0
	
	if(wytrzymalosc_zdobyta)
		wytrzymalosc += g_statystyki[id][WYTRZYMALOSC];
	if(wytrzymalosc_bonusowa)
		wytrzymalosc += bonusowa_wytrzymalosc_gracza[id];
	if(wytrzymalosc_klasy)
		wytrzymalosc += ArrayGetCell(wytrzymalosc_klas, klasa_gracza[id])
	
	return wytrzymalosc;
}

public PobierzKlase(id)
	return klasa_gracza[id];

public PobierzNazweKlasy(klasa, Return[], len)
{
	if(klasa < iloscKlas)
	{
		param_convert(2);
		ArrayGetString(nazwy_klas, klasa, Return, len)
	}
}

public PobierzOpisKlasy(klasa, Return[], len)
{
	if(klasa < iloscKlas)
	{
		param_convert(2);
		ArrayGetString(opisy_klas, klasa, Return, len)
	}
}

public PobierzKlasePrzezNazwe(const nazwa[])
{
	static i;
	param_convert(1);
	for(i = 1; i < iloscKlas; i++)
	{
            ArrayGetString(nazwy_klas, i, g_buffer, MAX_WIELKOSC_NAZWY)
		if(equal(nazwa, g_buffer))
                  return i;
      }
	return 0;
}

public PobierzStatusGracza(id)
      return g_status[id]
      
public PobierzIloscKlas()
	return iloscKlas-1;
	
public PobierzIloscPerkow()
	return iloscPerkow-1;

#if defined WYTRZYMALOSC_PERKU
public PobierzWytrzymaloscPerku(id)
	return wytrzymalosc_perku[id];
	
public UstawWytrzymaloscPerku(id, wartosc)
	wytrzymalosc_perku[id] = (wartosc > MAX_WYTRZYMALOSC_PERKU) ? MAX_WYTRZYMALOSC_PERKU : wartosc;
#endif

public PobierzSumeBitowaBonusowychBroni(id)
      return bonusowe_bronie_gracza[id]
      
public FastReload(id, bool:mode)
	szybki_reload[id] = mode

public ZadajObrazenia(attacker, victim, Float:dmg, Float:czynnik_inteligencji, byt_uszkadzajacy, damagebits)
	ExecuteHam(Ham_TakeDamage, victim, byt_uszkadzajacy, attacker, dmg+(PobierzInteligencje(attacker, 1, 1, 1)*czynnik_inteligencji), damagebits);

public ZarejestrujPerk(plugin, params)
{
	if(params != 4) return;
	
	ArrayPushCell(pluginy_perkow, plugin)
	
      get_string(1, g_buffer, MAX_WIELKOSC_NAZWY);
	ArrayPushString(nazwy_perkow, g_buffer)

	get_string(2, g_buffer, MAX_WIELKOSC_OPISU);
	ArrayPushString(opisy_perkow, g_buffer)

      ArrayPushCell(min_wartosci_perkow, get_param(3))
	ArrayPushCell(max_wartosci_perkow, get_param(4))
}

public ZarejestrujKlase(plugin, params)
{
	if(params != 8) return;

	ArrayPushCell(pluginy_klas, plugin)
	
	get_string(1, g_buffer, MAX_WIELKOSC_NAZWY);
	ArrayPushString(nazwy_klas, g_buffer)
	
	get_string(2, g_buffer, MAX_WIELKOSC_OPISU);
	ArrayPushString(opisy_klas, g_buffer)
	
	ArrayPushCell(bronie_klasy, get_param(3))
	ArrayPushCell(zdrowie_klas, get_param(4))
	ArrayPushCell(kondycja_klas, get_param(5))
	ArrayPushCell(inteligencja_klas, get_param(6))
	ArrayPushCell(wytrzymalosc_klas, get_param(7))
	
	get_string(8, g_buffer, MAX_WIELKOSC_NAZWY);
	ArrayPushString(frakcja_klas, g_buffer)
	ArrayPushString(typ_frakcji, g_buffer)
}

public BlokujKomende() return PLUGIN_HANDLED;
public HamSupercede() return HAM_SUPERCEDE;
public ClientKill() return FMRES_SUPERCEDE
    
public plugin_natives()
{
	register_native("cod_set_user_xp", "UstawDoswiadczenie", 1);
	register_native("cod_add_user_xp", "DodajDoswiadczenie", 1);
	register_native("cod_set_user_class", "UstawKlase", 1);
	register_native("cod_set_user_perk", "UstawPerk", 1);

      register_native("cod_add_user_bonus_health", "DodajBonusoweZdrowie", 1);
	register_native("cod_add_user_bonus_intelligence", "DodajBonusowaInteligencje", 1);
	register_native("cod_add_user_bonus_trim", "DodajBonusowaKondycje", 1);
	register_native("cod_add_user_bonus_stamina", "DodajBonusowaWytrzymalosc", 1);

	register_native("cod_get_user_xp", "PobierzDoswiadczenie", 1);
	register_native("cod_get_user_level", "PobierzPoziom", 1);
	register_native("cod_get_user_class", "PobierzKlase", 1);
	register_native("cod_get_user_perk", "PobierzPerk");
	
	register_native("cod_get_user_health", "PobierzZdrowie", 1);
	register_native("cod_get_user_intelligence", "PobierzInteligencje", 1);
	register_native("cod_get_user_trim", "PobierzKondycje", 1);
	register_native("cod_get_user_stamina", "PobierzWytrzymalosc", 1);

	register_native("cod_get_level_xp", "PobierzDoswiadczeniePoziomu", 1);
	
	register_native("cod_get_perkid", "PobierzPerkPrzezNazwe", 1);
	register_native("cod_get_perk_name", "PobierzNazwePerku", 1);
	register_native("cod_get_perk_desc", "PobierzOpisPerku", 1);
	register_native("cod_get_perks_num", "PobierzIloscPerkow", 1);
	
	register_native("cod_get_classid", "PobierzKlasePrzezNazwe", 1);
	register_native("cod_get_class_name", "PobierzNazweKlasy", 1);
	register_native("cod_get_class_desc", "PobierzOpisKlasy", 1);
	register_native("cod_get_classes_num", "PobierzIloscKlas", 1)
	
	register_native("cod_give_weapon", "DajBron", 1);
	register_native("cod_take_weapon", "WezBron", 1);
	
	register_native("cod_inflict_damage", "ZadajObrazenia", 1);
	
	register_native("cod_register_perk", "ZarejestrujPerk");
	register_native("cod_register_class", "ZarejestrujKlase");
	
	register_native("cod_get_user_status", "PobierzStatusGracza", 1);
	
	#if defined WYTRZYMALOSC_PERKU
	register_native("cod_get_perk_durability", "PobierzWytrzymaloscPerku", 1);
	register_native("cod_set_perk_durability", "UstawWytrzymaloscPerku", 1);
	#endif
	
	register_native("cod_get_bonus_weapons_bitsum", "PobierzSumeBitowaBonusowychBroni", 1)
	register_native("cod_user_fast_reload", "FastReload", 1);
	register_native("cod_set_user_rendering", "UstawRendering")
	register_native("cod_remove_user_rendering", "UsunRender")
	register_native("cod_refresh_rendering", "ZastosujRender", 1)
}

get_loguser_index()
{
	static name[33]
	read_logargv(0, g_buffer, 79)
	
	parse_loguser(g_buffer, name, 32)
	
	return get_user_index(name)
}

Display_Fade(id, r, g, b)
{
    message_begin(MSG_ONE_UNRELIABLE, msgScreenFade, {0, 0, 0}, id);
    write_short((1<<12) * 2);  // Duration of fadeout
    write_short((1<<12) * 2);  // Hold time of color
    write_short(0);    // Fade type
    write_byte (r);         // Red
    write_byte (g);       // Green
    write_byte (b);        // Blue
    write_byte (90);       // Alpha
    message_end();
}

public plugin_end()
{
      nvault_close(vault)

      ArrayDestroy(bronie_klasy)
      ArrayDestroy(zdrowie_klas)
      ArrayDestroy(kondycja_klas)
      ArrayDestroy(inteligencja_klas)
      ArrayDestroy(wytrzymalosc_klas)
      ArrayDestroy(pluginy_klas)
      ArrayDestroy(opisy_klas)
      ArrayDestroy(min_wartosci_perkow)
      ArrayDestroy(max_wartosci_perkow)
      ArrayDestroy(pluginy_perkow)
	ArrayDestroy(opisy_perkow)
      ArrayDestroy(nazwy_perkow)
      ArrayDestroy(frakcja_klas)
      ArrayDestroy(nazwy_klas)
      ArrayDestroy(typ_frakcji)
}