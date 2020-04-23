#include <amxmodx> 
#include <colorchat>
#include <amxmisc>

#define LOSOWANIE_W_KTOREJ_RUNDZIE 3
#define FLAGA_VIP ADMIN_LEVEL_H

#define JEDEN 2 //10
#define DWA 3 //15

new wylosowany[2];
new runda;

public plugin_init()
{
	register_plugin("Losowanie vipa", "1.0", "Wielkie Jooool");
	register_logevent("Poczatek_Rundy", 2, "1=Round_Start")  

	set_task(4.0, "UsunVipa", .flags="d")
}

public Poczatek_Rundy()
{   
	runda++
	if(runda == LOSOWANIE_W_KTOREJ_RUNDZIE)
	{
		set_task(3.0, "inf")
		
		new play = get_playersnum();
		if(play >= JEDEN && play < DWA)
		{
			ColorChat(0, GREEN, "[JAILAS] Free VIP for map vote started. Now is more than 10 players. 1 freevip will voted");	
			return PLUGIN_HANDLED
		}
			
		if(play >= DWA)
		{
			ColorChat(0, GREEN, "[JAILAS] Free VIP for map vote started. Now is more than 15 players. 2 freevips will voted");
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public inf()
{
	new play = get_playersnum();

	if(play >= JEDEN && play < DWA)
	{
		Losuj_Vipa(0)
		return PLUGIN_HANDLED
	}
		
	if(play >= DWA)
	{
		Losuj_Vipa(0)
		Losuj_Vipa(1)
		return PLUGIN_HANDLED
	}

	ColorChat(0, GREEN, "[DARMOWY VIP]^x01 Niestety, na serwerze nie bylo 10 osob! Losowanie nie odbedzie sie");
	
	return 1;
}

public client_disconnect(id)
{
	if(id == wylosowany[0] || id == wylosowany[1])
		remove_user_flags(id, FLAGA_VIP)
}

public Losuj_Vipa(ktory) 
{         
	static players[32], count, iPlayer;    
	get_players(players, count, "h");    
	
	new tries;

	while(count)
	{
		iPlayer = players[random(count)];

		if(!is_user_admin(iPlayer) && iPlayer != wylosowany[0] && iPlayer != wylosowany[1])
		{
			new Name[33];
			get_user_name(iPlayer, Name, charsmax(Name))
			set_user_flags(iPlayer, get_user_flags(iPlayer) | FLAGA_VIP);
			ColorChat(0, TEAM_COLOR, "^x04[DARMOWY VIP]^x01 Gratulacje dla gracza ^x03 %s, ktory uzyskal darmowego VIPA na tej mapie!", Name);
			set_hudmessage(255, 125, 0, -1.0, 0.40+(ktory*0.1), 0, 6.0)
			show_hudmessage(0, "%s free vip!", Name)
			
			client_cmd(0, "spk ^"sound/winlos.wav^"");
			//client_cmd(0, "mp3play ^"sound/winlos.mp3^""); //dla mp3
			wylosowany[ktory] = iPlayer;
			tries = 0;
			break;
		}
		else
		{
			if(++tries > 32)
			{
				ColorChat(0, RED, "[FREE VIP]^x01 Nie udo sie wylosowac vipala");
				tries = 0;
				break;
			}
		}
	}
}  

public UsunVipa()
{
	remove_user_flags(wylosowany[0], FLAGA_VIP);
	remove_user_flags(wylosowany[1], FLAGA_VIP);
}

public plugin_precache()
{
	precache_sound("sound/winlos.wav")
	//precache_sound("sound/winlos.mp3")
}