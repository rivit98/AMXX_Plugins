#include <amxmodx>
#include csx
#include fakemeta_util
#include cstrike
#include hamsandwich

#pragma tabsize 0

#define m_fBombState              	96 
#define BombState_PlantedC4       	1<<8
#define BombState_StartDefusing   	1<<0
#define m_fBombDefusing           	232
#define m_flProgressBarStartTime  	605
#define m_flProgressBarEndTime   	606
#define BombStatus_BeingDefusing  	1<<8 
#define SetDefuseCountDown(%0,%1)  ( set_pdata_float( %0, m_flDefuseCountDown, get_gametime() + %1 ) )
#define m_flDefuseCountDown      	99 // Czas w ktorym zostanie rozbrojona paka

#define IsBombPlanted(%0)          (!!(get_pdata_int(%0, m_fBombState) & BombState_PlantedC4))
#define IsBombStartDefusing(%0)    (!!(get_pdata_int(%0, m_fBombState) & BombState_StartDefusing))
#define IsBombDefusing(%0)         (!!(get_pdata_int(%0, m_fBombDefusing) & BombStatus_BeingDefusing))
#define SetProgressBarTime(%0,%1)  ( set_pdata_float( %0, m_flProgressBarStartTime, get_gametime() ), set_pdata_float( %0, m_flProgressBarEndTime, get_gametime() + %1 ) )

new clrs[4][15] = 
{
      "Czarny", 
      "Niebieski", 
      "Zielony", 
      "Zolty"
}

new kabel;
new HandleHookBarTime;
new HamHook:iHamUse
new bool:pakaJestRozbrajana
new iOdliczanie;
new c4index;

#define TASKID_ODLICZANIE 41273

public plugin_init()
{
	register_plugin("Cut The Cable", "1.0", "Rivit");

	RegisterHam(Ham_Spawn, "player", "fwSpawn", 1)
      iHamUse = RegisterHam(Ham_Use, "grenade", "bomb_defusing_pre");
      RegisterHam(Ham_Use, "grenade", "Defuse_Post", 1);

	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0")
}

public NowaRunda()
{
      kabel = -1
      c4index = -1
      EnableHamForward(iHamUse)
      pakaJestRozbrajana = false
}

public fwSpawn(id)
      remove_task(id)

public bomb_planted(id)
{
      if(!is_user_alive(id)) return
      
      kabel = -1
      
      new menu = menu_create("Oznacz kabelek dezaktywujacy pake! Masz 5s", "handle_plant")
      
      for(new i = 0; i < 4; i++)
            menu_additem(menu, clrs[i])
      
      menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
      menu_display(id, menu)
      
      iOdliczanie = 5
      
      set_task(5.0, "wybierz_kabel_random", id)
      set_task(1.0, "odliczanie", TASKID_ODLICZANIE+id, _, _, "a", 5)
}

public handle_plant(id, menu, item)
{
      kabel = item
      remove_task(id)
      remove_task(TASKID_ODLICZANIE+id)
      
      client_print(id, print_center, "Wybrales %s kabel", clrs[item])
      
      menu_destroy(menu)
}

public wybierz_kabel_random(id)
{
      if(id) client_print(id, print_center, "Nie wybrales kabla! Wybrano losowy!")
      
      kabel = random(4)
      
      show_menu(id, 0, "^n")
      remove_task(TASKID_ODLICZANIE+id)
}

public odliczanie(taskid)
      client_print(taskid-TASKID_ODLICZANIE, print_chat, "Pozostalo: %i s", --iOdliczanie)

public bomb_defusing_pre(const grenade, const caller, const activator) //index bytu uzywanego, 
{
      if(IsBombPlanted(grenade) && cs_get_user_team(activator) == CS_TEAM_CT && !IsBombStartDefusing(grenade) && is_user_alive(activator))
      {
            if(pakaJestRozbrajana)
            {
                  client_print(activator, print_center, "Ktos inny rozbraja pake!")
                  return HAM_IGNORED
            }
            
            if(kabel == -1) wybierz_kabel_random(0)
            
            pakaJestRozbrajana = true
            
            new menu = menu_create("Przetnij kabelek, nie masz czasu !", "handle_defuse")
            
            for(new i = 0; i < 4; i++)
                  menu_additem(menu, clrs[i])
            
            menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
            menu_display(activator, menu)
            
            set_task(7.0, "close_menu", activator)
            DisableHamForward(iHamUse)
            
            c4index = grenade
      }
      
      return HAM_SUPERCEDE
}

public Defuse_Post(const grenade, const caller, const activator)
{
	if(HandleHookBarTime)
	{
		SetProgressBarTime(activator, 0);
		SetDefuseCountDown(grenade, 0);
		
		unregister_message(HandleHookBarTime, get_user_msgid("BarTime"));
		HandleHookBarTime = 0;
		
		pakaJestRozbrajana = false
	}
}

public close_menu(id)
      show_menu(id, 0, "^n")

public handle_defuse(id, menu, item)
{
      if(item == kabel)
      {
            HandleHookBarTime = register_message(get_user_msgid("BarTime"), "OnMessageBarTime" );

            ExecuteHamB(Ham_Use, c4index, id, id, 2, 1.0)
      }
      else
            cs_set_c4_explode_time(c4index, get_gametime()+0.1)
}

public bomb_explode()
      show_menu(0, 0, "^n")
	
public Reset_BarTime()
{
	message_begin(MSG_ALL, get_user_msgid("BarTime"))
	write_byte(0)
	write_byte(0)
	message_end()
}

public OnMessageBarTime(msgId, msgDest, msgEntity)
{
	if(IsBombDefusing(msgEntity))
		set_msg_arg_int(1, ARG_SHORT, 0);
}