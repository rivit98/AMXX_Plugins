#include <amxmodx>
#include <hamsandwich>
#include <nvault>
#include <cstrike>
#include <fakemeta_util>

#pragma tabsize 0

#define TASKID_EXPLODE 555

#define MAX_PLAYERS 18
#define MR_STANDARD 15
#define MR_DOGRYWKA 3
#define MODELE_ESL

enum
{
      NOZOWKA = 1, 
      PIERWSZA_POLOWA, 
      DRUGA_POLOWA, 
      PIERWSZA_DOGRYWKA, 
      DRUGA_DOGRYWKA, 
      WALKA_NA_NOZE, 
      WALKA_NA_DEAGLE, 
      WALKA_NA_AWP
}

new TTwin, CTwin, iWygranaNozowka, nVault, iEtap, iPlanter;
new bool:bZapis;
new votesCount[2];
new Float:fRoundtime, Float:fC4Timer;
new HamHook:iHam_AddPlayerItem;

new nazwa_gracza[MAX_PLAYERS+1][33], 
fragi_gracza[MAX_PLAYERS+1], 
zgony_gracza[MAX_PLAYERS+1], 
hs_gracza[MAX_PLAYERS+1], 
plant_gracza[MAX_PLAYERS+1], 
defuse_gracza[MAX_PLAYERS+1], 
eksplozje_gracza[MAX_PLAYERS+1], 
he_gracza[MAX_PLAYERS+1];

new const g_regulamin[7][] =
{
      "Kto wygra runde nozowa wybiera team", 
      "Staraj sie nie wychodzic podczas gry!", 
      "NIEDOZWOLONE: tarcza, shotguny, uzi, auto-snajpy, ump, tmp, noktowizor", 
      "Zakaz uzywania cheatow!!!", 
      "Wykonujemy cele mapy! (CT broni BS'ow, TT plantuje pake)", 
      "Jezeli bd mial lagi to wylacz programy korzystajace z neta^n(gg, skype, przegladarka itp)", 
      "Jesli wyjdziesz i wejdziesz na tym samym nicku to^n przywroca Ci sie staty!"
}

public plugin_init() 
{
      register_plugin("MIX plugin", "", "Rivit");

      register_concmd("e_start", "e_start");
      register_concmd("e_losuj", "e_losuj");
      register_concmd("e_mapa", "e_mapa");

	register_clcmd("shield", "block")
	register_clcmd("xm1014", "block")
	register_clcmd("autoshotgun", "block")
	register_clcmd("mac10", "block")
	register_clcmd("ump45", "block")
	register_clcmd("sg550", "block")
	register_clcmd("krieg550", "block")
	register_clcmd("m3", "block")
	register_clcmd("12gauge", "block")
	register_clcmd("tmp", "block")
	register_clcmd("mp", "block")
	register_clcmd("g3sg1", "block")
	register_clcmd("nvgs", "block")

      register_event("SendAudio", "t_win", "a", "2&%!MRAD_terwin") 
      register_event("SendAudio", "ct_win", "a", "2&%!MRAD_ctwin")
      register_event("DeathMsg", "DeathMsg", "a")
      
      register_logevent("BombPlanted", 3, "2=Planted_The_Bomb")
      register_logevent("BombDefused", 3, "2=Defused_The_Bomb")
      register_logevent("KoniecRundy", 2, "0=World triggered", "1=Round_End");
}

public e_start()
{
      if(bZapis) return PLUGIN_HANDLED

      nVault = nvault_open("staty")
      
      iEtap = NOZOWKA

      set_cvar_float("mp_roundtime", 9.00);
      server_cmd("sv_restart 1")
      
      RegisterHam(Ham_Spawn, "player", "OdrodzeniePost", 1);
      iHam_AddPlayerItem = RegisterHam(Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Pre");

      set_task(5.0, "pokaz_zasady", _, _, _, "a", sizeof(g_regulamin))
      
      return PLUGIN_HANDLED
}

public KoniecRundy()
{
      set_task(7.0, "EtapyInformacje")
      remove_task(TASKID_EXPLODE)
}

public EtapyInformacje()
{
      if(iWygranaNozowka)
      {
            pokazVoteMenu()
            return;
	}
      
      if(bZapis)
      {
            new roundnumber = TTwin + CTwin;

            new info[128];
            formatex(info, charsmax(info), "Runda: %i^nTT %i:%i CT^n", roundnumber + 1, TTwin, CTwin)
            
            switch(iEtap)
            {
                  case PIERWSZA_POLOWA:
                  {
                        if(roundnumber == MR_STANDARD)
                        {
                              add(info, charsmax(info), "ZMIANA STRON!")

                              PrzygotujZmiane()
                              
                              set_task(6.0, "restart")
                              
                              iEtap = DRUGA_POLOWA
                        }
                  }
                  case DRUGA_POLOWA:
                  {
                        if(TTwin == MR_STANDARD + 1 || CTwin == MR_STANDARD + 1)
                              ZakonczMixa(info, charsmax(info))
                        
                        if(TTwin == MR_STANDARD && CTwin == MR_STANDARD)
                        {
                              add(info, charsmax(info), "DOGRYWKA po 3 rundy!")
                              
                              set_task(6.0, "restart")
                              
                              iEtap = PIERWSZA_DOGRYWKA
                        }
                  }
                  case PIERWSZA_DOGRYWKA:
                  {
                        if(roundnumber == 2 * MR_STANDARD + MR_DOGRYWKA)
                        {
                              add(info, charsmax(info), "ZMIANA STRON!")
                              
                              PrzygotujZmiane()
                              
                              set_task(6.0, "restart")
                              
                              iEtap = DRUGA_DOGRYWKA
                        }
                  }
                  case DRUGA_DOGRYWKA:
                  {
                        if(roundnumber == 2 * MR_DOGRYWKA + 2 * MR_STANDARD)
                        {
                              if(TTwin != CTwin)
                                    ZakonczMixa(info, charsmax(info))
                              else
                              {
                                    add(info, charsmax(info), "WALKA NA NOZE")
                              
                                    set_task(6.0, "restart")
                                    set_cvar_float("mp_roundtime", 9.00);
                              
                                    iEtap = WALKA_NA_NOZE
                                    
                                    EnableHamForward(iHam_AddPlayerItem);
                              }
                        }
                  }
                  case WALKA_NA_NOZE:
                  {
                        if(roundnumber == 2 * MR_DOGRYWKA + 2 * MR_STANDARD + 1)
                        {
                              add(info, charsmax(info), "WALKA NA DEAGLE")
                              
                              set_task(6.0, "restart")
                              
                              iEtap = WALKA_NA_DEAGLE
                        }
                  }
                  case WALKA_NA_DEAGLE:
                  {
                        if(roundnumber == 2 * MR_DOGRYWKA + 2 * MR_STANDARD + 2)
                        {
                              add(info, charsmax(info), "WALKA NA AWP")
                              
                              set_task(6.0, "restart")
                              
                              iEtap = WALKA_NA_AWP
                        }
                  }

                  case WALKA_NA_AWP:
                  {
                        if(roundnumber == 2 * MR_DOGRYWKA + 2 * MR_STANDARD + 3)
                              ZakonczMixa(info, charsmax(info))
                  }
            }
            
            set_hudmessage(255, 255, 255, -1.0, 0.1, 0, _, 9.0, _, _, 3)
            show_hudmessage(0, info)
	}

	client_cmd(0, "ex_interp 0.01");
	client_cmd(0, "rate 25000");
	client_cmd(0, "cl_updaterate 101");
	client_cmd(0, "cl_cmdrate 101");
	client_cmd(0, "cl_cmdbackup 2");
}

ZakonczMixa(info[], size)
{
      new dane[128];
      formatex(dane, charsmax(dane), "Wygrali %serrorysci!^nWszyscy zamrozeni!^nMozesz spokojnie ogladac staty!", TTwin > CTwin ? "T" : "Antyt")
      add(info, size, dane, charsmax(dane))
      
      bZapis = false

      set_task(8.0, "pokaz_staty_end")
      
      zapisz_do_pliku()
}

public pokaz_staty_end()
{
      new dane[1024] = "<style>body{background:#000;color:#FFB000}</style><body>"

      new temp[256];
      for(new id = 1; id <= MAX_PLAYERS; id++)
      {
            if(!is_user_connected(id)) continue;

            set_pev(id, pev_flags, FL_FROZEN);

            formatex(temp, charsmax(temp), "%s | Frags: %i (%i HS) | Deaths: %i | Plant: %i (%i explode) | Defuse: %i | HE: %i<br>", nazwa_gracza[id], fragi_gracza[id], hs_gracza[id], zgony_gracza[id], plant_gracza[id], eksplozje_gracza[id], defuse_gracza[id], he_gracza[id])
            add(dane, charsmax(dane), temp, charsmax(temp))
      }

      show_motd(0, dane, "STATY")
      
      client_cmd(0, "snapshot");
      client_cmd(0, "screentshot");
}

public OdrodzeniePost(id)
{
      if(!is_user_connected(id)) return;

	#if defined MODELE_ESL
      switch(get_user_team(id))
      {
            case 1: cs_set_user_model(id, "esltt")
            case 2: cs_set_user_model(id, "eslct")
      }
	#endif
	
      if(iEtap == NOZOWKA || iEtap > DRUGA_DOGRYWKA)
      {
            fm_strip_user_weapons(id)
            fm_give_item(id, "weapon_knife")
            cs_set_user_money(id, 0)
      }
      
      switch(iEtap)
      {
            case PIERWSZA_DOGRYWKA, DRUGA_DOGRYWKA:
                  cs_set_user_money(id, 8000)
                  
            case WALKA_NA_DEAGLE:
            {
                  fm_give_item(id, "weapon_deagle")
                  fm_give_item(id, "weapon_hegrenade")
                  cs_set_user_bpammo(id, CSW_DEAGLE, 35)
            }
            
            case WALKA_NA_AWP:
            {
                  fm_give_item(id, "weapon_flashbang")
                  fm_give_item(id, "weapon_flashbang")
                  fm_give_item(id, "weapon_smokegrenade")
                  fm_give_item(id, "weapon_awp")
                  cs_set_user_bpammo(id, CSW_AWP, 30)
            }
      }
    
      if(bZapis)
      {
            fm_set_user_frags(id, fragi_gracza[id])
            cs_set_user_deaths(id, zgony_gracza[id])
      }
}

public Ham_AddPlayerItem_Pre(id, iWeapon)
{
      if((iEtap == NOZOWKA || iEtap > DRUGA_DOGRYWKA) && cs_get_weapon_id(iWeapon) == CSW_C4)
      {
            cs_set_user_plant(id, 0, 0);
            set_pev(id, pev_body, 0);
            SetHamReturnInteger(false);

            return HAM_SUPERCEDE;
      }
      
      return HAM_IGNORED;
}

pokazVoteMenu()
{
      new menu = menu_create("\yWybierz team:^n", "menu_handler")

      menu_additem(menu, "ZMIEN^n")
      menu_additem(menu, "ZOSTAN")

      menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)

      for(new i = 1; i <= MAX_PLAYERS; i++)
      {
            if(is_user_connected(i) && get_user_team(i) == iWygranaNozowka)
            {
                  menu_display(i, menu)
                  set_pev(i, pev_flags, FL_FROZEN);
            }
      }

      set_task(7.0, "podsumujVoteTeam")
}

public menu_handler(id, menu, item)
{
      switch(item)
      {
            case 0: votesCount[0]++
            case 1: votesCount[1]++
      }
}

public podsumujVoteTeam()
{
      if(votesCount[0] > votesCount[1])
      {
            client_print(0, print_chat, "ZMIANA TEAMOW!");

            PrzygotujZmiane()
      }
      else
            client_print(0, print_chat, "TEAMY ZOSTAJA!");

      DisableHamForward(iHam_AddPlayerItem);
 
      set_task(1.9, "restart", _, _, _, "a", 3)            
      set_task(8.0, "pokaz_info")

      set_cvar_float("mp_roundtime", fRoundtime);

      iEtap = PIERWSZA_POLOWA
      iWygranaNozowka = CTwin = TTwin = votesCount[0] = votesCount[1] = 0

      bZapis = true
      
      show_menu(0, 0, "^n")
 
      for(new i = 1; i <= MAX_PLAYERS; i++)
      {
		if(is_user_connected(i))
			set_pev(i, pev_flags, FL_CLIENT);
	}
}

zapisz_do_pliku()
{
      delete_file("addons/amxmodx/staty.txt")
      
      static dane[256];
      for(new id = 1; id <= MAX_PLAYERS; id++)
      {
            if(!is_user_connected(id)) continue;

            formatex(dane, charsmax(dane), "%s | Fragi: %i (%i HS) | Zgony: %i | Plant: %i (%i explode) | Defuse: %i | HE: %i", nazwa_gracza[id], fragi_gracza[id], hs_gracza[id], zgony_gracza[id], plant_gracza[id], eksplozje_gracza[id], defuse_gracza[id], he_gracza[id])

            write_file("addons/amxmodx/staty.txt", dane) 
      }
}

/*----------------------- WYGRANA RUNDA -----------------------*/
public t_win()
{
      if(iEtap == NOZOWKA)
      {
            iWygranaNozowka = 1
            return;
      }
            
      if(bZapis)
            TTwin++
}

public ct_win()
{
      if(iEtap == NOZOWKA)
      {
            iWygranaNozowka = 2
            return;
      }

      if(bZapis)
            CTwin++
}

/*----------------------- STATY -----------------------*/
public DeathMsg()
{
      if(!bZapis) return;

      new kid = read_data(1);
      if(!is_user_connected(kid)) return;
      
      new vid = read_data(2);
      if(get_user_team(kid) != get_user_team(vid))
      {
            if(!kid) return;
		
		fragi_gracza[kid]++

		if(read_data(3))
			hs_gracza[kid]++

		new szWeapon[5];
		read_data(4, szWeapon, charsmax(szWeapon))

		if(szWeapon[3] == 'n')
			he_gracza[kid]++
      }  
      else
            fragi_gracza[kid]--

      zgony_gracza[vid]++
      
      zapisz_do_pliku()
}

public BombDefused()
{
      if(!bZapis) return

	remove_task(TASKID_EXPLODE)
	defuse_gracza[get_loguser_index()]++
	zapisz_do_pliku()
}

public BombPlanted()
{
      if(!bZapis) return

	set_task(fC4Timer, "BombExplode", TASKID_EXPLODE);
	plant_gracza[iPlanter = get_loguser_index()]++
	zapisz_do_pliku()
}

public BombExplode()
{
      if(!bZapis) return
	
	eksplozje_gracza[iPlanter]++
	zapisz_do_pliku()
}

get_loguser_index()
{
    new loguser[80], name[33]
    read_logargv(0, loguser, 79)
    parse_loguser(loguser, name, 32)
 
    return get_user_index(name)
}  

/*----------------------- (DIS)CONNECT STATS -----------------------*/
public client_connect(id)
{
      fragi_gracza[id] = 0;
      zgony_gracza[id] = 0;
      hs_gracza[id] = 0;
      eksplozje_gracza[id] = 0;
      he_gracza[id] = 0;
      plant_gracza[id] = 0;
      defuse_gracza[id] = 0;
      nazwa_gracza[id][0] = '^0'

      get_user_name(id, nazwa_gracza[id], 32);

      if(!bZapis || nVault == INVALID_HANDLE) return;

      new vaultdata[20];

      if(nvault_get(nVault, nazwa_gracza[id], vaultdata, 19))
      {
            new danegracza[7][4];

            parse(vaultdata, danegracza[0], 3, danegracza[1], 3, danegracza[2], 3, danegracza[3], 3, danegracza[4], 3, danegracza[5], 3, danegracza[6], 3)   
 
            fragi_gracza[id] = str_to_num(danegracza[0])
            zgony_gracza[id] = str_to_num(danegracza[1])
            hs_gracza[id] = str_to_num(danegracza[2])
            plant_gracza[id] = str_to_num(danegracza[3])
            defuse_gracza[id] = str_to_num(danegracza[4])
            he_gracza[id] = str_to_num(danegracza[5])
            eksplozje_gracza[id] = str_to_num(danegracza[6])

            client_print(0, 3, "Graczowi %s przywrocono staty.", nazwa_gracza[id])
      }
      else
            client_print(0, 3, "Graczowi %s nie udalo sie przywrocic statow.", nazwa_gracza[id])
}

public client_disconnect(id)
{
	if(!bZapis || nVault == INVALID_HANDLE) return;
 
	new vaultdata[20];
	
	formatex(vaultdata, charsmax(vaultdata), "%i %i %i %i %i %i %i", fragi_gracza[id], zgony_gracza[id], hs_gracza[id], plant_gracza[id], defuse_gracza[id], he_gracza[id], eksplozje_gracza[id])
	
	nvault_set(nVault, nazwa_gracza[id], vaultdata)
}

/*----------------------- ZMIENIANIE TEAMOW -----------------------*/
PrzygotujZmiane()
{
      new ttwin = TTwin;
      TTwin = CTwin;
      CTwin = ttwin;
   
      for(new id = 1; id <= MAX_PLAYERS; id++)
      {
            if(!is_user_connected(id)) continue;

            switch(id)
            {
                  case 1..3: set_task(0.1, "ZamienTeam", id);
                  case 4..6: set_task(0.3, "ZamienTeam", id);
                  case 7..32: set_task(0.6, "ZamienTeam", id);
            }
      }
}

public ZamienTeam(id)
{
      switch(get_user_team(id))
      {
            case 2: cs_set_user_team(id, 1);
            case 1: cs_set_user_team(id, 2);
            default: return;
      }
}

/*----------------------- INFO MESSAGES -----------------------*/
public pokaz_info()
{
      set_hudmessage(255, 255, 255, -1.0, 0.45, 0, _, 6.0, _, _, 1)
      show_hudmessage(0, "START")
}

public pokaz_zasady()
{
      static iRegulaminPos;

      set_hudmessage(255, 255, 255, -1.0, 0.75, 0, _, 4.0, _, _, 2);
      show_hudmessage(0, "%s", g_regulamin[iRegulaminPos++]);
}

public e_losuj()
{
      new i = get_playersnum()
      
      if(i < 4) return PLUGIN_HANDLED;

      new team1 = i / 2, 
      team2 = i - team1, 
      members1, members2, Float:czasTask;

      for(i = 1; i <= MAX_PLAYERS; i++)
      {
            if(!is_user_connected(i)) continue;
            
            new data[3];
            data[1] = i
            czasTask += 0.1
            
            if(random(2))
            {
                  if(members1 < team1)
                  {
                        members1++
                        data[0] = 1
                  }
                  else
                  {
                        members2++
                        data[0] = 2
                  }
                  set_task(czasTask, "przydziel", _, data, 2)
            }
            else
            {
                  if(members2 < team2)
                  {
                        members2++
                        data[0] = 2
                  }
                  else
                  {
                        members1++
                        data[0] = 1
                  }
                  set_task(czasTask, "przydziel", _, data, 2)
            }
      }
      
      server_cmd("sv_restart 1")
	
	return PLUGIN_HANDLED
}

public przydziel(data[])
      cs_set_user_team(data[1], data[0]);

new Array:aMapy;
public e_mapa()
{
	aMapy = ArrayCreate(12)
	ArrayPushString(aMapy, "de_dust2")
	ArrayPushString(aMapy, "de_nuke")
	ArrayPushString(aMapy, "de_tuscan")
	ArrayPushString(aMapy, "de_inferno")
	ArrayPushString(aMapy, "de_train")
	ArrayPushString(aMapy, "de_mirage")
	
	client_print(0, 3, "Losowanie map sie zaczelo! Mapa zostanie wybrana automaptycznie!")
	
	set_task(8.0, "odrzucMape", _, _, _, "a", 5)
	set_task(50.0, "zmianaMapy")
	
	return PLUGIN_HANDLED
}

public odrzucMape()
{
	new temp[12]
	new randomMap = random(ArraySize(aMapy))
	
	ArrayGetString(aMapy, randomMap, temp, 11)
	client_print(0, 3, "Odrzucono: %s", temp)
	ArrayDeleteItem(aMapy, randomMap)
}

public zmianaMapy()
{
	new temp[12]	
	ArrayGetString(aMapy, 0, temp, 11)
	client_print(0, 3, "Wybrana mapa to: %s. Za chwile nastapi zmiana!", temp)
	
	set_task(15.0, "changelevelpre")
}

public changelevelpre()
{
	new temp[12]	
	ArrayGetString(aMapy, 0, temp, 11)
	
	changelevel(temp)
	
	ArrayDestroy(aMapy)
}

public changelevel(mapa[])
	server_cmd("changelevel %s", mapa)

public block(id)
{
	client_print(id, print_chat, "TA BRON JEST ZAKAZANA!")

	return PLUGIN_HANDLED;
}

#if defined MODELE_ESL
public plugin_precache()
{
	precache_model("models/player/esltt/esltt.mdl")
	precache_model("models/player/eslct/eslct.mdl")
}
#endif

public plugin_cfg()
{
      fRoundtime = get_cvar_float("mp_roundtime")
      fC4Timer = get_cvar_float("mp_c4timer")
}

public restart()
      server_cmd("sv_restart 1")