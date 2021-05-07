#include <amxmodx>
#include <codmod>
#include <cstrike>

#define WYTRZYMALOSC_PERKU                // jesli chcesz wylaczyc wytrzymalosc perku to przed ta linijka daj // (WAZNE!! jezeli wylaczysz wytrzymalosc perku to zajrzyj takze do QTM_CodMod.sma i bonusowe_paczki.sma !!)

new Array:IdPerku,
Array:CenaPerku,
Array:IdWystawiajacego;

#if defined WYTRZYMALOSC_PERKU
new Array:WytrzymaloscPerku
#endif

new const prefix[] = "^4[Aukcje]^1"
new size;

public plugin_init()
{
      register_plugin("[CoD] Aukcje", "0.1", "RiviT");

      register_clcmd("say /aukcje", "cmdGlowneMenuAukcje");
      register_clcmd("say /rynek", "cmdGlowneMenuAukcje");
      register_clcmd("WpiszCene", "Wystaw");
      
      IdPerku = ArrayCreate(1, 2)
      CenaPerku = ArrayCreate(1, 2)
      IdWystawiajacego = ArrayCreate(1, 2)
      #if defined WYTRZYMALOSC_PERKU
      WytrzymaloscPerku = ArrayCreate(1, 2)
      #endif

      set_task(120.0, "info")
}

public cmdGlowneMenuAukcje(id)
{
      new menu = menu_create("Aukcje:", "GlowneMenuAukcje_Handler");

      menu_additem(menu, "Zobacz oferty");
      menu_additem(menu, "Wystaw oferte (koszt 100$)");
      menu_additem(menu, "Wycof oferte (koszt 3000 expa)");

      menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

      menu_display(id, menu);
}

public GlowneMenuAukcje_Handler(id, menu, item)
{
      if(item == MENU_EXIT)
      {
            menu_destroy(menu);
            return;
      }

      switch(item)
      {
            case 0: KupOferty(id);
            case 1: WystawOferte(id);
            case 2: WycofOferte(id);
      }

      menu_destroy(menu)
}

public KupOferty(id)
{
      new menu = menu_create("Oferty:", "KupOferty_Handler")
      new callback = menu_makecallback("callback")

      new bool:jestChociazJedna, name_perk[64], info[101];
      for(new i = 0; i < size; i++)
      {
            if(ArrayGetCell(IdPerku, i))
            {
                  cod_get_perk_name(ArrayGetCell(IdPerku, i), name_perk, charsmax(name_perk));
                  
			#if defined WYTRZYMALOSC_PERKU
                  formatex(info, charsmax(info), "%s [Wytrzymalosc: %i] | %i $", name_perk, ArrayGetCell(WytrzymaloscPerku, i), ArrayGetCell(CenaPerku, i));
			#else
                  formatex(info, charsmax(info), "%s | %i $", name_perk, ArrayGetCell(CenaPerku, i));
			#endif
                  if(ArrayGetCell(IdWystawiajacego, i) == id)
                  {
				add(info, charsmax(info), " (Twoje)", 10)
                        menu_additem(menu, info, _, _, callback);
			}
                  else
                        menu_additem(menu, info);

                  jestChociazJedna = true
            }
      }
      
      if(!jestChociazJedna)
      {
            client_print(id, print_center, "Brak ofert!")
            cmdGlowneMenuAukcje(id)
            return;
      }

	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne")
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie")      
      menu_setprop(menu, MPROP_EXITNAME, "Wroc")
      
      menu_display(id, menu)
}

public callback() return ITEM_DISABLED

public KupOferty_Handler(id, menu, idoferty)
{
      if(idoferty == MENU_EXIT)
      {
		cmdGlowneMenuAukcje(id)
            menu_destroy(menu);
            return;
      }

	new cena = ArrayGetCell(CenaPerku, idoferty),
	kasa = cs_get_user_money(id)
      if(kasa >= cena)
      {
		new idWyst = ArrayGetCell(IdWystawiajacego, idoferty),
		idPerk = ArrayGetCell(IdPerku, idoferty)
		
            cod_set_user_perk(id, idPerk, -1, 0)
		#if defined WYTRZYMALOSC_PERKU
            cod_set_perk_durability(id, ArrayGetCell(WytrzymaloscPerku, idoferty))
            #endif
            cs_set_user_money(id, kasa-cena)
            cs_set_user_money(idWyst, min(cs_get_user_money(idWyst)+cena, 16000))

            new name_perk[64];
            cod_get_perk_name(idPerk, name_perk, charsmax(name_perk));
            
            
            client_print_color(idWyst, print_team_red, "Aukcja perku %s zakonczona. Przelano %i $", prefix, name_perk, cena);
            client_print_color(id, print_team_red, "%s Kuplies perk za %i $", prefix, cena);
            
            
            ArrayDeleteItem(IdPerku, idoferty)
            ArrayDeleteItem(CenaPerku, idoferty)
            ArrayDeleteItem(IdWystawiajacego, idoferty)
            
		#if defined WYTRZYMALOSC_PERKU
            ArrayDeleteItem(WytrzymaloscPerku, idoferty)
		#endif
		size--
	}
      else
            client_print_color(id, print_team_red, "%s Masz za malo kasy!", prefix);

      menu_destroy(menu)
}

public WystawOferte(id)
{
      if(cod_get_user_perk(id))
            client_cmd(id, "messagemode WpiszCene");
      else
            client_print_color(id, print_team_red, "%s Nie masz perku!", prefix);
}

public Wystaw(id)
{
      if(!cod_get_user_perk(id) || !is_user_connected(id)) return PLUGIN_CONTINUE

	new kasa = cs_get_user_money(id)
      if(kasa < 100)
      {
            client_print_color(id, print_team_red, "%s Nie masz wystarczajaco kasy!", prefix);
            return PLUGIN_CONTINUE;
      }

	new arg[10];
	read_argv(1, arg, charsmax(arg));
	
	if(!strlen(arg))
	{
		client_cmd(id, "messagemode WpiszCene");
            client_print_color(id, print_team_red, "%s Nie moze zostac puste! Wpisz cene!", prefix);

		return PLUGIN_HANDLED;
	}
	
	new cena = str_to_num(arg);
	if(!is_str_num(arg) || cena > 16000 || cena <= 0)
      {
		client_cmd(id, "messagemode WpiszCene");
            client_print_color(id, print_team_red, "%s Musisz wpisac liczbe (max 16000)!", prefix);

		return PLUGIN_HANDLED;
	}

      ArrayPushCell(IdPerku, cod_get_user_perk(id))
      ArrayPushCell(CenaPerku, cena)
      ArrayPushCell(IdWystawiajacego, id)
      
	#if defined WYTRZYMALOSC_PERKU
      ArrayPushCell(WytrzymaloscPerku, cod_get_perk_durability(id))
	#endif
	
	size++
      cod_set_user_perk(id, 0, 0, 0)
      cs_set_user_money(id, kasa-100)
      
      client_print_color(id, print_team_red, "%s Wystawiles perk za %i$", prefix, cena);

	return PLUGIN_HANDLED;
}

public WycofOferte(id)
{
      new menu = menu_create("Wycof oferte:", "WycofOferte_Handler")
      
      new info[101], name_perk_szIdOferty[64], bool:jestChociazJedna;
      for(new i = 0; i < size; i++)
      {
            if(ArrayGetCell(IdWystawiajacego, i) == id && ArrayGetCell(IdPerku, i))
            {
                  cod_get_perk_name(ArrayGetCell(IdPerku, i), name_perk_szIdOferty, charsmax(name_perk_szIdOferty));
			#if defined WYTRZYMALOSC_PERKU
                  formatex(info, charsmax(info), "%s [Wytrzymalosc: %i] | %i $", name_perk_szIdOferty, ArrayGetCell(WytrzymaloscPerku, i), ArrayGetCell(CenaPerku, i));
			#else
                  formatex(info, charsmax(info), "%s | %i $", name_perk_szIdOferty, ArrayGetCell(CenaPerku, i));
			#endif
                  num_to_str(i, name_perk_szIdOferty, 4);

                  menu_additem(menu, info, name_perk_szIdOferty);
                  
                  jestChociazJedna = true
            }
      }
      
      if(!jestChociazJedna)
      {
		client_print(id, print_center, "Brak Twoich ofert!")
		cmdGlowneMenuAukcje(id)
		return;
      }
      
	menu_setprop(menu, MPROP_EXITNAME, "Wroc")
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne")
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie")

      menu_display(id, menu)
}

public WycofOferte_Handler(id, menu, item)
{
      if(item == MENU_EXIT)
      {
		cmdGlowneMenuAukcje(id)
            menu_destroy(menu);
            return;
      }
      
      new idoferty, idofertyx[5];
      menu_item_getinfo(menu, item, idoferty, idofertyx, 4, _, _, idoferty)

	idoferty = str_to_num(idofertyx)
      if(cod_get_user_xp(id) >= 3000)
      {                  
            new name_perk[64];
            cod_get_perk_name(ArrayGetCell(IdPerku, idoferty), name_perk, charsmax(name_perk));
            client_print_color(id, print_team_red, "%s Wycofales perk %s z aukcji. Pobrano 3000 expa", prefix, name_perk);
            
            cod_add_user_xp(id, -3000)

            ArrayDeleteItem(IdPerku, idoferty)
            ArrayDeleteItem(CenaPerku, idoferty)
            ArrayDeleteItem(IdWystawiajacego, idoferty)
		#if defined WYTRZYMALOSC_PERKU
            ArrayDeleteItem(WytrzymaloscPerku, idoferty)
            #endif
            
            size--
      }
      else
            client_print_color(id, print_team_red, "%s Masz za malo expa! Brakuje Ci %i expa!", prefix, 3000 - cod_get_user_xp(id));

      menu_destroy(menu)
}

public client_disconnect(id)
{
      for(new i = 0; i < size; i++)
      {
            if(ArrayGetCell(IdWystawiajacego, i) == id && ArrayGetCell(IdPerku, i))
            {
                  ArrayDeleteItem(IdPerku, i)
                  ArrayDeleteItem(CenaPerku, i)
                  ArrayDeleteItem(IdWystawiajacego, i)
                  
			#if defined WYTRZYMALOSC_PERKU
                  ArrayDeleteItem(WytrzymaloscPerku, i)
			#endif
                  i--
                  size--
            }
      }
}

public info()
      client_print_color(0, print_team_red, "%s Wejdz na aukcje! Kupuj, sprzedawaj! Komenda /aukcje", prefix);

public plugin_end()
{
      ArrayDestroy(IdPerku)
      ArrayDestroy(CenaPerku)
      ArrayDestroy(IdWystawiajacego)

	#if defined WYTRZYMALOSC_PERKU
      ArrayDestroy(WytrzymaloscPerku)
	#endif
}