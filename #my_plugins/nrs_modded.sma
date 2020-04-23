#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <cstrike>
#include <ColorChat>

#define VAULT_EXPIREDAYS 60
#pragma tabsize 0

new stale_haslo[MAX_PLAYERS+1][51], 
ma_haslo[MAX_PLAYERS+1], 
bool:wpisal[MAX_PLAYERS+1], 
haslo_gracza[MAX_PLAYERS+1][51], 
vault, 
nazwa_gracza[33][33];
new fail[33];

#define TASK_KICK 4123

public plugin_init() 
{
      register_plugin("Nick Reservation System", "1.0", "Rivit");

      register_clcmd("StworzHaslo", "ZalozHaslo");
      register_clcmd("Sprawdz", "SprawdzHaslo");
      register_clcmd("say", "BlokadaSay")
      register_clcmd("say_team", "BlokadaSay")

      register_message(get_user_msgid("ShowMenu"), "message_show_menu");
      register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu");

      register_clcmd("jointeam 5", "Zablokuj")

      vault = nvault_open("HaslaGraczy");
}

public BlokadaSay(id)
{
      if(!wpisal[id])
      {
            client_print(id, print_center, "Zeby moc pisac musisz sie zalogowac")
            return PLUGIN_HANDLED
      }
      
      return PLUGIN_CONTINUE
}

public plugin_cfg()
{
      if(vault != INVALID_HANDLE)
            nvault_prune(vault, 0, get_systime()-(86400*VAULT_EXPIREDAYS));
}

public Wpisz(id)
{
	client_cmd(id, "messagemode StworzHaslo");
	ColorChat(id, GREEN, "Teraz wpisz haslo dla siebie")
}

public client_putinserver(id)
{
      get_user_name(id, nazwa_gracza[id], 32)

	Wczytaj(id);
	
	set_task(1.5, "TaskSpytaj", id);
	
	wpisal[id] = false;
	fail[id] = 0
}

public TaskSpytaj(id)
{
	if(ma_haslo[id])
	{
            new tytul[64]
            formatex(tytul, charsmax(tytul), "\yWpisz haslo dla nicku %s^n", nazwa_gracza[id])
            
            new menu = menu_create(tytul, "Handle_MenuWpisz")
            
            menu_additem(menu, "\yWpisz haslo")
            menu_additem(menu, "\wNie znam hasla")
            
            menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
            menu_display(id, menu);
      }
	else
	{
            new menu = menu_create("Rejstracja", "Handle_Stworz")
            
            menu_additem(menu, "Utworz konto")
            
            menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
            menu_display(id, menu);
	}
}

public Handle_Stworz(id, menu, item)
{
      client_cmd(id, "messagemode StworzHaslo");
      client_print(id, print_center, "Wpisz haslo jakie chcesz na ten nick");

      menu_destroy(menu)
}

public Handle_MenuWpisz(id, menu, item)
{
	switch(item)
	{
		case 0: 
		{
                  client_cmd(id, "messagemode Sprawdz");
                  ColorChat(id, GREEN, "Wpisz swoje haslo");
		}
		case 1: KickPlayer(id + TASK_KICK);
	}
	
	menu_destroy(menu)
}

public SprawdzHaslo(id)
{
      if(fail[id] >= 3)
      {
            client_print(id, print_center, "Zbyt duzo prob logowania!");
            set_task(3.0, "KickPlayer", id + TASK_KICK)
            return PLUGIN_HANDLED;
      }

	new arg[51];
	read_argv(1, arg, 50);
	
	if(!strlen(arg))
	{
		client_print(id, print_center, "Nie moze zostac puste!");
		client_cmd(id, "messagemode Sprawdz");
		return PLUGIN_HANDLED;
	}
	
	if(equal(stale_haslo[id], arg))
	{
		wpisal[id] = true;
		menu_chooseteam(id)
	}
	else
	{
            fail[id]++
		client_print(id, print_center, "Zle haslo, sprobuj jeszcze raz!");
		client_cmd(id, "messagemode Sprawdz");
	}
	
	return PLUGIN_HANDLED;
}

public ZalozHaslo(id)
{
	new arg[51];
	read_argv(1, arg, 50);
	
	if(!strlen(arg))
	{
		client_print(id, print_center, "Nie moze zostac puste!");
		client_cmd(id, "messagemode StworzHaslo");
		return PLUGIN_HANDLED;
	}
	else if(strlen(arg) > 10)
	{
            client_print(id, print_center, "Maksymalnie 10 liter");
		client_cmd(id, "messagemode StworzHaslo");
		return PLUGIN_HANDLED;
	}
	
	formatex(haslo_gracza[id], 50, "%s", arg);
	
	PokazMenuStworz(id);
	
	return PLUGIN_HANDLED;
}

public client_disconnect(id)
{
	Zapisz(id);
	
	ma_haslo[id] = 0;
	
	stale_haslo[id][0] = '^0';
	
	wpisal[id] = false;

      remove_task(id + TASK_KICK);
}


public PokazMenuStworz(id)
{
      new tytul[256]
      formatex(tytul, charsmax(tytul), "Haslo dla nicku \r%s to: \r%s^n\wTej operacji \rnie da sie cofnac \wjesli zapomnisz hasla!^n\wPo %i dniach nieobecnosci konto zostanie \rusuniete!", nazwa_gracza[id], haslo_gracza[id], VAULT_EXPIREDAYS)

      new menu = menu_create(tytul, "Handle_MenuStworz")
      
      menu_additem(menu, "\yZaakceptuj haslo")
      menu_additem(menu, "\wWybierz inne haslo")
      
      menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
      menu_display(id, menu);
}

public Handle_MenuStworz(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			stale_haslo[id] = haslo_gracza[id];
			ma_haslo[id] = 1;
			wpisal[id] = true;
			Zapisz(id);
			ColorChat(id, GREEN, "^x04Twoje haslo to ^x03%s", stale_haslo[id])
			ColorChat(id, GREEN, "^x04Twoje haslo to ^x03%s", stale_haslo[id])
			ColorChat(id, GREEN, "^x04Twoje haslo to ^x03%s", stale_haslo[id])
			
                  menu_chooseteam(id)
		}
		case 1:
		{
                  client_cmd(id, "messagemode StworzHaslo");
                  ColorChat(id, GREEN, "Haslo odrzucone! Wpisz nowe.")
		}
	}
	
	menu_destroy(menu)
}


public menu_chooseteam(id)
{	
	if (is_user_connected(id))
	{
            show_motd(id, "addons/amxmodx/data/regulamin.txt", "Regulamin")

            new menu = menu_create("\rWybierz team:^n", "_menu_chooseteam")
            new napis[3][32]
            formatex(napis[0], 31, "\wTT\r [%d]", get_teamplayersnum(1))
            formatex(napis[1], 31, "\wCT\r [%d]", get_teamplayersnum(2))
            formatex(napis[2], 31, "\wObserwatorzy\r [%d]", get_teamplayersnum(3))

		menu_additem(menu, napis[0])
		menu_additem(menu, napis[1])
		menu_additem(menu, napis[2])
		
            menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
            menu_display(id, menu);
	}
}

public _menu_chooseteam(id, menu, item)
{
	switch(item)
	{
		case 0: engclient_cmd(id, "jointeam", "1");
		
		case 1: engclient_cmd(id, "jointeam", "2");
		
		case 2, 6: engclient_cmd(id, "jointeam", "6")
	}
	
	menu_destroy(menu)
	
	return PLUGIN_HANDLED;
}

public Zapisz(id)
{
	if(vault == INVALID_HANDLE) return PLUGIN_CONTINUE;
	
	new vaultkey[40], vaultdata[16];
	
	formatex(vaultkey, charsmax(vaultkey), "%s-acc", nazwa_gracza[id]);
	formatex(vaultdata, charsmax(vaultdata), "%s %d", stale_haslo[id], ma_haslo[id]);
	
	nvault_set(vault, vaultkey, vaultdata);
	
	return PLUGIN_CONTINUE;
}

public Wczytaj(id)
{
	if(vault == INVALID_HANDLE) return PLUGIN_CONTINUE;
	
	new vaultkey[40], vaultdata[16];
	formatex(vaultkey, charsmax(vaultkey), "%s-acc", nazwa_gracza[id]);
	
	nvault_get(vault, vaultkey, vaultdata, charsmax(vaultdata));
	
	new ma[3];
	
	parse(vaultdata, stale_haslo[id], 11, ma, 2);
	ma_haslo[id] = str_to_num(ma);
	
	return PLUGIN_CONTINUE;
}

public KickPlayer(id)
{
	id -= TASK_KICK;
	
	if(ma_haslo[id] && !wpisal[id])
            server_cmd("kick #%d ^"Skoro nie znasz hasla to pewnie nie jest twoj nick^"", get_user_userid(id))
}

public message_vgui_menu()
{
	if (get_msg_arg_int(1) != 2)
		return PLUGIN_CONTINUE
	
	return PLUGIN_HANDLED;
}

public message_show_menu()
{
	static team_select[] = "#Team_Select"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE
	
	return PLUGIN_HANDLED
}

get_teamplayersnum(team)
{
	new playerCnt;
	for(new i = 1; i <= MAX_PLAYERS; ++i)
	{
		if(!is_user_connected(i) || is_user_hltv(i)) continue;
		if(team > -1 && get_user_team(i) != team) continue;
		
		++playerCnt;
	}
	
	return playerCnt;
}

public Zablokuj()
      return PLUGIN_HANDLED