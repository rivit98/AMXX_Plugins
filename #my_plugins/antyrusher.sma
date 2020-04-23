#include <amxmodx>
#include <amxmisc>

#pragma tabsize 0

#define TASK_ZONE 600743
#define TASK_LOOP 500743
#define TASK_VIEW 400743
#define TASKID_MOZNARUSHOWAC 74328

new bool:map_cors_pre
new origin_granica[6]
new map_cors_edit[6] // 0,1 - X || 2,3 - Y || 4,5 - Z

new zone_incresment = 10
new zone_coords_num
new zone_coords[3][2] = { "X", "Y", "Z"}

new bool:edytowane

new g_origin[3]

new zone_color_aktiv[3] = { 0, 255, 0 }
new zone_color_red[3] = { 255, 0, 0 }
new zone_color_yellow[3] = { 255, 255, 0 }

new ilosc_linii = 5;
new odstep = 35;
new switcher = 0;

new spr_dot;

public plugin_init()
{	
	register_plugin("Antyrusher", "1.2", "Rivit")

	register_clcmd("say /rush", "KreatorStref")
	register_clcmd("IloscLinii", "IloscLinii_h")
	register_clcmd("Odstep", "Odstep_h")

	register_cvar("amx_rush_time", "35.0")		

	register_logevent("Event_StartRound", 2, "1=Round_Start");
      register_logevent("UsunTaski", 2, "0=World triggered", "1=Round_End");

	register_menucmd(register_menuid("Edytuj strefe"), 1023, "edit_zone2")
      
      WczytajStrefy();
}

public plugin_precache()
	spr_dot = precache_model("sprites/dot.spr")
	
public plugin_natives()
      register_native("antyrusher_off", "MoznaRushowac")
 
public Event_StartRound()
{
	if(map_cors_pre)
	{
            remove_task(TASK_LOOP)
            remove_task(TASK_VIEW)
            remove_task(TASKID_MOZNARUSHOWAC)

		set_task(0.2, "checkOrigin", TASK_LOOP, .flags="b")
		set_task(1.6, "RysujGranice", TASK_VIEW, .flags="b")
		
		set_task(get_cvar_float("amx_rush_time"), "MoznaRushowac", TASKID_MOZNARUSHOWAC)
	}
}

public MoznaRushowac()
{
      UsunTaski();
      client_print(0, 3, "********************** RUSH OFF **********************")
}

public UsunTaski()
{
      remove_task(TASK_LOOP)
      remove_task(TASK_VIEW)
      remove_task(TASKID_MOZNARUSHOWAC)
}

public RysujGranice()
{
      DrawLine(origin_granica[1], origin_granica[3-switcher], origin_granica[4], origin_granica[switcher], origin_granica[3], origin_granica[4], zone_color_aktiv)
      DrawLine(origin_granica[1-switcher], origin_granica[2], origin_granica[4], origin_granica[0], origin_granica[2+switcher], origin_granica[4], zone_color_aktiv)

      for(new i = 1; i <= ilosc_linii; ++i)
      {
            DrawLine(origin_granica[1], origin_granica[3-switcher], origin_granica[4]+(i*odstep), origin_granica[switcher], origin_granica[3], origin_granica[4]+(i*odstep), zone_color_aktiv)
            DrawLine(origin_granica[1-switcher], origin_granica[2], origin_granica[4]+(i*odstep), origin_granica[0], origin_granica[2+switcher], origin_granica[4]+(i*odstep), zone_color_aktiv)
      }
}

public Odstep_h(id)
{
      new arg[18];
	read_argv(1, arg, charsmax(arg));
	
	odstep = str_to_num(arg)
      
      if(!is_str_num(arg) || !strlen(arg) || odstep < 30 || odstep > 1000)
      {
            client_cmd(id, "messagemode Odstep")
            
            client_print(id, 3, "Musisz podac liczbe! Ale nie przeginaj!")
            
            odstep = 30
            
            return PLUGIN_HANDLED
      }
      
      edit_zone(id)
      
      return PLUGIN_HANDLED
}

public IloscLinii_h(id)
{
      new arg[18];
	read_argv(1, arg, charsmax(arg));
	
	ilosc_linii = str_to_num(arg)
      
      if(!is_str_num(arg) || !strlen(arg) || ilosc_linii > 20)
      {
            client_cmd(id, "messagemode IloscLinii")

            client_print(id, 3, "Musisz podac liczbe! Ale nie przeginaj!")
            
            ilosc_linii = 5
            
            return PLUGIN_HANDLED
      }
      
      client_cmd(id, "messagemode Odstep")
      
      return PLUGIN_HANDLED
}

public checkOrigin()
{
      static players[32], num
	get_players(players, num)
	for(new i = 0; i < num; i++) 
	{
		if(is_user_alive(players[i]))
		{
                  get_user_origin(players[i], g_origin)
                  if ((origin_granica[0] < g_origin[0] < origin_granica[1]) && (origin_granica[2] < g_origin[1] < origin_granica[3]) && (origin_granica[4] < g_origin[2] < origin_granica[5]))
                  {
                        user_kill(players[i])
                        client_print(players[i], 3, "Zostales zabity za rushowanie!")
                  }
		}
	}
}

public KreatorStref(id)
{
      if(!(get_user_flags(id) & ADMIN_PASSWORD)) return PLUGIN_HANDLED
      if(!is_user_alive(id)) return PLUGIN_HANDLED
      
      remove_task(TASK_LOOP)
      remove_task(TASK_VIEW)
      remove_task(TASKID_MOZNARUSHOWAC)

      map_cors_edit = origin_granica
      
      set_task(0.2, "ar_zone", TASK_ZONE, _, _, "b")

      new menu = menu_create("Kreator stref", "KreatorStrefHandler")
      new menucb = menu_makecallback("KreatorStrefCb")
      
      menu_additem(menu, "Nowa strefa", "", 0, menucb)
      menu_additem(menu, "Usun strefe", "", 0, menucb)
      menu_additem(menu, "Edytuj strefe", "", 0, menucb)
      
      menu_display(id, menu)
      
	edytowane = false
	
	return PLUGIN_HANDLED
} 

public KreatorStrefHandler(id, menu, item) 
{
      if(item == MENU_EXIT)
      {
            remove_task(TASK_ZONE)
            menu_destroy(menu)
            return PLUGIN_HANDLED
      }
      
	switch(item) 
	{ 
		case 0:
		{
			if(!map_cors_pre)
			{
                        new origins[3]
                        get_user_origin(id, origins, 0)
                        map_cors_edit[0]=origins[0]-32
                        map_cors_edit[1]=origins[0]+32
                        map_cors_edit[2]=origins[1]-32
                        map_cors_edit[3]=origins[1]+32
                        map_cors_edit[4]=origins[2]-32
                        map_cors_edit[5]=origins[2]+32
				
				zone_incresment = 10
				
				edit_zone(id)
			}
		}
		case 1:
		{
                  UsunStrefe(id)
                  
                  menu_display(id, menu)   

                  return PLUGIN_CONTINUE
		}
		case 2:
		{	
			zone_incresment = 10
			
			edit_zone(id)
		}
	}
	
      menu_destroy(menu)
      
      return PLUGIN_CONTINUE
}

public KreatorStrefCb(id, menu, item)
{
      if((!item && map_cors_pre) || (item && !map_cors_pre))
            return ITEM_DISABLED
      
      return ITEM_ENABLED
}

public edit_zone(id)
{
	edytowane = true
	
	new text[256] 
	new keys= (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
	formatex(text, 255, "\yEdytuj strefe ^n^n\w1. Wymiar: \y%s ^n\r    2. - | 3. +^n\y    4. - | 5. +^n  ^n\w6. Edytuj ilosc linii (%i) i odstep (%i)^n7. Zmien o: %i ^n8. Switch X/Y (%s)^n\y9. Zapisz strefe^n\r0. Anuluj", zone_coords[zone_coords_num], ilosc_linii, odstep, zone_incresment, switcher ? "ON" : "\dOFF") 	

	show_menu(id, keys, text)
} 

public edit_zone2(id, key)
{ 	
	switch(key)
	{ 
		case 0:
		{	
			if(zone_coords_num<2) zone_coords_num++
			else zone_coords_num=0
		}
		case 1:
		{	
			if((map_cors_edit[zone_coords_num*2]+zone_incresment) < (map_cors_edit[zone_coords_num*2+1]-16))
                        map_cors_edit[zone_coords_num*2] += zone_incresment
		}
		case 2:
		{	
			if((map_cors_edit[zone_coords_num*2]-zone_incresment)>-8000)
                        map_cors_edit[zone_coords_num*2] -= zone_incresment
		}
		case 3:
		{
			if((map_cors_edit[zone_coords_num*2+1]-zone_incresment)>(map_cors_edit[zone_coords_num*2]+16))
                        map_cors_edit[zone_coords_num*2+1] -= zone_incresment
		}
		case 4:
		{	
			if((map_cors_edit[zone_coords_num*2+1]+zone_incresment)<8000)
                        map_cors_edit[zone_coords_num*2+1] += zone_incresment
		}
		case 5:
		{
                  client_cmd(id, "messagemode IloscLinii")
                  return PLUGIN_CONTINUE
		}
		case 6:
		{
			if(zone_incresment < 1000) zone_incresment*=10
			else zone_incresment=1
		}
		case 7: switcher = switcher ? 0 : 1
		case 8:
		{
                  remove_task(TASK_ZONE)

                  origin_granica = map_cors_edit
                  
                  map_cors_pre = true
                  
                  ZapiszStrefy()

			KreatorStref(id)
			return PLUGIN_CONTINUE
		}
		case 9:
		{
                  map_cors_edit[0]=0
                  map_cors_edit[1]=0
                  map_cors_edit[2]=0
                  map_cors_edit[3]=0
                  map_cors_edit[4]=0
                  map_cors_edit[5]=0

                  KreatorStref(id)
            
                  return PLUGIN_CONTINUE
		}
	}
	
	edit_zone(id)
	
	return PLUGIN_HANDLED
}

public ar_zone()
{
	new start[3], stop[3]

	start[0]= map_cors_edit[0]
	start[1]= map_cors_edit[2]
	start[2]= map_cors_edit[4]
	
	stop[0]= map_cors_edit[1]
	stop[1]= map_cors_edit[3]
	stop[2]= map_cors_edit[5]
	
	ShowZoneBox(start, stop)
}

public ShowZoneBox(mins[3], maxs[3])
{
	DrawLine(maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2], zone_color_aktiv)
	DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2], zone_color_aktiv)
	DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2], zone_color_aktiv)

	DrawLine(mins[0], mins[1], mins[2], maxs[0], mins[1], mins[2], zone_color_aktiv)
	DrawLine(mins[0], mins[1], mins[2], mins[0], maxs[1], mins[2], zone_color_aktiv)
	DrawLine(mins[0], mins[1], mins[2], mins[0], mins[1], maxs[2], zone_color_aktiv)

	DrawLine(mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2], zone_color_aktiv)
	DrawLine(mins[0], maxs[1], mins[2], maxs[0], maxs[1], mins[2], zone_color_aktiv)
	DrawLine(maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2], zone_color_aktiv)
	DrawLine(maxs[0], mins[1], mins[2], maxs[0], mins[1], maxs[2], zone_color_aktiv)
	DrawLine(maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2], zone_color_aktiv)
	DrawLine(mins[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2], zone_color_aktiv)
	
	if(edytowane)
	{
            switch(zone_coords_num)
            {
                  case 0:
                  {
                        DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], mins[1], mins[2], zone_color_yellow)
                        DrawLine(maxs[0], maxs[1], mins[2], maxs[0], mins[1], maxs[2], zone_color_yellow)
                        DrawLine(mins[0], maxs[1], maxs[2], mins[0], mins[1], mins[2], zone_color_red)
                        DrawLine(mins[0], maxs[1], mins[2], mins[0], mins[1], maxs[2], zone_color_red)
                  }
                  case 1:
                  {
                        DrawLine(mins[0], mins[1], mins[2], maxs[0], mins[1], maxs[2], zone_color_red)
                        DrawLine(maxs[0], mins[1], mins[2], mins[0], mins[1], maxs[2], zone_color_red)
                        DrawLine(mins[0], maxs[1], mins[2], maxs[0], maxs[1], maxs[2], zone_color_yellow)
                        DrawLine(maxs[0], maxs[1], mins[2], mins[0], maxs[1], maxs[2], zone_color_yellow)
                  }
                  case 2:
                  {
                        DrawLine(maxs[0], maxs[1], maxs[2], mins[0], mins[1], maxs[2], zone_color_yellow)
                        DrawLine(maxs[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2], zone_color_yellow)
                        DrawLine(maxs[0], maxs[1], mins[2], mins[0], mins[1], mins[2], zone_color_red)
                        DrawLine(maxs[0], mins[1], mins[2], mins[0], maxs[1], mins[2], zone_color_red)
                  }
		}
	}
}

public DrawLine(x1, y1, z1, x2, y2, z2, color[3])
{
	new start[3]
	new stop[3]
	
	start[0] = (x1)
	start[1] = (y1)
	start[2] = (z1)
	
	stop[0] = (x2)
	stop[1] = (y2)
	stop[2] = (z2)

	FX_Line(start, stop, color)
}

public FX_Line(start[3], stop[3], color[3])
{
	message_begin(MSG_ALL, SVC_TEMPENTITY) 
	
	write_byte(TE_BEAMPOINTS) 
	
	write_coord(start[0]) 
	write_coord(start[1])
	write_coord(start[2])
	
	write_coord(stop[0])
	write_coord(stop[1])
	write_coord(stop[2])
	
	write_short(spr_dot)
	
	write_byte(1)	// framestart 
	write_byte(1)	// framerate 
	write_byte(4)	// life in 0.1's 
	write_byte(5)	// width
	write_byte(0) 	// noise 
	
	write_byte(color[0])   // r, g, b 
	write_byte(color[1])   // r, g, b 
	write_byte(color[2])   // r, g, b 
	
	write_byte(60)  	// brightness 
	write_byte(0)   	// speed 
	
	message_end() 
}

UsunStrefe(id)
{
      map_cors_edit[0]=0
      map_cors_edit[1]=0
      map_cors_edit[2]=0
      map_cors_edit[3]=0
      map_cors_edit[4]=0
      map_cors_edit[5]=0
 
      origin_granica = map_cors_edit
    
      map_cors_pre = false

      new sciezka[256]
      get_configsdir(sciezka, charsmax(sciezka))
 
      new currentmap[32]
      get_mapname(currentmap, charsmax(currentmap))

      formatex(sciezka, charsmax(sciezka), "%s/antyrusher/%s.cor", sciezka, currentmap)

      delete_file(sciezka)

      client_print(id, 3, "Strefa usunieta pomyslnie")
}

ZapiszStrefy()
{
      new sciezka[256]
      get_configsdir(sciezka, charsmax(sciezka))
      
      formatex(sciezka, charsmax(sciezka), "%s/antyrusher", sciezka)
      
      if(!dir_exists(sciezka)) mkdir(sciezka)
      
      new currentmap[32]
      get_mapname(currentmap, charsmax(currentmap))

      formatex(sciezka, charsmax(sciezka), "%s/%s.cor", sciezka, currentmap)
      
      delete_file(sciezka)

	new dane[64]

      formatex(dane, 63, "%i %i %i %i %i %i %i %i %i", origin_granica[0], origin_granica[1], origin_granica[2], origin_granica[3], origin_granica[4], origin_granica[5], ilosc_linii, odstep, switcher ? 1 : 0)
	
	write_file(sciezka, dane)
	
      client_print(0, print_chat, "Zapisano strefe!")
}

public WczytajStrefy()
{
      new sciezka[256]
      get_configsdir(sciezka, charsmax(sciezka))
      
      new currentmap[32]
      get_mapname(currentmap, charsmax(currentmap))

      formatex(sciezka, charsmax(sciezka), "%s/antyrusher/%s.cor", sciezka, currentmap)
	
	if(file_exists(sciezka))
	{	
		new readdata[64], len

		if(read_file(sciezka, 0, readdata, 63, len))
		{
                  new x11[7], x12[7], y11[7], y12[7], z11[7], z12[7], linie[3], odstepx[7], sw[3]
			parse(readdata, x11, 6, x12, 6, y11, 6, y12, 6, z11, 6, z12, 6, linie, 6, odstepx, 6, sw, 2)

                  origin_granica[0] = str_to_num(x11)
                  origin_granica[1] = str_to_num(x12)
                  origin_granica[2] = str_to_num(y11)
                  origin_granica[3] = str_to_num(y12)
                  origin_granica[4] = str_to_num(z11)
                  origin_granica[5] = str_to_num(z12)
                  ilosc_linii = str_to_num(linie)
                  odstep = str_to_num(odstepx)
                  switcher = str_to_num(sw)

                  map_cors_pre = true

                  return;
		}
	}

      map_cors_pre = false
}