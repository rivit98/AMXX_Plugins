#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>

native antyrusher_off()

#define IsPlayer(%1) (1<=%1<=get_maxplayers())

#define TASKID_CHALLENGING            53254

#define DECIDESECONDS                  6 // czas na odpowiedz
#define KNIFESLASHES                  2 // potarcia o sciane
 
new bool:g_challenging, bool:g_pojedynek, bool:g_noChallengingForAWhile, g_challenger, g_challenged, g_challenges[MAX_PLAYERS+1], weapon[33], CSW_weapon;
new challenger_name[33], challenged_name[33];
new const g_IdWpn[] = {1, 3, 5, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28, 29, 30};
new const maxAmmo[31]={0, 52, 0, 90, 0, 32, 0, 100, 90, 0, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 0, 35, 90, 90, 0, 100};
new mapname[32]

public plugin_init()
{
      register_plugin("Pojedynek", "1.4", "Rivit")

      register_forward(FM_EmitSound, "EmitSound")

      register_event("DeathMsg", "DeathMsg", "a")
      register_event("SendAudio", "KoniecRundy", "ae", "2&%!MRAD_terwin")
      register_event("SendAudio", "KoniecRundy", "ae", "2&%!MRAD_ctwin")
      register_event("SendAudio", "KoniecRundy", "ae", "2&%!MRAD_rounddraw")
      register_event("CurWeapon", "CurWeapon", "be", "1=1", "2!29")
      
      RegisterHam(Ham_Touch, "weaponbox", "HamTouchPre", 0);
      RegisterHam(Ham_Touch, "armoury_entity", "HamTouchPre", 0);
      RegisterHam(Ham_Spawn, "player", "HamSpawnPost", 1)
      
      get_mapname(mapname, 31)
}

public EmitSound(const PIRATE, x, noise[])
{
      if (g_noChallengingForAWhile || g_pojedynek || g_challenging || !IsPlayer(PIRATE) || !is_user_alive(PIRATE) || !equal(noise, "weapons/knife_hitwall1.wav"))
            return FMRES_IGNORED

      new team = get_user_team(PIRATE), otherteam = 0, matchingOpponent = 0
      for (new i = 1; i <= get_maxplayers(); i++)
      {
            if (!is_user_alive(i) || PIRATE == i)
                  continue
                  
            if (get_user_team(i) == team) return FMRES_IGNORED
                  
            else
            {
                  if (++otherteam > 1)
                        return FMRES_IGNORED
                        
                  matchingOpponent = i
            }
      }

      if (!matchingOpponent) return FMRES_IGNORED

      if ((++g_challenges[PIRATE] >= KNIFESLASHES))
      {
            g_challenger = PIRATE
            g_challenged = matchingOpponent
            get_user_name(g_challenger, challenger_name, charsmax(challenger_name))
            get_user_name(g_challenged, challenged_name, charsmax(challenged_name))
            
            Challenge()
            g_challenges[PIRATE] = 0
      }
            
      else
            set_task(2.0, "decreaseChallenges", PIRATE)

      return FMRES_IGNORED
}

public decreaseChallenges(id)
{
      if (--g_challenges[id] < 0)
            g_challenges[id] = 0
}

Challenge()
{
      g_challenging = true

      client_print(g_challenger, print_chat, "Wyzwales przeciwnika na pojedynek! Oczekiwanie na odpowiedz")
      
      new tytul[60];
      formatex(tytul, charsmax(tytul), "%s wyzwal Cie na pojedynek!", challenger_name)
      new menu = menu_create(tytul, "pojedynek_handle")
      new cb = menu_makecallback("ChallengeCB")
      

      menu_additem(menu, "Dawaj na kosy i 100 HP!", "", 0, cb)
      menu_additem(menu, "Dawaj na kosy i 200 HP!", "", 0, cb)
      menu_additem(menu, "Dawaj na losowa bron i 200 HP!")
      menu_additem(menu, "Odpuszczam...")
      
      menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
      
      menu_display(g_challenged, menu)

      set_task(DECIDESECONDS.0, "timed_toolate", TASKID_CHALLENGING)
}

public ChallengeCB(id, menu, item)
{
      if(equali(mapname, "aim_awp_school") || equali(mapname, "aim_cobble_athl")) return ITEM_DISABLED
      
      return ITEM_ENABLED
}

public timed_toolate()
{
      if (g_challenging)
      {
            client_print(0, print_chat, "%s nie odpowiedzial na wyzwanie! Pewnie sie boi!", challenged_name)
            
            CancelAll(1)
            
            show_menu(g_challenged, 0, "^n")
      }
}

public pojedynek_handle(id, menu, item)
{
      switch (item)
      {
            case 0: Akceptacja(0)
            case 1: Akceptacja(1)
            case 2: Akceptacja(2)
            case 3: client_print(0, print_chat, "Nie zgodzil sie! Pewnie sie boi!")
      }
      
      g_challenging = false
      
      remove_task(TASKID_CHALLENGING)
      
      menu_destroy(menu)
}
      
Akceptacja(opcja)
{
      antyrusher_off()
      
      g_pojedynek = true
      
      client_print(0, print_chat, "ZGODZIL SIE CWANIAK!")
      client_cmd(0, "spk pojedynek/pojedynek_start.wav")
      
      new hp = 200;
      
      switch(opcja)
      {
            case 0:
            {
                  CSW_weapon = 29
                  hp = 100
            }
            case 1: CSW_weapon = 29
            case 2: CSW_weapon = g_IdWpn[random(sizeof(g_IdWpn))]

      }
      
      if(is_user_alive(g_challenger) && is_user_alive(g_challenger))
      {
            cs_set_user_armor(g_challenger, 0, CS_ARMOR_NONE)
            cs_set_user_armor(g_challenged, 0, CS_ARMOR_NONE)
            
            get_weaponname(CSW_weapon, weapon, charsmax(weapon))

            fm_give_item(g_challenger, weapon)
            fm_give_item(g_challenged, weapon)
            
            fm_set_user_health(g_challenger, hp)
            fm_set_user_health(g_challenged, hp)
            
            if(CSW_weapon != 29)
            {
                  cs_set_user_bpammo(g_challenger, CSW_weapon, maxAmmo[CSW_weapon])
                  cs_set_user_bpammo(g_challenged, CSW_weapon, maxAmmo[CSW_weapon])
            }

            engclient_cmd(g_challenger, weapon)
            engclient_cmd(g_challenged, weapon)
      }
}

public CurWeapon(id)
{
      if(g_pojedynek && is_user_alive(id) && read_data(2) != CSW_weapon)
      {
            if(user_has_weapon(id, CSW_weapon))
                  engclient_cmd(id, weapon)
            else
                  engclient_cmd(id, "weapon_knife")
      }
}

public KoniecRundy()
{
      if(g_pojedynek)
      {
            CancelAll(0)
            
            if(CSW_weapon != CSW_KNIFE)
            {
                  for(new i = 1; i <= get_maxplayers(); i++)
                  {
                        if(is_user_alive(i))
                              set_task(1.0, "ham_strip_weapon", i)
                  }
            }
      }
      else if (g_challenging)
            CancelAll(0)
}

public ham_strip_weapon(id)
{
      new wEnt;
      while((wEnt = engfunc(EngFunc_FindEntityByString, wEnt, "classname", weapon)) && pev(wEnt, pev_owner) != id) {}
      if(!wEnt) return 0;

      if(get_user_weapon(id) == CSW_weapon) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt);

      if(!ExecuteHamB(Ham_RemovePlayerItem, id, wEnt)) return 0;
      ExecuteHamB(Ham_Item_Kill, wEnt);

      set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<CSW_weapon));

      return 1;
}

CancelAll(switcher)
{
      g_challenging = false
      
      if(!switcher)
      {
            set_task(4.95, "wyzerujplugin")
            g_noChallengingForAWhile = true
      }
      else
            set_task(1.0, "wyzerujplugin")

      remove_task(TASKID_CHALLENGING)
}

public DeathMsg()
{
      if (g_challenging || g_pojedynek)
      {
            CancelAll(0)
            show_menu(g_challenged, 0, "^n")
      }
}

public wyzerujplugin()
{
      g_pojedynek = false
      g_noChallengingForAWhile = false
}

public HamSpawnPost(id)
{
      if(!is_user_alive(id)) return HAM_IGNORED
      
      if(g_challenging)
      {
            CancelAll(1)
            show_menu(g_challenged, 0, "^n")
      }

      if(g_pojedynek)
      {
            cs_set_user_deaths(id, cs_get_user_deaths(id)-1)
            user_silentkill(id)
            client_print(id, print_center, "Trwa pojedynek! Odrodzisz sie w nastepnej rundzie!")
      }
      
      return HAM_IGNORED
}

public HamTouchPre(weapon, id)
{
	if(!g_pojedynek || !IsPlayer(id) || !is_user_alive(id) || !pev_valid(weapon))
		return HAM_IGNORED;

	return HAM_SUPERCEDE;
}

public plugin_precache()
	precache_sound("pojedynek/pojedynek_start.wav")

public plugin_natives()
      register_native("pojedynek_status", "pojedynek_status")
      
public bool:pojedynek_status()
      return g_pojedynek