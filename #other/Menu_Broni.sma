#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fun>
 
new g_iMyWeapons[33][2];
new CSW_MAX_AMMO[33] = {-2, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100, -1, -1}
 
#define FLAGA ADMIN_LEVEL_H

public plugin_init()
{
	register_plugin("Menu Broni", "v1.0", "Skull");
 
	RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
}

public client_disconnect(id)
	g_iMyWeapons[id][0] = g_iMyWeapons[id][1] = 0;

public Odrodzenie(id)
{
	if(!is_user_alive(id) || !(get_user_flags(id) & FLAGA)){
		return;
	}
	
	new menu = menu_create("Menu Broni", "Handel_Menu");
	menu_additem(menu, "Wybierz Bronie");
	menu_additem(menu, "Daj Poprzednie bronie");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_display(id, menu);
}

public Handel_Menu(id, menu, item)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
 
	switch(item)
	{
		case MENU_EXIT: return PLUGIN_CONTINUE;
		case 0: return MenuBroni(id);
		case 1:
		{
			new g_szName[24];
			get_weaponname(g_iMyWeapons[id][0], g_szName, 23);
			give_item(id, g_szName);
			get_weaponname(g_iMyWeapons[id][1], g_szName, 23);
			give_item(id, g_szName);
		}
	}
	return PLUGIN_CONTINUE;
}

public MenuBroni(id)
{
	new menu = menu_create("Wybierz Bron:", "Handel_Bronie");
	menu_additem(menu, "M4A1");
	menu_additem(menu, "AK47");
	menu_additem(menu, "AWP");
	menu_additem(menu, "Scout");
	menu_additem(menu, "AUG");
	menu_additem(menu, "Krieg 550");
	menu_additem(menu, "M249");
	menu_additem(menu, "MP5");
	menu_additem(menu, "UMP45");
	menu_additem(menu, "Famas");
	menu_additem(menu, "Galil");
	menu_additem(menu, "M3");
	menu_additem(menu, "XM1014");
	menu_additem(menu, "Mac10");
	menu_additem(menu, "TMP");
	menu_additem(menu, "P90");
	menu_additem(menu, "G3SG1 (autokampa)");
	menu_additem(menu, "Krieg 552 (autokampa)");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
	return menu_display(id, menu);
}

public Handel_Bronie(id, menu, item)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;

	strip_user_weapons(id);
	give_item(id, "weapon_knife");

	switch(item)
	{
		case MENU_EXIT: return PLUGIN_CONTINUE;
		case 0: g_iMyWeapons[id][0] = CSW_M4A1;
		case 1: g_iMyWeapons[id][0] = CSW_AK47;
		case 2: g_iMyWeapons[id][0] = CSW_AWP;
		case 3: g_iMyWeapons[id][0] = CSW_SCOUT;
		case 4: g_iMyWeapons[id][0] = CSW_AUG;
		case 5: g_iMyWeapons[id][0] = CSW_SG550;
		case 6: g_iMyWeapons[id][0] = CSW_M249;
		case 7: g_iMyWeapons[id][0] = CSW_MP5NAVY;
		case 8: g_iMyWeapons[id][0] = CSW_UMP45;
		case 9: g_iMyWeapons[id][0] = CSW_FAMAS;
		case 10: g_iMyWeapons[id][0] = CSW_GALI;
		case 11: g_iMyWeapons[id][0] = CSW_M3;
		case 12: g_iMyWeapons[id][0] = CSW_XM1014;
		case 13: g_iMyWeapons[id][0] = CSW_MAC10;
		case 14: g_iMyWeapons[id][0] = CSW_TMP;
		case 15: g_iMyWeapons[id][0] = CSW_P90;
		case 16: g_iMyWeapons[id][0] = CSW_G3SG1;
		case 17: g_iMyWeapons[id][0] = CSW_SG552;
	}
	new g_szName[24];
	get_weaponname(g_iMyWeapons[id][0], g_szName, 23);
	give_item(id, g_szName);
	return MenuBroniPistolety(id);
}

public MenuBroniPistolety(id)
{
	new menu = menu_create("Wybierz Bron Krotka:", "Handel_BroniePistolety");
	menu_additem(menu, "Deagle");
	menu_additem(menu, "Elite");
	menu_additem(menu, "Usp");
	menu_additem(menu, "Glock18");
	menu_additem(menu, "Fiveseven");
	menu_additem(menu, "P228");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
	return menu_display(id, menu);
}

public Handel_BroniePistolety(id, menu, item)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;

	switch(item)
	{
		case MENU_EXIT: return PLUGIN_CONTINUE;
		case 0: g_iMyWeapons[id][1] = CSW_DEAGLE;
		case 1: g_iMyWeapons[id][1] = CSW_ELITE;
		case 2: g_iMyWeapons[id][1] = CSW_USP;
		case 3: g_iMyWeapons[id][1] = CSW_GLOCK18;
		case 4: g_iMyWeapons[id][1] = CSW_FIVESEVEN;
		case 5: g_iMyWeapons[id][1] = CSW_P228;
	}
	new g_szName[24];
	get_weaponname(g_iMyWeapons[id][1], g_szName, 23);
	give_item(id, g_szName);
	return PLUGIN_CONTINUE;
}
