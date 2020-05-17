//=-=-=-=-=-=-=-=-=-=-=-=-=-=//
#pragma compress 1
//=-=-=-=-=-=-=-=-=-=-=-=-=-=//

#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <nvault_util>
#include <nvault_array>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <dd2mod>

// Przydziela dodatkowa pamiec aby zapobiec bledowi stack error :)
#pragma dynamic 16384

#define PLUGIN "DD2 MISJE"
#define VERSION "v1"
#define AUTHOR ""
#define PREFIX "Misja"


new opis_misji[][] =
{
	"-",
	"Rozegraj %d rund",
	"Zabij %d osób",
	"Zabij %d osób w głowe",
	"Zadaj %d dmg",
	"Zadaj %d dmg w g�owe",
	"Podłóż/Rozbrój C4 %d razy",
	"Podnieś %d amunicji",
	"Przetrwaj %d rund bez zgonu",
	"Zabij %d osób bez zgonu",
	"Zabij %d osób w głowe bez zgonu",
	"Zadaj %d dmg bez zgonu",
	"Zadaj %d dmg w głowe bez zgonu",
	"-",
	"-",
	"-",
	"-",
	"-",
	"-",
	"-",
	"Zabij %d prowadzacych",
	"Zabij %d prowadzacych w glowe",
	"Zabij %d straznikow",
	"Zabij %d straznikow w glowe",
	"Zadaj %d dmg prowadzacemu",
	"Zadaj %d dmg prowadzacemu w glowe",
	"Zadaj %d dmg straznikom",
	"Zadaj %d dmg straznikom w glowe",
	"Przetrwaj %d razy jako ostatni wiezien",
	"Zdobadz %d zyczen"
}

new bronie_misji[][] =
{
	"DOWOLNA",
	"P228",
	"-",
	"SCOUT",
	"HEGRENADE",
	"XM1014",
	"-",
	"MAC10",
	"AUG",
	"-",
	"ELITE",
	"FIVESEVEN",
	"UMP45",
	"SG550",
	"GALIL",
	"FAMAS",
	"USP",
	"GLOCK",
	"AWP",
	"MP5NAVY",
	"M249",
	"M3",
	"M4A1",
	"TMP",
	"G3SG1",
	"-",
	"DEAGLE",
	"SG552",
	"AK47",
	"KNIFE"
}

new plik_akty[128], plik_misje[128], plik_natywy[128];
new LINIA_Z_PLIKU[128], Dlugosc;
new DANE[10][48];

new g_Hudi;
new ilosc_aktow, ilosc_misji;
new wybrany_akt[33];
new typ_misji_gracza[33], cel_misji_gracza[33], nagroda_misji_gracza[33], bron_misji_gracza[33];
new opis_misji_status[33][64];

const max_graczy_nvault = 3000;
enum top15_dane_gracza
{
    Nick_Gracza[33],
	id_misji_gracza,
	id_aktu_gracza,
	progres_misji_garcza,
	wykonanych_misji,
	wykonanych_misji_w_akcie,
	zaliczone_akty
}
new top15_dane[33][top15_dane_gracza];
new top15_nick[33][33];

new vault_misje;


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_logevent("Poczatek_Rundy", 2, "1=Round_Start");
	register_event("DeathMsg", "Zabojstwo", "a");
	RegisterHam(Ham_TakeDamage, "player", "Obrazenia");
	register_forward(FM_PlayerPreThink, "Przetrwanie");
	register_event("AmmoPickup", "Podniesienie_Ammo", "b")
	
	register_clcmd("say /misje", "Menu_Glowne");
	register_clcmd("say_team /misje", "Menu_Glowne");
	register_clcmd("say /m", "Menu_Glowne");
	register_clcmd("say_team /m", "Menu_Glowne");
	register_clcmd("say /mtop15", "Top15");
	register_clcmd("say_team /mtop15", "Top15");
	
	g_Hudi = CreateHudSyncObj();
	
	vault_misje = nvault_open("MISJE");
	
	if(vault_misje == INVALID_HANDLE)
		set_fail_state("Nie moge otworzyc pliku z danymi!");
	
	MyFile_INIT();
}

public plugin_end()
{
	nvault_close(vault_misje);
}

public plugin_precache()
{
    precache_sound("misc/sounds/mission/mission_passed.mp3");
}

public plugin_natives()
{
	register_library("MISJE");
	
	register_native("dd2_get_completemissions", "natyw_pobierz_wykonane_misje", 1);
	register_native("dd2_mission_skip", "natyw_pomin_misje", 1);
	register_native("pobierz_top15_misji", "Top15", 1);   
}

public natyw_pobierz_wykonane_misje(id)
{
	return top15_dane[id][wykonanych_misji];
}

public natyw_pomin_misje(id)
{
	top15_dane[id][wykonanych_misji_w_akcie]++
	top15_dane[id][wykonanych_misji]++;
	
	new i, ilosc_misji_w_akcie;
	for(i = 0, ilosc_misji_w_akcie = 0; read_file(plik_misje, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
	{
		parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47, DANE[2],47, DANE[3],47, DANE[4],47, DANE[5],47);
		
		if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1) && top15_dane[id][id_aktu_gracza] == str_to_num(DANE[0]))
		{
			ilosc_misji_w_akcie++;
		}
	}
	
	if(top15_dane[id][wykonanych_misji_w_akcie] >= ilosc_misji_w_akcie)
	{
		top15_dane[id][zaliczone_akty]++;
		top15_dane[id][wykonanych_misji_w_akcie] = 0;
	}
	
	top15_dane[id][id_misji_gracza] = 0;
	top15_dane[id][progres_misji_garcza] = 0;
	typ_misji_gracza[id] = 0;
	cel_misji_gracza[id] = 1;
	
	client_cmd(id, "mp3 play sound/misc/sounds/mission/mission_passed.mp3");
	
	if(get_messagestatus(id)) {
		if(!get_messagetype(id)) {
			set_hudmessage(70, 255, 0, -1.0, -1.0, 2, 0.05, 3.0, 0.05, 1.0)
			show_hudmessage(id, "Ukończył%s misje!^nOtrzymał%s dodatkowe +%d punktów", get_sextype(id) ? "aś" : "eś", get_sextype(id) ? "aś" : "eś", nagroda_misji_gracza[id]);
		}
		else if(get_messagetype(id)) {
			client_print_color(id, id, "^x03[Misje]^x01 Ukończył%s misje! Otrzymał%s dodatkowe^x04 +%d^x01 punktów!", get_sextype(id) ? "aś" : "eś", get_sextype(id) ? "aś" : "eś", nagroda_misji_gracza[id]);
		}
	}
	
	set_points(id, get_points(id) + nagroda_misji_gracza[id]);
}
	

public client_authorized(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return PLUGIN_CONTINUE;
		
	top15_dane[id][id_misji_gracza] = 0;
	top15_dane[id][id_aktu_gracza] = 0;
	top15_dane[id][progres_misji_garcza] = 0;
	top15_dane[id][wykonanych_misji] = 0;
	top15_dane[id][wykonanych_misji_w_akcie] = 0;
	top15_dane[id][zaliczone_akty] = 0;
	typ_misji_gracza[id] = 0;
	cel_misji_gracza[id] = 1;
	
	get_user_name(id, top15_nick[id], 32);
	nvault_get_array(vault_misje, top15_nick[id], top15_dane[id][top15_dane_gracza:0], sizeof(top15_dane[]));
	
	wybrany_akt[id] = top15_dane[id][id_aktu_gracza];
	
	for(new i = 0, n = 1; read_file(plik_misje, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
	{
		parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47, DANE[2],47, DANE[3],47, DANE[4],47, DANE[5],47);
		
		if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1) && wybrany_akt[id] == str_to_num(DANE[0]))
		{
			if(n == top15_dane[id][id_misji_gracza])
			{
				format(opis_misji_status[id],63, opis_misji[str_to_num(DANE[2])], str_to_num(DANE[3]));
				typ_misji_gracza[id] = str_to_num(DANE[2]);
				cel_misji_gracza[id] = str_to_num(DANE[3]);
				nagroda_misji_gracza[id] = str_to_num(DANE[4]);
				bron_misji_gracza[id] = str_to_num(DANE[5]);
				
				i = 9999;
			}
			else n++;
		}
	}
	
	set_task(1.0, "Status", id, _, _, "b");
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return PLUGIN_CONTINUE;
	
	get_user_name(id, top15_dane[id][Nick_Gracza], 32);
	nvault_set_array(vault_misje, top15_nick[id], top15_dane[id][top15_dane_gracza:0], sizeof(top15_dane[]));
	
	return PLUGIN_CONTINUE;
}

public MyFile_INIT()
{
	new configs_dir[64], base_dir[64];
	get_configsdir(configs_dir, 63);
	get_basedir(base_dir, 63);
	
	format(plik_akty, 127, "%s/MISJE/AKTY.ini", configs_dir);
	format(plik_misje, 127, "%s/MISJE/MISJE.ini", configs_dir);
	format(plik_natywy, 127, "%s/scripting/include/MISJE.inc", base_dir);
	
	if(!dir_exists("addons/amxmodx/configs/MISJE"))
		mkdir("addons/amxmodx/configs/MISJE");
	
	if(!file_exists(plik_natywy))
	{
		write_file(plik_natywy, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_natywy, "//=-=-=-=-=                             Natywy                          =-=-=-=-=//", -1);
		write_file(plik_natywy, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_natywy, "", -1);
		write_file(plik_natywy, "#if defined _MISJE_included", -1);
		write_file(plik_natywy, "	#endinput", -1);
		write_file(plik_natywy, "#endif", -1);
		write_file(plik_natywy, "", -1);
		write_file(plik_natywy, "#define _MISJE_included", -1);
		write_file(plik_natywy, "", -1);
		write_file(plik_natywy, "#pragma library ^"MISJE^"", -1);
		write_file(plik_natywy, "^n^n^n", -1);
		write_file(plik_natywy, "native dd2_get_completemissions(id)               // Pobiera ilosc wykonanych misji gracza", -1);
		write_file(plik_natywy, "native dd2_mission_skip(id)                      // Pomija aktualnie wybrana misje gracza", -1);
	}
	
	if(!file_exists(plik_akty))
	{
		write_file(plik_akty, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_akty, "//=-=-=-=-=                             Akty                            =-=-=-=-=//", -1);
		write_file(plik_akty, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_akty, "//", -1);
		write_file(plik_akty, "// Schemat:", -1);
		write_file(plik_akty, "// ^"Numer aktu (numeruj od 1 w gore)^" ^"Nazwa aktu^"", -1);
		write_file(plik_akty, "//", -1);
		write_file(plik_akty, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_akty, "", -1);
		write_file(plik_akty, "", -1);
		write_file(plik_akty, "^"1^" ^"Akt I^"", -1);
		write_file(plik_akty, "^"2^" ^"Akt II^"", -1);
		write_file(plik_akty, "^"3^" ^"Akt III^"", -1);
	}

	if(!file_exists(plik_misje))
	{
		write_file(plik_misje, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_misje, "//=-=-=-=-=                             Misje                           =-=-=-=-=//", -1);
		write_file(plik_misje, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_misje, "//", -1);
		write_file(plik_misje, "// Schemat:", -1);
		write_file(plik_misje, "// ^"Akt misji^" ^"Nazwa misji^" ^"Typ misji^" ^"Cel misji^" ^"Nagroda misji^" ^"Bron misji^"", -1);
		write_file(plik_misje, "//", -1);
		write_file(plik_misje, "// Wyjasnieie schematu:", -1);
		write_file(plik_misje, "// Akt misji - akt do ktorego misja ma zostac dodana", -1);
		write_file(plik_misje, "// Nazwa misji - nazwa misji", -1);
		write_file(plik_misje, "// Typ misji - typ misji, typy wybieraj z listy ponizej", -1);
		write_file(plik_misje, "// Cel misji - ilosc jaka ma byc celem misji (liczba podstawiana za x w typach misji)", -1);
		write_file(plik_misje, "// Nagroda misji - ilosc nagrody za ukonczenie misji", -1);
		write_file(plik_misje, "// Bron misji - id broni jaka ma byc uzywana podczas misji, dziala tylko z misjami zabij/zadaj", -1);
		write_file(plik_misje, "//", -1);
		write_file(plik_misje, "// Typy misji:", -1);
		write_file(plik_misje, "// 1 - Rozegraj x rund", -1);
		write_file(plik_misje, "// 2 - Zabij x osob", -1);
		write_file(plik_misje, "// 3 - Zabij x osob w glowe", -1);
		write_file(plik_misje, "// 4 - Zadaj x dmg", -1);
		write_file(plik_misje, "// 5 - Zadaj x dmg w glowe", -1);
		write_file(plik_misje, "// 6 - Podloz/Rozbroj C4 x razy", -1);
		write_file(plik_misje, "// 7 - Podnies x amunicji", -1);
		write_file(plik_misje, "// 8 - Przetrwaj x rund bez zgonu", -1);
		write_file(plik_misje, "// 9 - Zabij x osob bez zgonu", -1);
		write_file(plik_misje, "// 10 - Zabij x osob w glowe bez zgonu", -1);
		write_file(plik_misje, "// 11 - Zadaj x dmg bez zgonu", -1);
		write_file(plik_misje, "// 12 - Zadaj x dmg w glowe bez zgonu", -1);
		write_file(plik_misje, "//", -1);
		write_file(plik_misje, "// Bronie:", -1);
		write_file(plik_misje, "// 0 - DOWOLNA BRON", -1);
		write_file(plik_misje, "// 1 - P228", -1);
		write_file(plik_misje, "// 3 - SCOUT", -1);
		write_file(plik_misje, "// 4 - HEGRENADE", -1);
		write_file(plik_misje, "// 5 - XM1014", -1);
		write_file(plik_misje, "// 7 - MAC10", -1);
		write_file(plik_misje, "// 8 - AUG", -1);
		write_file(plik_misje, "// 10 - ELITE", -1);
		write_file(plik_misje, "// 11 - FIVESEVEN", -1);
		write_file(plik_misje, "// 12 - UMP45", -1);
		write_file(plik_misje, "// 13 - SG550", -1);
		write_file(plik_misje, "// 14 - GALIL", -1);
		write_file(plik_misje, "// 15 - FAMAS", -1);
		write_file(plik_misje, "// 16 - USP", -1);
		write_file(plik_misje, "// 17 - GLOCK", -1);
		write_file(plik_misje, "// 18 - AWP", -1);
		write_file(plik_misje, "// 19 - MP5NAVY", -1);
		write_file(plik_misje, "// 20 - M249", -1);
		write_file(plik_misje, "// 21 - M3", -1);
		write_file(plik_misje, "// 22 - M4A1", -1);
		write_file(plik_misje, "// 23 - TMP", -1);
		write_file(plik_misje, "// 24 - G3SG1", -1);
		write_file(plik_misje, "// 26 - DEAGLE", -1);
		write_file(plik_misje, "// 27 - SG552", -1);
		write_file(plik_misje, "// 28 - AK47", -1);
		write_file(plik_misje, "// 29 - KNIFE", -1);
		write_file(plik_misje, "//", -1);
		write_file(plik_misje, "//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=//", -1);
		write_file(plik_misje, "", -1);
		write_file(plik_misje, "", -1);
		write_file(plik_misje, "^"1^" ^"Witamy na serwerze^" ^"1^" ^"5^" ^"30^" ^"0^"", -1);
		write_file(plik_misje, "^"1^" ^"Pierwsza krew^" ^"2^" ^"10^" ^"50^" ^"0^"", -1);
		write_file(plik_misje, "", -1);
		write_file(plik_misje, "^"2^" ^"Szkolenie^" ^"2^" ^"10^" ^"50^" ^"26^"", -1);
		write_file(plik_misje, "^"2^" ^"Hitman^" ^"3^" ^"5^" ^"80^" ^"0^"", -1);
		write_file(plik_misje, "", -1);
		write_file(plik_misje, "^"3^" ^"Staly bywalec^" ^"1^" ^"25^" ^"100^" ^"0^"", -1);
		write_file(plik_misje, "^"3^" ^"Kara smierci^" ^"2^" ^"20^" ^"125^" ^"0^"", -1);
	}
	
	if(file_exists(plik_akty))
	{
		for(new i = 0, n = 1; read_file(plik_akty, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
		{
			if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1))
			{
				ilosc_aktow++;
				n++;
			}
		}
	}
	
	if(file_exists(plik_misje))
	{
		for(new i = 0; read_file(plik_misje, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
		{
			if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1))
			{
				ilosc_misji++;
			}
		}
	}
	
	if(ilosc_aktow == 0 || ilosc_misji == 0)
		set_fail_state("[MISJE] Plugin nie odnalazl wymaganych plikow lub brak aktow badz misji w plikach!");
}

public Menu_Glowne(id)
{
	new menu;
	
	if(top15_dane[id][id_misji_gracza] > 0)
	{	
		for(new i = 0, n = 1; read_file(plik_misje, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
		{
			parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47, DANE[2],47, DANE[3],47, DANE[4],47, DANE[5],47);
			
			if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1) && wybrany_akt[id] == str_to_num(DANE[0]))
			{
				if(n == top15_dane[id][id_misji_gracza])
				{
					new tytul[156], opis_misji_item[64], item1[64];
					format(opis_misji_item,63, opis_misji[str_to_num(DANE[2])], str_to_num(DANE[3]));
					
					if(str_to_num(DANE[5]) > 0)
					{
						format(tytul,155, "\r[\y%s\r]^n^n\wCel misji: \r%s^n\wWymagana bron: \r%s^n\wNagroda: \r%d punktów", DANE[1], opis_misji_item, bronie_misji[str_to_num(DANE[5])], str_to_num(DANE[4]));
						format(item1,63, "\d%s z broni %s, aby ukończyć misję!", opis_misji_item, bronie_misji[str_to_num(DANE[5])]);
					}
					else
					{
						format(tytul,155, "\r[\y%s\r]^n^n\wCel misji: \r%s^n\wNagroda: \r%d punktow", DANE[1], opis_misji_item, str_to_num(DANE[4]));
						format(item1,63, "\d%s, aby ukończyć misję!", opis_misji_item);
					}
					
					menu = menu_create(tytul, "Menu_Glowne_Handle3");
					menu_additem(menu, item1);
					
					top15_dane[id][id_aktu_gracza] = wybrany_akt[id];
					typ_misji_gracza[id] = str_to_num(DANE[2]);
					cel_misji_gracza[id] = str_to_num(DANE[3]);
					nagroda_misji_gracza[id] = str_to_num(DANE[4]);
					bron_misji_gracza[id] = str_to_num(DANE[5]);
					format(opis_misji_status[id],63, opis_misji[str_to_num(DANE[2])], str_to_num(DANE[3]));
					
					i = 9999;
				}
				else n++;
			}
		}
	}
	else
	{
		menu = menu_create("\yMenu Misji", "Menu_Glowne_Handle");
		
		menu_additem(menu, "\wMisje");
		menu_additem(menu, "\wCzym są misję?");
		//menu_additem(menu, "\wTop 15 \d(/mtop15)");
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_display(id, menu);
}

public Menu_Glowne_Callback(id, menu, item)
{
	new nazwa_itemu[64];
			
	for(new i = 0, n = 0; read_file(plik_akty, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
	{
		parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47);
		
		if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1))
		{
			if(n == item)
			{
				i = 9999;

				if(item < top15_dane[id][zaliczone_akty] + 1)
				{
					format(nazwa_itemu,63, "\w%s", DANE[1]);
					menu_item_setname(menu, item, nazwa_itemu)
				}
				else
				{
					format(nazwa_itemu,63, "\d%s", DANE[1]);
					menu_item_setname(menu, item, nazwa_itemu)
					return ITEM_DISABLED;
				}
			}
			else n++;
		}
	}
	
	return ITEM_ENABLED;
}

public Menu_Glowne_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item)
	{
		case 0:
		{
			new menu2 = menu_create("\rMisje", "Menu_Glowne_Handle2");
			new cb2 = menu_makecallback("Menu_Glowne_Callback");
			
			for(new i = 0; read_file(plik_akty, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
			{
				parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47);
				
				if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1))
				{
					if(ilosc_aktow > 0)
						menu_additem(menu2, DANE[1], DANE[0],_,cb2);
				}
			}
		
			menu_setprop(menu2, MPROP_EXITNAME, "Wyjdź");
			menu_setprop(menu2, MPROP_BACKNAME, "Wróć");
			menu_setprop(menu2, MPROP_NEXTNAME, "Dalej");
			menu_display(id, menu2);
		}
		  case 1: czymsamisje(id);
		//case 1: Top15(id);
	}
	
	return PLUGIN_CONTINUE;
}

public czymsamisje(id) {
	show_menu(id, 1023, "\yCzym są misję?:^n^n\
				\wMisję są to określone zadania które trzeba wykonać,^n\
				\waby otrzymać nagrodę.^n\
				Za każdą wykonaną misję dostajemy^n\
				\w+ dodatkowych punktów");
				
	return PLUGIN_HANDLED;
}

public Menu_Glowne_Handle2(id, menu2, item)
{
	if(item == MENU_EXIT || top15_dane[id][id_misji_gracza] > 0)
	{
		menu_destroy(menu2);
		return PLUGIN_CONTINUE;
	}
	
	new DOSTEP, INFO_ITEMU[33], NAZWA_ITEMU[33], cb;
	menu_item_getinfo(menu2, item, DOSTEP, INFO_ITEMU,32, NAZWA_ITEMU,32, cb);
	
	wybrany_akt[id] = str_to_num(INFO_ITEMU);
	Menu_Misje(id);
	
	return PLUGIN_CONTINUE;
}

public Menu_Glowne_Handle3(id, menu, item)
{
	if(item == MENU_EXIT || top15_dane[id][id_misji_gracza] > 0 || item == 0)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public Menu_Misje(id)
{
	new menu, cb;
	new item1[16];
	
	for(new i = 0; read_file(plik_akty, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
	{
		parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47);
		
		if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1) && wybrany_akt[id] == str_to_num(DANE[0]))
		{
			new TYTUL[64];
			format(TYTUL,63, "\r[\y%s\r]", DANE[1]);
			menu = menu_create(TYTUL, "Menu_Misje_Handle");
			cb = menu_makecallback("Menu_Misje_Callback");
		}
	}
	
	for(new i = 0, n = 1; read_file(plik_misje, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
	{
		parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47, DANE[2],47, DANE[3],47, DANE[4],47, DANE[5],47);
		
		if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1) && wybrany_akt[id] == str_to_num(DANE[0]))
		{
			format(item1,15, "%d", n);
			menu_additem(menu, DANE[1], item1,_,cb);
			n++;
		}
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_display(id, menu);
}

public Menu_Misje_Callback(id, menu, item)
{
	new nazwa_itemu[64], opis_misji_item[64];
			
	for(new i = 0, n = 0; read_file(plik_misje, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
	{
		parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47, DANE[2],47, DANE[3],47, DANE[4],47, DANE[5],47);
		
		if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1) && wybrany_akt[id] == str_to_num(DANE[0]))
		{
			if(n == item)
			{
				i = 9999;
				if(top15_dane[id][zaliczone_akty] >= wybrany_akt[id])
				{
					format(nazwa_itemu,63, "\d%s \y[\wzaliczone\y]", DANE[1]);
					menu_item_setname(menu, item, nazwa_itemu)
				}
				else if(item + 1 < top15_dane[id][wykonanych_misji_w_akcie] + 1)
				{
					format(nazwa_itemu,63, "\d%s \y[\wzaliczone\y]", DANE[1]);
					menu_item_setname(menu, item, nazwa_itemu)
				}
				else if(item < top15_dane[id][wykonanych_misji_w_akcie] + 1)
				{
					format(opis_misji_item,63, opis_misji[str_to_num(DANE[2])], str_to_num(DANE[3]));
					format(nazwa_itemu,63, "\w%s \r[\y%s\r]", DANE[1], opis_misji_item);
					menu_item_setname(menu, item, nazwa_itemu)
				}
				else
				{
					format(nazwa_itemu,63, "\d%s [ukryte]", DANE[1]);
					menu_item_setname(menu, item, nazwa_itemu)
					return ITEM_DISABLED;
				}
			}
			else n++;
		}
	}
	
	return ITEM_ENABLED;
}

public Menu_Misje_Handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	else if(top15_dane[id][zaliczone_akty] >= wybrany_akt[id])
	{
		client_print_color(id, id, "^x04[%s]^x03 Wybrana misja jest juz zaliczona!", PREFIX);
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	else if(item + 1 < top15_dane[id][wykonanych_misji_w_akcie] + 1)
	{
		client_print_color(id, id, "^x04[%s]^x03 Wybrana misja jest juz zaliczona!", PREFIX);
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	new DOSTEP, INFO_ITEMU[33], NAZWA_ITEMU[33], cb;
	menu_item_getinfo(menu, item, DOSTEP, INFO_ITEMU,32, NAZWA_ITEMU,32, cb);
	
	top15_dane[id][id_misji_gracza] = str_to_num(INFO_ITEMU);
	
	Menu_Glowne(id);
	
	return PLUGIN_CONTINUE;
}





public Poczatek_Rundy()
{
	for(new id = 1; id <= get_maxplayers(); id++)
	{
		if(typ_misji_gracza[id] == 1 || typ_misji_gracza[id] == 8)
			top15_dane[id][progres_misji_garcza]++;
	}
}

public Zabojstwo()
{
	new zabojca = read_data(1);
	new ofiara = read_data(2);
	new hs = read_data(3);
	
	if(!is_user_alive(zabojca))
		return PLUGIN_CONTINUE;
	
	if(zabojca == ofiara || zabojca == 0)
		return PLUGIN_CONTINUE;
		
	new bron = get_user_weapon(zabojca);
		
	if(bron_misji_gracza[zabojca] > 0)
	{	
		if(typ_misji_gracza[zabojca] == 2 && bron == bron_misji_gracza[zabojca])
			top15_dane[zabojca][progres_misji_garcza]++;
			
		if(typ_misji_gracza[zabojca] == 3 && hs && bron == bron_misji_gracza[zabojca])
			top15_dane[zabojca][progres_misji_garcza]++;
			
		if(typ_misji_gracza[zabojca] == 9 && bron == bron_misji_gracza[zabojca])
			top15_dane[zabojca][progres_misji_garcza]++;
			
		if(typ_misji_gracza[zabojca] == 10 && hs && bron == bron_misji_gracza[zabojca])
			top15_dane[zabojca][progres_misji_garcza]++;
	}
	else
	{		
		if(typ_misji_gracza[zabojca] == 2)
			top15_dane[zabojca][progres_misji_garcza]++;
			
		if(typ_misji_gracza[zabojca] == 3 && hs)
			top15_dane[zabojca][progres_misji_garcza]++;
		
		if(typ_misji_gracza[zabojca] == 9)
			top15_dane[zabojca][progres_misji_garcza]++;
		
		if(typ_misji_gracza[zabojca] == 10 && hs)
			top15_dane[zabojca][progres_misji_garcza]++;
	}
	
	if(typ_misji_gracza[ofiara] == 8 || typ_misji_gracza[ofiara] == 9 || typ_misji_gracza[ofiara] == 10 || typ_misji_gracza[ofiara] == 11 || typ_misji_gracza[ofiara] == 12)
	{
		top15_dane[ofiara][progres_misji_garcza] = 0;
		client_print_color(ofiara, ofiara, "^x04[%s]^x01 Zaliczył%s zgon. Postęp misji został wyzerowany.", PREFIX, get_sextype(ofiara) ? "aś" : "eś");
	}
	
	return PLUGIN_CONTINUE;
}

public Obrazenia(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
		
	new bron = get_user_weapon(attacker);
	new hs = get_pdata_int(victim, 75) == HIT_HEAD;
		
	if(bron_misji_gracza[attacker] > 0)
	{
		if(typ_misji_gracza[attacker] == 4 && bron == bron_misji_gracza[attacker])
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
			
		if(typ_misji_gracza[attacker] == 5 && hs && bron == bron_misji_gracza[attacker])
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
			
		if(typ_misji_gracza[attacker] == 11 && bron == bron_misji_gracza[attacker])
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
			
		if(typ_misji_gracza[attacker] == 12 && hs && bron == bron_misji_gracza[attacker])
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
	}
	else
	{
		if(typ_misji_gracza[attacker] == 4)
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
			
		if(typ_misji_gracza[attacker] == 5 && hs)
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
			
		if(typ_misji_gracza[attacker] == 11)
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
			
		if(typ_misji_gracza[attacker] == 12 && hs)
			top15_dane[attacker][progres_misji_garcza] += floatround(damage, floatround_round);
	}
	
	return HAM_IGNORED;
}

public Przetrwanie(id)
{
	if(top15_dane[id][progres_misji_garcza] >= cel_misji_gracza[id])
		Misja_Ukonczona(id);
}

public bomb_planted(planter)
{
	if(typ_misji_gracza[planter] == 6)
		top15_dane[planter][progres_misji_garcza]++;
}

public bomb_defused(defuser)
{
	if(typ_misji_gracza[defuser] == 6)
		top15_dane[defuser][progres_misji_garcza]++;
}

public Podniesienie_Ammo(id)
{
	new ilosc_naboi = read_data(2);
	
	if(typ_misji_gracza[id] == 7)
		top15_dane[id][progres_misji_garcza] += ilosc_naboi;
}






public Top15(id)
{
	enum _:Top15_INFO
	{
		nVault_Offset,
		Ilosc_Wykonanych_Misji
	}
	
	static Sortuj_Dane[max_graczy_nvault][Top15_INFO];
	
	new ivault_misje, wiersze, ilosc, next_offset, current_offset, klucz[45], dostepni_gracze, next_top15_dane[top15_dane_gracza];
	new motd[1501], pozycja;
	
	nvault_close(vault_misje);
	vault_misje = nvault_open("MISJE");
	
	ivault_misje = nvault_util_open("MISJE");
	
	ilosc = nvault_util_count(ivault_misje);
	
	for(wiersze = 0; wiersze < ilosc && wiersze < max_graczy_nvault; wiersze++)
	{
		next_offset = nvault_util_read_array(ivault_misje, next_offset, klucz, charsmax(klucz), next_top15_dane[top15_dane_gracza:0], sizeof(next_top15_dane));
		
		Sortuj_Dane[wiersze][nVault_Offset] = current_offset;
		Sortuj_Dane[wiersze][Ilosc_Wykonanych_Misji] = next_top15_dane[wykonanych_misji];
		
		current_offset = next_offset;
	}
	
	SortCustom2D(Sortuj_Dane, min(ilosc, max_graczy_nvault), "Top15_Porownaj_Misje");

	pozycja = formatex(motd, charsmax(motd), "<html><body style=^"background-color: black; font-family: sans-serif;^"><br>");
	pozycja += formatex(motd[pozycja], charsmax(motd) - pozycja, "<center><table frame=^"border^" width=^"800^" cellspacing=^"0^" bordercolor=grey style=^"text-align: center; color: green; font-weight: bold;^">");
	pozycja += formatex(motd[pozycja], charsmax(motd) - pozycja, "<tr style=^"font-weight: bold; color: aqua;^"><td style=^"padding: 8px;^">#</td><td>Nick</td><td>Wykonanych Misji</td></tr>");
	
	dostepni_gracze = min(ilosc, 15);
	
	for(wiersze = 0; wiersze < dostepni_gracze; wiersze++)
	{
		current_offset = Sortuj_Dane[wiersze][nVault_Offset];
		
		nvault_util_read_array(ivault_misje, current_offset, klucz, charsmax(klucz), next_top15_dane[top15_dane_gracza:0], sizeof(next_top15_dane));
		
		pozycja += formatex(motd[pozycja], charsmax(motd) - pozycja, "<tr><td style=^"padding: 8px;^">%d</td><td>%s</td><td>%d</td></tr>", (wiersze + 1), next_top15_dane[Nick_Gracza], next_top15_dane[wykonanych_misji]);
	}
	
	nvault_util_close(ivault_misje);
	
	formatex(motd[pozycja], charsmax(motd) - pozycja, "</center></body></html>");
	
	show_motd(id, motd, "Top 15 - Wykonane Misje");
	
	return PLUGIN_HANDLED;
}

public Top15_Porownaj_Misje(element1[], element2[]) 
{ 
    if(element1[1] > element2[1]) 
        return -1; 
    else if(element1[1] < element2[1]) 
        return 1; 
    
    return 0; 
}  
		
public Misja_Ukonczona(id)
{	
	top15_dane[id][wykonanych_misji_w_akcie]++
	top15_dane[id][wykonanych_misji]++;
	
	new i, ilosc_misji_w_akcie;
	for(i = 0, ilosc_misji_w_akcie = 0; read_file(plik_misje, i, LINIA_Z_PLIKU,127, Dlugosc); i++)
	{
		parse(LINIA_Z_PLIKU, DANE[0],47, DANE[1],47, DANE[2],47, DANE[3],47, DANE[4],47, DANE[5],47);
		
		if(containi(LINIA_Z_PLIKU, "//") == -1 && !equal(LINIA_Z_PLIKU, "", 1) && top15_dane[id][id_aktu_gracza] == str_to_num(DANE[0]))
		{
			ilosc_misji_w_akcie++;
		}
	}
	
	if(top15_dane[id][wykonanych_misji_w_akcie] >= ilosc_misji_w_akcie)
	{
		top15_dane[id][zaliczone_akty]++;
		top15_dane[id][wykonanych_misji_w_akcie] = 0;
	}
	
	top15_dane[id][id_misji_gracza] = 0;
	top15_dane[id][progres_misji_garcza] = 0;
	typ_misji_gracza[id] = 0;
	cel_misji_gracza[id] = 1;
	
	client_cmd(id, "mp3 play sound/misc/sounds/mission/mission_passed.mp3");
	
	if(get_messagestatus(id)) {
		if(!get_messagetype(id)) {
			set_hudmessage(70, 255, 0, -1.0, -1.0, 2, 0.05, 3.0, 0.05, 1.0)
			show_hudmessage(id, "Ukończył%s misje!^nOtrzymał%s dodatkowe +%d punktów", get_sextype(id) ? "aś" : "eś", get_sextype(id) ? "aś" : "eś", nagroda_misji_gracza[id]);
		}
		else if(get_messagetype(id)) {
			client_print_color(id, id, "^x03[Misje]^x01 Ukończył%s misje! Otrzymał%s dodatkowe^x04 +%d^x01 punktów!", get_sextype(id) ? "aś" : "eś", get_sextype(id) ? "aś" : "eś", nagroda_misji_gracza[id]);
		}
	}
	
	set_points(id, get_points(id) + nagroda_misji_gracza[id]);
}

public Status(id) {
	new iTarget = id;

	if(!is_user_alive(iTarget)) {
		iTarget = pev(id, pev_iuser2);
	}

	if(!iTarget || task_exists(iTarget+333)) {
		return;
	}
	if(!get_statushud(id)) {
		if(top15_dane[iTarget][id_misji_gracza] > 0) {
			set_hudmessage(108, 246, 250, 0.37, 0.01,0,0.0,2.0,0.0,0.0, -1)
			ShowSyncHudMsg(id, g_Hudi, "^nMisja: %s | Postęp: [%d/%d] | Wykonanych: [%d]", opis_misji_status[iTarget], top15_dane[iTarget][progres_misji_garcza], cel_misji_gracza[iTarget], top15_dane[iTarget][wykonanych_misji]);
		} 
		else
			{
			set_hudmessage(108, 246, 250, 0.43, 0.01,0,0.0,2.0,0.0,0.0, -1)
			ShowSyncHudMsg(id, g_Hudi, "^nMisja: Brak | Wykonanych: [%d]", top15_dane[iTarget][wykonanych_misji]);
		}
	}
}




