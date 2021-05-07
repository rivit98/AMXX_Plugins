#include <amxmodx>
#include <codmod>
#include <cstrike>
#include <fun>

#pragma tabsize 0

new kupione[33];
enum
{
      HE = 1, 
      FB, 
      EXP, 
      STROJ, 
      RENDER, 
      AWP, 
      KROKI
}

new CT_Skins[4][] = {"sas","gsg9","urban","gign"};
new Terro_Skins[4][] = {"arctic","leet","guerilla","terror"};

new const prefix[] = "^4[SKLEP]^3"

/*--------------------------------------------------------*/
new cenyZwykle[][] = {{6000, 4000, 3000}, {16000, 13000, 11000}, {12000, 9000, 7000}, {15000, 13000, 11000}, {5000, 4000, 3000}, {5000, 4200, 3100}, {6300, 5300, 4400}}
new cenyPremium[][] = {{11000, 9000}, {9000, 7000}, {13000, 10000}}
new cenySuperPremium[] = {12000, 9000}
/*--------------------------------------------------------*/

public plugin_init() 
{
	register_plugin("CoD Shop", "1.0", "RiviT");
	
	register_clcmd("say /sklep", "GlowneMenu");
	register_clcmd("say /shop", "GlowneMenu");
	register_clcmd("say /s", "GlowneMenu");

	register_logevent("RoundEnd", 2, "1=Round_End");
	
	register_event("DeathMsg", "Death", "a", "1!0");
}

public GlowneMenu(id)
{
	new menu = menu_create("Sklep^nBonusy jednorazowe lub na runde", "GlowneMenu_Handler");
	new menucallback = menu_makecallback("nowemenucallback");
	
	menu_additem(menu, "Zwykle")
	menu_additem(menu, "Premium", _, _, menucallback)
	menu_additem(menu, "Super Premium", _, _, menucallback)
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_display(id, menu);	
}

public nowemenucallback(id, menu, item)
{
      switch(item)
      {
            case 1: if(!(cod_get_user_status(id) & STATUS_PREMIUM)) return ITEM_DISABLED;
            case 2: if(!(cod_get_user_status(id) & STATUS_SPREMIUM)) return ITEM_DISABLED;
      }
	
	return ITEM_ENABLED;
}

public GlowneMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}

	switch(item)
	{
		case 0: SklepZwykly(id)
            case 1: SklepPremium(id)
            case 2: SklepSuperPremium(id)
      }
      
      menu_destroy(menu)
}

SklepZwykly(id)
{
      new rzeczy[7][30], status = cod_get_user_status(id), menu = 0;
	
	if(status == STATUS_PREMIUM)
		menu = 1
	else if(status > STATUS_PREMIUM)
		menu = 2
	
	formatex(rzeczy[0], 29, "Wyzsze skoki \R\y%i$", cenyZwykle[0][menu])
	formatex(rzeczy[1], 29, "Exp \R\y%i$", cenyZwykle[1][menu])
	formatex(rzeczy[2], 29, "Perk \R\y%i$", cenyZwykle[2][menu])
	formatex(rzeczy[3], 29, "+80 hp \R\y%i$", cenyZwykle[3][menu])
	formatex(rzeczy[4], 29, "200 kevlaru \R\y%i$", cenyZwykle[4][menu])
	formatex(rzeczy[5], 29, "HE \R\y%i$", cenyZwykle[5][menu])
	formatex(rzeczy[6], 29, "2x FB \R\y%i$", cenyZwykle[6][menu])
	
	menu = menu_create("Sklep zwykly", "SklepZwykly_Handler");
	
	menu_additem(menu, rzeczy[0]);
	menu_additem(menu, rzeczy[1]);
	menu_additem(menu, rzeczy[2]);
	menu_additem(menu, rzeczy[3]);
	menu_additem(menu, rzeczy[4]);
	menu_additem(menu, rzeczy[5]);
	menu_additem(menu, rzeczy[6]);

	menu_setprop(menu, MPROP_EXITNAME, "Wroc");
	menu_display(id, menu);
}

public SklepZwykly_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
            GlowneMenu(id)
		menu_destroy(menu);
		return;
	}
	
	if(!is_user_alive(id))
	{
		client_print(id, print_chat, "Musisz byc zywy!", prefix)
		menu_destroy(menu);
		return;
	}
	
	new index = 0, status = cod_get_user_status(id);
	
	if(status == STATUS_PREMIUM)
		index = 1
	else if(status > STATUS_PREMIUM)
		index = 2
	
	new kasa = cs_get_user_money(id);
	if(kasa >= cenyZwykle[item][index])
            cs_set_user_money(id, kasa - cenyZwykle[item][index]);
      else
      {
            client_print_color(id, print_team_default, "%s Masz za malo kasy!", prefix);
            menu_destroy(menu)
            return;
      }
	
	switch(item)
	{
		case 0:
		{
                  set_user_gravity(id, 0.5);
                  client_print_color(id, print_team_default, "%s Skaczesz wyzej!", prefix);
		}
		case 1:
		{
                  index = random_num(10, 600);
                  cod_add_user_xp(id, index)
                  client_print_color(id, print_team_default, "%s Dostales %i EXP'a!", prefix, index);
		}
		case 2:
		{
                  cod_set_user_perk(id, -1, -1, 1);
                  client_print_color(id, print_team_default, "%s Kupiles losowy perk!", prefix);
		}
		case 3:
		{
                  set_user_health(id, get_user_health(id) + 80);
                  client_print_color(id, print_team_default, "%s Kupiles 80 hp!", prefix);
		}
		case 4:
		{
                  cs_set_user_armor(id, get_user_armor(id) + 200, CS_ARMOR_KEVLAR);
                  client_print_color(id, print_team_default, "%s Kupiles 200 kevlaru!", prefix);
		}
		case 5:
		{
                  if(cod_get_bonus_weapons_bitsum(id) & (1<<CSW_HEGRENADE))
                        give_item(id, "weapon_hegrenade")
                  else
                  {
                        cod_give_weapon(id, CSW_HEGRENADE);
                        kupione[id] |= (1<<HE)
                  }
                  client_print_color(id, print_team_default, "%s Kupiles HE!", prefix);
		}
		case 6:
		{
                  if(cod_get_bonus_weapons_bitsum(id) & (1<<CSW_FLASHBANG))
                        give_item(id, "weapon_flashbang")
                  else
                  {
                        cod_give_weapon(id, CSW_FLASHBANG);
                        kupione[id] |= (1<<FB)
                  }

                  cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
                 
                  client_print_color(id, print_team_default, "%s Kupiles 2 FB!", prefix);
		}
	}
	
	menu_destroy(menu);
}

public SklepPremium(id)
{
	new menu = 0, rzeczy[3][30];
	
	if(cod_get_user_status(id) > STATUS_PREMIUM)
		menu = 1
	
	formatex(rzeczy[0], 29, "50 widocznosci \R\y%i$", cenyPremium[0][menu])
	formatex(rzeczy[1], 29, "AWP z 10 ammo \R\y%i$", cenyPremium[1][menu])
	formatex(rzeczy[2], 29, "Ciche kroki \R\y%i$", cenyPremium[2][menu])
	
	menu = menu_create("Sklep Premium", "SklepPremium_Handler");
	
	menu_additem(menu, rzeczy[0]);
	menu_additem(menu, rzeczy[1]);
	menu_additem(menu, rzeczy[2]);

	menu_setprop(menu, MPROP_EXITNAME, "Wroc");
	menu_display(id, menu);
}

public SklepPremium_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
            GlowneMenu(id)
		menu_destroy(menu);
		return;
	}
	
	if(!is_user_alive(id))
	{
		client_print_color(id, print_team_default, "%s Musisz byc zywy!", prefix)
		menu_destroy(menu);
		return;
	}
	
	new index = 0;
	
	if(cod_get_user_status(id) > STATUS_PREMIUM)
		index = 1

      new kasa = cs_get_user_money(id);
	if(kasa >= cenyPremium[item][index])
            cs_set_user_money(id, kasa - cenyPremium[item][index]);
      else
      {
            client_print_color(id, print_team_default, "%s Masz za malo kasy!", prefix);
            menu_destroy(menu)
            return;
      }
	
	switch(item)
	{
		case 0:
		{
                  kupione[id] |= (1<<RENDER)
                  cod_set_user_rendering(id, 50)
                  client_print_color(id, print_team_default, "%s Masz 50 widocznosci!", prefix);
		}
		case 1:
		{
                  cod_give_weapon(id, CSW_AWP);
                  cs_set_user_bpammo(id, CSW_AWP, 0)
                  kupione[id] |= (1<<AWP)
                  client_print_color(id, print_team_default, "%s Kupiles AWP z 10 ammo!", prefix);
		}
		case 2:
		{
                  set_user_footsteps(id, 1)
                  kupione[id] |= (1<<KROKI)
                  client_print_color(id, print_team_default, "%s Kupiles ciche kroki!", prefix);
		}
	}
	
	menu_destroy(menu)
}

public SklepSuperPremium(id)
{
	new menu = menu_create("Sklep Super Premium", "SklepSuperPremium_Handler");
	new rzeczy[2][35];
	
	formatex(rzeczy[0], 34, "Stroj wroga \R\y%i$", cenySuperPremium[0])
	formatex(rzeczy[1], 34, "5x exp za frag \R\y%i$", cenySuperPremium[1])
	
	menu_additem(menu, rzeczy[0]);
	menu_additem(menu, rzeczy[1]);

	menu_setprop(menu, MPROP_EXITNAME, "Wroc");
	menu_display(id, menu);
}

public SklepSuperPremium_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
            GlowneMenu(id)
		menu_destroy(menu);
		return;
	}
	
	if(!is_user_alive(id))
	{
		client_print(id, print_chat, "Musisz byc zywy!", prefix)
            menu_destroy(menu);
		return;
	}
	
      new kasa = cs_get_user_money(id);
	if(kasa >= cenySuperPremium[item])
            cs_set_user_money(id, kasa-cenySuperPremium[item]);
      else
      {
            client_print_color(id, print_team_default, "%s Masz za malo kasy!", prefix);
            menu_destroy(menu)
            return;
      }
	
	switch(item)
	{
		case 0:
		{
                  cs_set_user_model(id, (get_user_team(id) == 1)? CT_Skins[random_num(0, 3)]: Terro_Skins[random_num(0, 3)]);
                  kupione[id] |= (1<<STROJ)
                  client_print_color(id, print_team_default, "%s Masz stroj wroga!", prefix);
		}
		
		case 1:
		{
                  kupione[id] |= (1<<EXP)
                  client_print_color(id, print_team_default, "%s Masz 5x exp za frag! Milego fragowania :)", prefix);
		}
	}
	
	menu_destroy(menu)
}

public client_disconnect(id)
      kupione[id] = 0

public RoundEnd()
{
      for(new id = 1; id <= get_maxplayers(); ++id)
      {
            if(!kupione[id] || !is_user_connected(id)) continue;

		if(kupione[id] & (1<<HE))
			cod_take_weapon(id, CSW_HEGRENADE);
		
		if(kupione[id] & (1<<FB))
		{
			cod_take_weapon(id, CSW_FLASHBANG);
			cod_take_weapon(id, CSW_FLASHBANG);
		}

		if(kupione[id] & (1<<AWP))
			cod_take_weapon(id, CSW_AWP)
		
		if(kupione[id] & (1<<RENDER))
                  cod_remove_user_rendering(id)
		
		if(kupione[id] & (1<<KROKI))   
			set_user_footsteps(id, 0)
		
		if(kupione[id] & (1<<STROJ))
			cs_reset_user_model(id);

            kupione[id] = 0
	}
}

public Death()
{
	new kid = read_data(1);
	
      if(!is_user_connected(kid)) return;
	
      if(kupione[kid] & (1<<EXP))
            cod_add_user_xp(kid, get_cvar_num("cod_killxp")*4); 
}