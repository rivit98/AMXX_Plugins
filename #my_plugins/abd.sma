#include <amxmodx>
#include <engine>
#include <dhudmessage>

#define IsPlayer(%1) (1<=%1<=maxPlayers)

new Float: Yv[33], Float: Ya[33], maxPlayers;

public plugin_init() 
{
	register_plugin("Pokazywanie dmg", "1.0", "asdf")
	
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")

      maxPlayers = get_maxplayers()
}

public on_damage(vid)
{
	new aid = get_user_attacker(vid)
	new dmg = read_data(2)
	
      if(aid != vid)
      {
            if(get_user_team(aid) != get_user_team(vid))
            {
                  if(is_user_alive(vid))
                  {
                        set_dhudmessage(255, 0, 0, 0.44, Yv[vid], 0, _, 1.7, _, _, false)
                        show_dhudmessage(vid, "%i", dmg)
                  }
                  
                  if(is_user_alive(aid) && IsPlayer(aid))
                  {
                        set_dhudmessage(0, 100, 200, 0.54, Ya[aid], 0, _, 1.7, _, _, false)
                        show_dhudmessage(aid, "%i", dmg)
                  }
                  
                  show_damage(vid, dmg, 0)
                  CheckPosition(vid, 0)

                  if(IsPlayer(aid))
                  {
                        show_damage(aid, dmg, 1)
                        CheckPosition(aid, 1)
                  }
            }
      }
      else
      {
            set_dhudmessage(255, 110, 0, 0.5, 0.6, 0, _, 1.7, _, _, false)
            show_dhudmessage(aid, "%i", dmg)
            show_damage(vid, dmg, 2)
      }

	return PLUGIN_CONTINUE;
}

show_damage(id, dmg, attacker)
{
	static R, G, B
	static Float: Y_Pos, Float: X_Pos
	
	switch(attacker)
	{
            case 0:
            {
                  R = 255
                  G = 0
                  B = 0
                  Y_Pos = Yv[id]
                  X_Pos = 0.44
            }
            case 1:
            {
                  R = 0
                  G = 100
                  B = 200
                  Y_Pos = Ya[id]
                  X_Pos = 0.54
            }
            case 2:
            {
                  R = 255
                  G = 110
                  B = 0
                  Y_Pos = 0.6
                  X_Pos = 0.5
            }
	}
	
	new Players[32], iNum
	get_players(Players, iNum, "bch")
	
	for(new i = 0, Spectator = 0; i < iNum; i++)
	{
		Spectator = Players[i]	

		if(entity_get_int(Spectator, EV_INT_iuser2) == id)
		{
			set_dhudmessage(R, G, B, X_Pos, Y_Pos, 0, _, 1.7, _, _, false)
			show_dhudmessage(Spectator, "%i", dmg)
            }
	}
}

CheckPosition(id, attacker)
{
      switch(attacker)
      {
            case 0:
            {
                  Yv[id] += 0.04
                  
                  if(Yv[id] >= 0.75)
                        Yv[id] = 0.5
            }
            case 1:
            {
                  Ya[id] += 0.04

                  if(Ya[id] >= 0.75)
                        Ya[id] = 0.5
            }
      }
}

public client_putinserver(id)
{
      Yv[id] = 0.5
      Ya[id] = 0.5
}