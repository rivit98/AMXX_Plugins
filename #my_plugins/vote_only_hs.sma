#include <amxmodx> 
#include <ColorChat>
#include <dhudmessage>

new g_wyborow[3];

public plugin_init()  
{ 
	register_plugin("Vote Only HS", "1.0", "Rivit")
	
	set_task(60.0, "start_vote")
	
	register_clcmd("say /votehs", "sprawdz_start_vote");
}

public start_vote() 
{    
      g_wyborow[0] = g_wyborow[1] = g_wyborow[2] = 0

	new menu = menu_create("Only HS:", "start_vote_handler") 
	
	menu_additem(menu, "Tak")
	menu_additem(menu, "Nie")
	menu_additem(menu, "Obojetne")

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

      new team;
      for(new i = 1; i <= get_maxplayers(); i++)
      {
            team = get_user_team(i)
            if(is_user_connected(i) && (team == 1 || team == 2))
                  menu_display(i, menu) 
      }

	set_task(10.0, "finish_vote") 
} 

public start_vote_handler(id, menu, item)
{
      if(0 <= item <= 2)
      {
            ++g_wyborow[item]
            
            ColorChat(0, GREEN, "Wyniki ONLY HS | TAK (^x03%i^x04) | NIE (^x03%i^x04) | OBOJETNIE (^x03%i^x04)", g_wyborow[0], g_wyborow[1], g_wyborow[2])
      }
}

public finish_vote() 
{
	set_hudmessage(0, 255, 255, 0.8, 0.8, 2, 7.0, 6.0, _, _, -1)	
	
	if(g_wyborow[0] > g_wyborow[1]) 
	{ 
		show_hudmessage(0, "Zaczynamy rzeznie!^nOnly HS ON!^nZabic mozna tylko w banie!");
		server_cmd("only_hs 1");
	} 
	else if(g_wyborow[1] > g_wyborow[0]) 
	{ 
		show_hudmessage(0, "Panie nie denerwuj pan!^nOnly HS OFF!");
		server_cmd("only_hs 0");
	} 
	else
	{
		g_wyborow[random(1)]++
		finish_vote()
	}

	show_menu(0, 0, "^n")
}

public sprawdz_start_vote(id)
{
	if(get_user_flags(id) & ADMIN_VOTE)
	{
		set_task(7.0, "start_vote"); 
		ColorChat(0, GREEN, "^x04[Only HS]:^x01 Admin wymusil glosowanie na^x04 ONLY HS.");
	}
	else
            ColorChat(id, BLUE, "Nie masz uprawnien, aby wymusic glosowanie na ONLY HS");
}