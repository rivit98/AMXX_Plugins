#include <amxmodx>
#include <fakemeta>
#include <csx>
#include <nvault>
#include <dhudmessage>
#include <rangi>

#pragma tabsize 0

native pojedynek_status();

#define ZADANIE_POKAZ_INFORMACJE 672

/*-----------------KONFIGURACJA-----------------*/

#define SIEC "Cs-Skazani"       // tu zmieniasz np na twoja nazwe sieci lub forum
#define VAULT_EXPIREDAYS 30     // po ilu dniach nieobecnosci na serwerze ma usuwac dane gracza (lvl, staty)

/*----------------------------------------------*/

new vault, SyncHudObj;
new bool:jestMapaAwp;

new cvar_proporcja_poziomu, onlyHs;

new
poziom_gracza[MAX_PLAYERS+1], 
xp_gracza[MAX_PLAYERS+1],
killstreak_gracza[MAX_PLAYERS+1],
he_gracza[MAX_PLAYERS+1],
knife_gracza[MAX_PLAYERS+1],
knifehs_gracza[MAX_PLAYERS+1];

new bool:g_status[MAX_PLAYERS+1];

public plugin_init() 
{
      register_plugin("Rangi", "1.3", "Rivit");

      cvar_proporcja_poziomu = register_cvar("aim_levelratio", "50");        //proprcja poziomu

      register_clcmd("say /exp", "RozpiskaExpa");
      register_clcmd("say /hud", "Hud");
      
      register_clcmd("radio2", "Hud");

      vault = nvault_open("Rangi");

      SyncHudObj = CreateHudSyncObj();
}

public plugin_cfg()
{
      if(vault != INVALID_HANDLE)
            nvault_prune(vault, 0, get_systime() - (86400 * VAULT_EXPIREDAYS));

      onlyHs = get_cvar_num("only_hs")
      
      new mapName[32]
      get_mapname(mapName, charsmax(mapName))
      if(containi(mapName, "awp") != -1)
            jestMapaAwp = true
}

public Hud(id)
{
      if(task_exists(id+ZADANIE_POKAZ_INFORMACJE))
            remove_task(id+ZADANIE_POKAZ_INFORMACJE)
      else
            set_task(1.0, "PokazInformacje", id+ZADANIE_POKAZ_INFORMACJE, _, _, "b");
            
      return PLUGIN_HANDLED
}

public client_death(kid, vid, wid, hitplace, TK)
{
      if(!is_user_connected(kid) && TK && !kid && kid == vid && pojedynek_status()) return

      killstreak_gracza[vid] = 0
      killstreak_gracza[kid]++
      
      new nowy_exp;
      new bool:hs;
      
      if(hitplace == HIT_HEAD)
            hs = true

      nowy_exp += 5
      
      if(wid == CSW_HEGRENADE)
      {
            nowy_exp += 10
            he_gracza[kid]++
      }

      if(onlyHs)
      {
            if(jestMapaAwp)
            {
                  if(wid == CSW_KNIFE)
                  {
                        if(hs)
                        {
                              knifehs_gracza[kid]++
                              nowy_exp += 8
                        }
                        else nowy_exp += 4

                        knife_gracza[kid]++
                  }
                  
                  else if(wid != CSW_AWP && wid != CSW_KNIFE) nowy_exp += 7
            }
            else
            {
                  if(wid == CSW_KNIFE)
                  {
                        if(hs)
                        {
                              knifehs_gracza[kid]++
                              nowy_exp += 14
                        }
                        else nowy_exp += 8

                        knife_gracza[kid]++
                  }
                  
                  else if(wid == CSW_AWP) nowy_exp += 18
            }
      }
      else
      {
            if(jestMapaAwp)
            {
                  if(wid == CSW_KNIFE)
                  {
                        if(hs)
                        {
                              knifehs_gracza[kid]++
                              nowy_exp += 25
                        }
                        else nowy_exp += 12
       
                        knife_gracza[kid]++
                  }
                  
                  if(hs)
                  {
                        if(wid == CSW_AWP) nowy_exp += 9
                        else if(wid != CSW_AWP && wid != CSW_KNIFE) nowy_exp += 7
                  }
            }
            else
            {
                  if(wid == CSW_KNIFE)
                  {
                        if(hs)
                        {
                              knifehs_gracza[kid]++
                              nowy_exp += 40
                        }
                        else nowy_exp += 20

                        knife_gracza[kid]++
                  }
   
                  if(hs)
                  {
                        if(wid == CSW_AWP) nowy_exp += 15

                        else if(wid != CSW_AWP && wid != CSW_KNIFE) nowy_exp += 4
                  }
            }
      }
      
      if(killstreak_gracza[kid] > 4)
            nowy_exp += killstreak_gracza[kid]

      if(g_status[kid]) nowy_exp *= 2

      set_dhudmessage(122, 255, 228, -1.0, 0.68, 0, _, 1.6, _, _, false)
      show_dhudmessage(kid, "+%i", nowy_exp);

      xp_gracza[kid] += nowy_exp;

   
      SprawdzPoziom(kid);
}

public client_connect(id)
{
      poziom_gracza[id] = 0;
      xp_gracza[id] = 0;
      killstreak_gracza[id] = 0;
      knife_gracza[id] = 0;
      knifehs_gracza[id] = 0;
      he_gracza[id] = 0;
      
      set_task(5.0, "client_putinserver", id)
}

public client_putinserver(id)
{
      set_task(1.0, "PokazInformacje", id+ZADANIE_POKAZ_INFORMACJE, _, _, "b");
      WczytajDane(id);
}

public client_authorized(id)
{
      if(get_user_flags(id) & ADMIN_LEVEL_C)
            g_status[id] = true
      else
            g_status[id] = false;
}

public client_disconnect(id)
{
      ZapiszDane(id);
      remove_task(id+ZADANIE_POKAZ_INFORMACJE);   
}

SprawdzPoziom(id, bool:info = true)
{   
      if(!is_user_connected(id)) return;

      new limit_poziomu = sizeof(ranga_name)

      if(poziom_gracza[id] >= limit_poziomu)
      {
            xp_gracza[id] = PobierzDoswiadczeniePoziomu(limit_poziomu-1)
            poziom_gracza[id] = limit_poziomu;
            return;
      }
      
      new bool:zdobyl = false

      while(xp_gracza[id] >= PobierzDoswiadczeniePoziomu(poziom_gracza[id]) && poziom_gracza[id] < limit_poziomu)
      {
            poziom_gracza[id]++;
            zdobyl = true
      }
         
      while(xp_gracza[id] < PobierzDoswiadczeniePoziomu(poziom_gracza[id]-1))
            poziom_gracza[id]--;
            
      if(zdobyl && info)
      {
            set_dhudmessage(122, 255, 228, -1.0, 0.7, 0, _, 7.5, _, _, false)
            show_dhudmessage(id, "Awansowales na stopien:^n%s", ranga_name[poziom_gracza[id]]);
            
            Display_Fade(id, 0, 0, 240)
            
            ZapiszDane(id);
      }
}

public PokazInformacje(id) 
{
      id -= ZADANIE_POKAZ_INFORMACJE;

      if(!is_user_connected(id))
      {
            remove_task(id+ZADANIE_POKAZ_INFORMACJE);
            return PLUGIN_CONTINUE;
      }
   
      new Time[8]
      get_time("%H:%M", Time, 7)
      
      if(!is_user_alive(id))
      {
            new target = pev(id, pev_iuser2);

            if(!target) return PLUGIN_CONTINUE;
   
            new Float:fProcent;
            if(!xp_gracza[target])
                  fProcent = 0.0;
            else if(poziom_gracza[target] >= sizeof(ranga_name))
                  fProcent = 100.0;
            else
            {
                  new ilePotrzebaBylo = PobierzDoswiadczeniePoziomu(poziom_gracza[target]-1);
                  fProcent = (float((xp_gracza[target] - ilePotrzebaBylo)) / float((PobierzDoswiadczeniePoziomu(poziom_gracza[target]) - ilePotrzebaBylo))) * 100.0;
            }

            set_hudmessage(255, 255, 255, 0.01, 0.19, 0, _, 1.0, _, _, 2);
            ShowSyncHudMsg(id, SyncHudObj, "|%s^n|XP: %0.1f%%^n|Ranga: %s^n|Killstreak: %i^n|Status: %s^n|%s", SIEC, fProcent, ranga_name[poziom_gracza[target]], killstreak_gracza[target], g_status[target] ? "VIP" : "Gracz", Time);

            return PLUGIN_CONTINUE;
      }
      
      new Float:fProcent;
      if(!xp_gracza[id])
            fProcent = 0.0;
      else if(poziom_gracza[id] >= sizeof(ranga_name))
            fProcent = 100.0;
      else
      {
            new ilePotrzebaBylo = PobierzDoswiadczeniePoziomu(poziom_gracza[id]-1);
            fProcent = (float((xp_gracza[id] - ilePotrzebaBylo)) / float((PobierzDoswiadczeniePoziomu(poziom_gracza[id]) - ilePotrzebaBylo))) * 100.0;
      }
      
      set_hudmessage(0, 255, 0, 0.01, 0.17, 0, _, 1.0, _, _, 2);
      ShowSyncHudMsg(id, SyncHudObj, "|%s^n|XP: %0.1f%%^n|KS: %i^n|Ranga: %s^n|%s", SIEC, fProcent, killstreak_gracza[id], ranga_name[poziom_gracza[id]], Time);

      return PLUGIN_CONTINUE;
}

public RozpiskaExpa(id)
      show_motd(id, "addons/amxmodx/data/rozpiskaexpa.txt", "TABELA EXPA")

public PobierzDoswiadczeniePoziomu(poziom)
      return power(poziom, 2) * get_pcvar_num(cvar_proporcja_poziomu);

public ZapiszDane(id)
{
      if(vault == INVALID_HANDLE) return PLUGIN_CONTINUE;

      new vaultkey[64], vaultdata[256], name[33];
      get_user_name(id, name, charsmax(name))

      formatex(vaultdata, charsmax(vaultdata), "%i %i %i %i", xp_gracza[id], knife_gracza[id], knifehs_gracza[id], he_gracza[id]);
      formatex(vaultkey, charsmax(vaultkey), "%s-aim", name);

      nvault_set(vault, vaultkey, vaultdata);

      return PLUGIN_CONTINUE;
}

public WczytajDane(id)
{
      if(vault == INVALID_HANDLE) return PLUGIN_CONTINUE;

      new vaultkey[64], vaultdata[256], name[33];
      get_user_name(id, name, charsmax(name))

      formatex(vaultkey, charsmax(vaultkey), "%s-aim", name);

      if(nvault_get(vault, vaultkey, vaultdata, 127))
      {
            new danegracza[4][17];
            parse(vaultdata, danegracza[0], 16, danegracza[1], 16, danegracza[2], 16, danegracza[3], 16);
            
            xp_gracza[id] = str_to_num(danegracza[0]);
            knife_gracza[id] = str_to_num(danegracza[1]);
            knifehs_gracza[id] = str_to_num(danegracza[2]);
            he_gracza[id] = str_to_num(danegracza[3]);
            
            SprawdzPoziom(id, false);
            
            nvault_touch(vault, vaultkey);
      }
      else
      {
            xp_gracza[id] = 0;
            poziom_gracza[id] = 0;
            knife_gracza[id] = 0
            knifehs_gracza[id] = 0
            he_gracza[id] = 0
      }

      return PLUGIN_CONTINUE;
}

public plugin_end()
      nvault_close(vault)

public plugin_natives()
      register_native("rangi_pobierz_dane", "PobierzDane", 1)
      
public PobierzDane(const name[], typ)
{
      param_convert(1)
      new id = get_user_index(name)

      if(is_user_connected(id))
      {
            switch(typ)
            {
                  case 0:
                  {
                        new limit_poziomu = sizeof(ranga_name)
 
                        while(xp_gracza[id] >= PobierzDoswiadczeniePoziomu(poziom_gracza[id]) && poziom_gracza[id] < limit_poziomu)
                              poziom_gracza[id]++;

                        while(xp_gracza[id] < PobierzDoswiadczeniePoziomu(poziom_gracza[id]-1))
                              poziom_gracza[id]--;
  
                        if(poziom_gracza[id] > limit_poziomu)
                              poziom_gracza[id] = limit_poziomu;

                        return poziom_gracza[id];
                  }
                  case 1: return knife_gracza[id];
                  case 2: return knifehs_gracza[id];
                  case 3: return he_gracza[id];
            }
      }
      
      if(vault == INVALID_HANDLE) return PLUGIN_CONTINUE;
   
      new vaultkey[40], vaultdata[64];
   
      formatex(vaultkey, charsmax(vaultkey), "%s-aim", name);

      if(nvault_get(vault, vaultkey, vaultdata, 127))
      {
            new danegracza[4][17];
            parse(vaultdata, danegracza[0], 16, danegracza[1], 16, danegracza[2], 16, danegracza[3], 16);

            switch(typ)
            {
                  case 0:
                  {
                        new limit_poziomu = sizeof(ranga_name)

                        while(xp_gracza[id] >= PobierzDoswiadczeniePoziomu(poziom_gracza[id]) && poziom_gracza[id] < limit_poziomu)
                              poziom_gracza[id]++;
 
                        while(xp_gracza[id] < PobierzDoswiadczeniePoziomu(poziom_gracza[id]-1))
                              poziom_gracza[id]--;

                        if(poziom_gracza[id] > limit_poziomu)
                              poziom_gracza[id] = limit_poziomu;

                        return poziom_gracza[id];
                  }
                  case 1, 2, 3: return str_to_num(danegracza[typ]);
            }
      }
   
      return PLUGIN_CONTINUE;
}

Display_Fade(id, r, g, b)
{
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0, 0, 0}, id);
    write_short((1<<12) * 2);  // Duration of fadeout
    write_short((1<<12) * 2);  // Hold time of color
    write_short(0);    // Fade type
    write_byte (r);         // Red
    write_byte (g);       // Green
    write_byte (b);        // Blue
    write_byte (90);       // Alpha
    message_end();
}