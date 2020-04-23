#include <amxmodx>
#include <dhudmessage>

#define PREPARE_HUD() set_hudmessage(42, 255, 42, 0.05, -1.0, 0, _, 6.0, _, _, -1) //rozrabiaka
#define PREPARE_HUD2() set_hudmessage(42, 42, 200, 0.60, -1.0, 0, _, 6.0, _, _, 1) //koniec szalenstwa
#define PREPARE_HUD3() set_hudmessage(230, 20, 0, 0.7, 0.35, 0, _, 4.0, _, _, 4) //poszukiwany
#define PREPARE_HUD4() set_dhudmessage(255, 51, 200, 0.71, Float:ypos, 2, 3.0, 5.0, _, _, false) //killstreak

new levels[8] = {3, 5, 7, 9, 11, 13, 15, 17};

enum typ
{
      ZWYKLE = 0,
      HS,
      ZWYKLE_RUNDA,
      HS_RUNDA
}

new g_fragi[MAX_PLAYERS+1][typ];
new Float:ypos = 0.55

new stksounds[8][] = 
{
      "ultimate_sounds_by_rivit/multikill", 
      "ultimate_sounds_by_rivit/ultrakill", 
      "ultimate_sounds_by_rivit/killingspree", 
      "ultimate_sounds_by_rivit/megakill", 
      "ultimate_sounds_by_rivit/rampage", 
      "ultimate_sounds_by_rivit/godlike", 
      "ultimate_sounds_by_rivit/unstoppable", 
      "ultimate_sounds_by_rivit/monsterkill"
};

new stkmessages[8][] = 
{
      "%s: Multi Kill!", 
      "%s: Ultra Kill!", 
      "%s: Killing Spree!", 
      "%s: Mega Kill!", 
      "%s: Rampage!", 
      "%s: Godlike!", 
      "%s: Unstoppable", 
      "%s: Monster Kill"
};

public plugin_init()
{
      register_plugin("Ultimate Sounds", "1.3", "Rivit")

      register_event("DeathMsg", "DeathMsg", "a", "1!0");

      register_logevent("ResetAllThisRound", 2, "1=Round_Start");  
      register_logevent("Podsumuj", 2, "1=Round_End");
}

public DeathMsg(id)
{
      new kid = read_data(1);
      new vid = read_data(2);
      
      if(!is_user_connected(kid) || kid == vid) return PLUGIN_CONTINUE;
      
      g_fragi[kid][ZWYKLE]++
      g_fragi[kid][ZWYKLE_RUNDA]++
      
      if(read_data(3))
      {
            g_fragi[kid][HS]++
            g_fragi[kid][HS_RUNDA]++
      }
      
      new szKillNick[33];
      get_user_name(kid, szKillNick, charsmax(szKillNick));

      for (new i = 0; i < sizeof(levels); i++)
      {
            if (g_fragi[kid][ZWYKLE] == levels[i])
            {
                  switch(ypos)
                  {
                        case 0.55: ypos = 0.59
                        case 0.59: ypos = 0.55
                  }
                  PREPARE_HUD4();
                  show_dhudmessage(0, stkmessages[i], szKillNick);
                  client_cmd(0, "spk %s", stksounds[i]);
                  
                  break;
            }
      }

      if(g_fragi[kid][ZWYKLE] > 17)
      {
            PREPARE_HUD3();
            show_hudmessage(0, "%s^nposzukiwany za %i zabojstw", szKillNick, g_fragi[kid][ZWYKLE]);
            set_task(1.1, "Poszukiwany",.flags="a",.repeat=3);
      }

      if(g_fragi[vid][ZWYKLE] > 5)
      {
            new szVicNick[33];
            get_user_name(vid, szVicNick, 32);
            PREPARE_HUD2();
            show_hudmessage(0, "Szalenstwo zabijania^n%s^n [%d w tym %d w HS]^n^nzatrzymane przez:^n%s",szVicNick, g_fragi[vid][ZWYKLE], g_fragi[vid][HS], szKillNick);
      }
      
      g_fragi[vid][ZWYKLE] = 0;
      g_fragi[vid][HS] = 0;

      return PLUGIN_CONTINUE;
}

public podsumowanie()
{
      new bool:double=false;
      new id=0;
      for(new i = 1;i <= MAX_PLAYERS; i++)
      {
            if(g_fragi[id][ZWYKLE_RUNDA] == g_fragi[i][ZWYKLE_RUNDA])
            {
                  if(g_fragi[id][HS_RUNDA] == g_fragi[i][HS_RUNDA])
                        double = true;
                        
                        else if(g_fragi[id][HS_RUNDA] < g_fragi[i][HS_RUNDA])
                        {
                              id = i;
                              double = false;
                        }
            }
            else if(g_fragi[id][ZWYKLE_RUNDA] < g_fragi[i][ZWYKLE_RUNDA])
            {
                  id = i;	
                  double = false;
            }
      }

      if(!double && id)
      {
            PREPARE_HUD();
            
            new szNick[33];
            get_user_name(id, szNick, 32);

            show_hudmessage(0, "Najlepszy wynik:^n%s^n[%d w tym %d HS]", szNick, g_fragi[id][ZWYKLE_RUNDA], g_fragi[id][HS_RUNDA]);
      }
}

public Podsumuj()
      set_task(0.4, "podsumowanie");

public client_connect(id)
      reset(id);

reset(id)
{
      g_fragi[id][ZWYKLE] = 0
      g_fragi[id][HS] = 0
      g_fragi[id][ZWYKLE_RUNDA] = 0
      g_fragi[id][HS_RUNDA] = 0
}

resetRound(id)
{
      g_fragi[id][ZWYKLE_RUNDA] = 0
      g_fragi[id][HS_RUNDA] = 0
}

public ResetAllThisRound()
{
      for(new i = 1; i <= MAX_PLAYERS; i++)
            resetRound(i);
}

public Poszukiwany()
	client_cmd(0, "spk ultimate_sounds_by_rivit/klaxon.wav");

public plugin_precache()
{
      precache_sound("ultimate_sounds_by_rivit/monsterkill.wav")
      precache_sound("ultimate_sounds_by_rivit/godlike.wav")
      precache_sound("ultimate_sounds_by_rivit/killingspree.wav")
      precache_sound("ultimate_sounds_by_rivit/multikill.wav")
      precache_sound("ultimate_sounds_by_rivit/ultrakill.wav")
      precache_sound("ultimate_sounds_by_rivit/rampage.wav")
      precache_sound("ultimate_sounds_by_rivit/megakill.wav")
      precache_sound("ultimate_sounds_by_rivit/unstoppable.wav")
      precache_sound("ultimate_sounds_by_rivit/klaxon.wav")
}