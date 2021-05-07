#include <amxmodx>
#include <codmod>

new opcja, wybrany;

#pragma tabsize 0

public plugin_init()
{
	register_plugin("COD Admin Menu", "1.5", "RiviT");
	
	register_clcmd("say /codadmin", "AM");
	register_clcmd("ile", "pobierz");
}
	
public AM(id)
{
	if(!(get_user_flags(id) & ADMIN_PASSWORD)) return;

	new menu = menu_create("COD Admin Menu", "AM_handler");
	menu_additem(menu, "Dodaj \rEXP");//1
	menu_additem(menu, "Ustaw \rLVL");//2
	menu_additem(menu, "Daj \rItem");//3
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz")
	menu_display(id, menu);
}

public AM_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	Gracz(id);
	opcja = item+1

      menu_destroy(menu);
}

public Gracz(id)
{
	new menu = menu_create("Wybierz gracza:", "Gracz_handler");
	new szId[3], name[33];
	for(new i=1; i<=32; i++)
	{
		if(!is_user_connected(i)) continue;
		
		num_to_str(i, szId, 2)
		get_user_name(i, name, 32)

		menu_additem(menu, name, szId);
	}
	menu_setprop(menu, MPROP_EXITNAME, "Wroc")
	menu_display(id, menu);
}

public Gracz_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
            AM(id)
		menu_destroy(menu);
		return;
	}
	
	new cb, szId[3]
      menu_item_getinfo(menu, item, cb, szId, 2, _, _, cb)
	
	wybrany = str_to_num(szId);
	
	if(opcja == 3)
		wybierz_perk(id);
	else
		console_cmd(id, "messagemode ile");

      menu_destroy(menu);
}

public pobierz(id)
{
	new text[32]
	read_argv(1, text, 31)
	new ile = str_to_num(text)
	
	if(ile <= 0)
	{
		client_print(id, 3, "Musi byc wieksze od 0!")
		console_cmd(id, "messagemode ile");
		
		return;
	}
	
	dawaj(id, ile)
}
	
public dawaj(id, ile)
{
	new name[33], cvar = get_cvar_num("cod_maxlevel")
	get_user_name(wybrany, name, 32);
	if(opcja == 1)
	{
		new maxexp = cod_get_level_xp(cvar)
		if(ile > maxexp)
			ile = maxexp

		cod_add_user_xp(wybrany, ile);
		client_print(id, print_chat, "Dodales graczowi %s %i EXP'a", name, ile);
	}

	else if(opcja == 2)
	{
		if(ile > cvar)
			ile = cvar

		cod_set_user_xp(wybrany, cod_get_level_xp(ile-1));
		
		client_print(id, print_chat, "Ustawiles graczowi %s %i LVL", name, ile);
	}
}

public wybierz_perk(id)
{
	new menu = menu_create("Wybierz perk:", "wybierz_perk_handler");
	new nazwa_perku[33]
	for(new i = 1; i <= cod_get_perks_num(); i++)
	{
		cod_get_perk_name(i, nazwa_perku, 32)
		menu_additem(menu, nazwa_perku);
	}
	menu_setprop(menu, MPROP_EXITNAME, "Wroc")
	menu_display(id, menu);
}

public wybierz_perk_handler(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		AM(id)
		menu_destroy(menu);
		return;
	}
	
	new nazwa_perku[33], name[33]
	cod_set_user_perk(wybrany, item, -1, 0);
	cod_get_perk_name(item, nazwa_perku, 32);
	get_user_name(wybrany, name, 32)
	
	client_print(id, print_chat, "Dales graczowi %s perk %s", name, nazwa_perku);
}