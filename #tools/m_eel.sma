#include <amxmodx>
#include <amxmisc>
#include <engine>

#define KeysBasic_menu (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9) // Keys: 1234567890
#define KeysGet_ent (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<8) // Keys: 12345679
#define KeysEnt_search (1<<0)|(1<<1)|(1<<2)|(1<<6)|(1<<8) // Keys: 12379
#define KeysDetect (1<<6)|(1<<8)|(1<<9) // Keys: 790
#define Keysmenu_90 (1<<8)|(1<<9) // Keys: 90
#define Keysmenu_string (1<<9) // Keys: 0

#define NEXT_THINK 0.1

new sint[37][]=
{
	"gamestate","oldbuttons","groupinfo","iuser1","iuser2","iuser3","iuser4","weaponanim",
	"pushmsec","bInDuck","flTimeStepSound","flSwimTime","flDuckTime","iStepLeft",
	"movetype","solid","skin","body","effects","light_level","sequence","gaitsequence",
	"modelindex","playerclass","waterlevel","watertype","spawnflags","flags","colormap",
	"team","fixangle","weapons","rendermode","renderfx","button","impulse","deadflag"
}

new sfloat[37][] = {
	"impacttime","starttime","idealpitch","pitch_speed","ideal_yaw","yaw_speed","ltime",
	"nextthink","gravity","friction","frame","animtime","framerate","health","frags",
	"takedamage","max_health","teleport_time","armortype","armorvalue","dmg_take","dmg_save",
	"dmg","dmgtime","speed","air_finished","pain_finished","radsuit_finished","scale",
	"renderamt","maxspeed","fov","flFallVelocity","fuser1","fuser2","fuser3","fuser4"
}

new svec[23][] = {
	"origin","oldorigin","velocity","basevelocity","clbasevelocity","movedir","angles",
	"avelocity","punchangle","v_angle","endpos","startpos","absmin","absmax",
	"mins","maxs","size","rendercolor","view_ofs","vuser1","vuser2","vuser3","vuser4"
}

new sedict[11][] = {
	"chain","dmg_inflictor","enemy","aiment","owner","groundentity",
	"pContainingEntity","euser1","euser2","euser3","euser4"
}

new sstring[13][] = {
	"classname","globalname","model","target","targetname","netname",
	"message","noise","noise1","noise2","noise3","viewmodel","weaponmodel"
}


new sbyte[6][] = {
	"controller1","controller2","controller3","controller4","blending1","blending2"
}

new ignore[128][32]//={"spark_shower"}
new ignore_num = 0

new ignors[128]
new ignors_num=0

new class_list[128][32]//={"spark_shower"}
new class_list_num = 0

new current_class_num=0
new current_ent=-1

new laser=0
new sprite_line
new g_text[64]

new ints[37]
new Float:floats[37]
new Float:vecs[23][3]
new edicts[11]
new strings[13][32]
new bytes[6]

new n_int[37]
new n_float[37]
new n_vec[23]
new n_edict[11]
new n_string[13]
new n_byte[6]
new n_status
new n_data

new detect_page=0

new lab
new lab_mode

new get_mode[3][32]={"By aim","By touth","New ones"}
new get_mod = 0
new look_for_ent = 1

new last_touth

new m_fakeHostage
new m_fakeHostageDie

public plugin_precache()
{
	sprite_line = precache_model("sprites/dot.spr")
}

public plugin_init() 
{
	register_plugin("M_EEL", "1.1", "Miczu")
	
	register_menucmd(register_menuid("Detect"), KeysDetect, "PressedDetect")
	register_menucmd(register_menuid("Ent_search"), KeysEnt_search, "PressedEnt_search")
	register_menucmd(register_menuid("Get_ent"), KeysGet_ent, "PressedGet_ent")
	register_menucmd(register_menuid("menu_string"), Keysmenu_string, "Pressedmenu_string")
	register_menucmd(register_menuid("menu_eb2"), Keysmenu_90, "Pressedmenu_eb2")
	register_menucmd(register_menuid("menu_eb1"), Keysmenu_90, "Pressedmenu_eb1")
	register_menucmd(register_menuid("menu_vec2"), Keysmenu_90, "Pressedmenu_vec2")
	register_menucmd(register_menuid("menu_vec1"), Keysmenu_90, "Pressedmenu_vec1")
	register_menucmd(register_menuid("menu_float3"), Keysmenu_90, "Pressedmenu_float3")
	register_menucmd(register_menuid("menu_float2"), Keysmenu_90, "Pressedmenu_float2")
	register_menucmd(register_menuid("menu_float1"), Keysmenu_90, "Pressedmenu_float1")
	register_menucmd(register_menuid("menu_int3"), Keysmenu_90, "Pressedmenu_int3")
	register_menucmd(register_menuid("menu_int2"), Keysmenu_90, "Pressedmenu_int2")
	register_menucmd(register_menuid("menu_int1"), Keysmenu_90, "Pressedmenu_int1")
	register_menucmd(register_menuid("Basic_menu"), KeysBasic_menu, "PressedBasic_menu")
	
	m_fakeHostage = get_user_msgid("HostagePos");
	m_fakeHostageDie = get_user_msgid("HostageK");
	
	register_clcmd("say /eel","menu")
	register_clcmd("/eel","menu")
	register_clcmd("radio1", "radio1")
	register_clcmd("radio2", "radio2")
	register_clcmd("radio3", "radio3")
	
	
	register_think("eng_ent_lab", "think_eng_ent_lab")
	
	register_touch("player", "*", "touch")
	register_touch("*", "player", "touch2")
}

public plugin_end()
{
	if(is_valid_ent(lab)) remove_entity(lab)
}
//////////////////////////////////////////////////////////
//		    	 Lab code	   		//
//////////////////////////////////////////////////////////

public create_lab(id)
{
	new ent = find_ent_by_class(-1, "eng_ent_lab")

	if(ent)
	{
		entity_set_edict(ent, EV_ENT_owner, id )
		entity_set_float(ent, EV_FL_nextthink, halflife_time() + NEXT_THINK)
		lab=ent	
	}
	else
	{
		ent = create_entity("info_target")
		if(is_valid_ent(ent))
		{
			entity_set_string(ent, EV_SZ_classname, "eng_ent_lab")
			entity_set_float(ent, EV_FL_nextthink, halflife_time() + NEXT_THINK)
			
			entity_set_edict(ent, EV_ENT_owner, id )
			set_enemy(id)
			lab=ent
		}
	}
	if(is_valid_ent(ent)) return true
	
	return false
}

public think_eng_ent_lab(eng_ent_lab)
{
	static ents[768]	//I think it will work
	static nent		//New ent
	new id = 0 
	
	if(is_valid_ent(eng_ent_lab)) id = entity_get_edict(eng_ent_lab, EV_ENT_owner)
	
	if(is_user_connected(id))
	{
		if(look_for_ent)	// do we look for ent ( 6. Get ent )
		{
			if(get_mod==0)	// By aim
			{
				new trash,aim
				get_user_aiming(id,aim,trash,6000)
				if(nent != aim && is_ignored(aim)!=1) nent = aim
			}
			else if(get_mod==1)	// By touth
			{
				if(nent != last_touth && is_ignored(last_touth)!=1) nent = last_touth
			}
			else if(get_mod==2)	// New Ones
			{
				for(new i=0;i<768;i++)
				{
					if(is_valid_ent(i))
					{
						if(!ents[i])
						{
							if(is_ignored(i)==0) nent=i
						}
						ents[i]=1
					}
					else ents[i]=0
				}
			}
			
			if(nent != entity_get_edict(eng_ent_lab, EV_ENT_enemy))	// is it new?
			{
				set_enemy(nent)
			} 
		}
		
		///////////    Get ent data    //////////
		
		new ent = entity_get_edict(eng_ent_lab, EV_ENT_enemy)
		
		if(is_valid_ent(ent))
		{
			for(new i=0;i<=36;i++)
			{
				if(ints[i] != entity_get_int(ent, i))
				{
					ints[i] = entity_get_int(ent, i)
					n_int[i] = 1
				}
			}
			
			for(new i=0;i<=36;i++)
			{
				if(floats[i] != entity_get_float(ent, i))
				{
					floats[i] = entity_get_float(ent, i)
					n_float[i] = 1
				}
			}
			
			for(new i=0;i<=22;i++)
			{
				new Float:veca[3]
				entity_get_vector(ent, i, veca)
				
				if(veca[0]!=vecs[i][0]||veca[1]!=vecs[i][1]||veca[2]!=vecs[i][2])
				{
					for(new j=0;j<3;j++)
						vecs[i][j]=veca[j]
					n_vec[i]=1
				}
			}
			
			for(new i=0;i<=10;i++)
			{
				if(edicts[i] != entity_get_edict( ent, i))
				{
					edicts[i] = entity_get_edict( ent, i)
					n_edict[i] = 1
				}
			}
			
			
			for(new i=0;i<=12;i++)
			{
				new text[32]
				entity_get_string( ent, i,text,31)
				if(!equal(strings[i],text))
				{
					format(strings[i],31,"%s",text)
					n_string[i] = 1
				}
			}
			
			for(new i=0;i<=5;i++)
			{
				if(bytes[i] != entity_get_byte ( ent, i ))
				{
					bytes[i] = entity_get_byte ( ent, i )
					n_byte[i] = 1
				}
			}		
		}
		else ent_info()		// too get a invalit message :)
		
		////////////////////////////////////////////////////
						
		if(n_status<1) n_format() // first ent data as base
		n_status++		
		
		switch(lab_mode)			// what menu we look at
		{
			case -1,7:ShowBasic_menu(id)
			case 0: Showmenu_int1(id)
			case 10:Showmenu_int2(id)
			case 20:Showmenu_int3(id)
			case 1: Showmenu_float1(id)
			case 11:Showmenu_float2(id)
			case 21:Showmenu_float3(id)
			case 2: Showmenu_vec1(id) 
			case 12:Showmenu_vec2(id) 
			case 3: Showmenu_eb1(id) 
			case 13:Showmenu_eb2(id) 
			case 4: Showmenu_string(id) 
			case 5: ShowGet_ent(id)
			case 6: ShowEnt_search(id)
			case 8: ShowDetect(id)
		}
		
		static Float: delay=0.0			// if its go too fast, radar wont work...
		if(delay>1 && is_valid_ent(ent)) 	// +1 sec
		{
			showOnRadar(id, ent)
			delay=0.0
		}
		delay+=NEXT_THINK
		
		if(is_valid_ent(ent)) 
		{
			if(laser) use_laser(id,ent)
		}

		entity_set_float(eng_ent_lab, EV_FL_nextthink, halflife_time() + NEXT_THINK)
	}
}


//////////////////////////////////////////////////////////
//		    	 Menu code	   		//
//////////////////////////////////////////////////////////
//		   Made by menu generator	   	//
//////////////////////////////////////////////////////////

public menu(id)
{
	if(create_lab(id))
	{
		lab_mode=-1
		ShowBasic_menu(id) 
	}
}

public ShowBasic_menu(id) 
{	
	new text[1024]
	new laser_color[3]
	
	if(laser==0) format(laser_color,2,"\w")
	else if(laser==1) format(laser_color,2,"\y")
	else if(laser==2) format(laser_color,2,"\r")
	
	format(text,255,"%s\w^n\y1. \wInteger^n\y2. \wFloat^n\y3. \wVector^n\y4. \wEdict & Byte^n\y5. \wString^n^n\y6. \wGet ent^n\y7. \wEnt search^n^n\y8. %sLaser^n^n\y9. \wChange Detect^n^n\y0. \rExit^n",g_text,laser_color)
	show_menu(id, KeysBasic_menu, text, -1, "Basic_menu") // Display menu
}

public PressedBasic_menu(id, key) {
	/* Menu:
	* ent() class:
	* 
	* 1. Integer
	* 2. Float
	* 3. Vector
	* 4. Edict & Byte
	* 5. String
	* 
	* 6. Get ent
	* 7. Ent search
	*
	* 8. Laser
	*
	* 9. Change Detect
	* 0. Exit
	*/

	switch (key) {
		case 0: { // 1

		}
		case 1: { // 2
			
		}
		case 2: { // 3
			
		}
		case 3: { // 4
			
		}
		case 4: { // 5
			
		}
		case 5: { // 6
			
		}
		case 6: { // 7
			look_for_ent=0
			get_all_classes()
		}
		case 7: { // 8
			if(laser==0) laser=1
			else if(laser==1) laser=2
			else laser=0
		}
		case 8: { // 9
			detect_page=0
		}
		case 9: { // 0
			remove_entity(lab)
		}
	}
	lab_mode=key
}


public Showmenu_int1(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=0;i<13;i++)
	{
		format(text,1023,"%s \r%s \w%d^n",text,sint[i],ints[i])
	}
	
	add(text,1023,"\y9. Next  \r0. Exit")
	show_menu(id, Keysmenu_90, text, -1, "menu_int1") // Display menu
}

public Pressedmenu_int1(id, key) 
{
	switch (key) {
		case 8: { // 9
			lab_mode=10
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_int2(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=13;i<25;i++)
	{
		format(text,1023,"%s \r%s \w%d^n",text,sint[i],ints[i])
	}
	
	add(text,1023,"\y9. Next  \r0. Exit")
	show_menu(id, Keysmenu_90, text, -1, "menu_int2") // Display menu
}

public Pressedmenu_int2(id, key)
{

	switch (key) {
		case 8: { // 9
			lab_mode=20
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_int3(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=25;i<37;i++)
	{
		format(text,1023,"%s \r%s \w%d^n",text,sint[i],ints[i])
	}
	
	add(text,1023,"\y9. Next  \r0. Exit")
	show_menu(id, Keysmenu_90, text, -1, "menu_int3") // Display menu
}

public Pressedmenu_int3(id, key) 
{
	switch (key) {
		case 8: { // 9
			lab_mode=0
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_float1(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=0;i<13;i++)
	{
		format(text,1023,"%s \r%s \w%5.2f^n",text,sfloat[i],floats[i])
	}
	
	add(text,1023,"\y9. Next  \r0. Exit")
	
	show_menu(id, Keysmenu_90, text, -1, "menu_float1") // Display menu
}

public Pressedmenu_float1(id, key) 
{
	switch (key) 
	{
		case 8: { // 9
			lab_mode=11
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_float2(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=13;i<25;i++)
	{
		format(text,1023,"%s \r%s \w%5.2f^n",text,sfloat[i],floats[i])
	}
	
	add(text,1023,"\y9. Next  \r0. Exit")
	
	show_menu(id, Keysmenu_90, text, -1, "menu_float2") // Display menu
}

public Pressedmenu_float2(id, key) 
{
	switch (key) {
		case 8: { // 9
			lab_mode=21
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_float3(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=25;i<37;i++)
	{
		format(text,1023,"%s \r%s \w%5.2f^n",text,sfloat[i],floats[i])
	}
	
	add(text,1023,"\y9. Next  \r0. Exit")
	
	show_menu(id, Keysmenu_90, text, -1, "menu_float3") // Display menu
}

public Pressedmenu_float3(id, key) 
{
	switch (key) {
		case 8: { // 9
			lab_mode=1
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_vec1(id) 
{	
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=0;i<12;i++)
	{
		format(text,1023,"%s \r%s \w{%4.1f,%4.1f,%4.1f}^n",text,svec[i],vecs[i][0],vecs[i][1],vecs[i][2])
	}
	
	add(text,1023,"\y9. Next  \r0. Exit")
	
	show_menu(id, Keysmenu_90, text, -1, "menu_vec1") // Display menu
}

public Pressedmenu_vec1(id, key) 
{
	switch (key) {
		case 8: { // 9
			lab_mode=12
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_vec2(id) 
{	
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=12;i<23;i++)
	{
		format(text,1023,"%s \r%s \w{%4.1f,%4.1f,%4.1f}^n",text,svec[i],vecs[i][0],vecs[i][1],vecs[i][2])
	}
	
	add(text,1023,"\y9. Back  \r0. Exit")
	
	show_menu(id, Keysmenu_90, text, -1, "menu_vec2") // Display menu
}

public Pressedmenu_vec2(id, key)
{
	switch (key) {
		case 8: { // 9
			lab_mode=2
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_eb1(id) 
{	
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=0;i<11;i++)
	{
		format(text,1023,"%s \r%s \w%d^n",text,sedict[i],edicts[i])
	}
	
	add(text,1023,"\y9. Back  \r0. Exit")
	
	show_menu(id, Keysmenu_90, text, -1, "menu_eb1") // Display menu
}

public Pressedmenu_eb1(id, key) 
{
	switch (key) {
		case 8: { // 9
			lab_mode= 13
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_eb2(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=0;i<6;i++)
	{
		format(text,1023,"%s \r%s \w%d^n",text,sbyte[i],bytes[i])
	}
	
	add(text,1023,"\y9. Back  \r0. Exit")
	
	show_menu(id, Keysmenu_90, text, -1, "menu_eb2") // Display menu
}

public Pressedmenu_eb2(id, key) 
{
	switch (key) {
		case 8: { // 9
			lab_mode= 3
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public Showmenu_string(id) 
{
	new text[1024]
	format(text,1023,"%s",g_text)
	
	for(new i=0;i<13;i++)
	{
		format(text,1023,"%s \r%s \w%s^n",text,sstring[i],strings[i])
	}
	
	add(text,1023,"\y0. Exit")
	
	show_menu(id, Keysmenu_string, text, -1, "menu_string") // Display menu
}

public Pressedmenu_string(id, key) 
{
	switch (key) {
		case 9: { // 0
			lab_mode=-1
		}
	}
}

public ShowGet_ent(id) 
{
	new text[1024]
	
	if(look_for_ent==1)format(text,1023,"%s^n\rGet you ent!^n\y^n1. \wMode: %s^n^n\y2. \wIgnore ent^n\y3. \wIgnore class^n\y4. \wReset ignore list.^n^n\y5. \wLock ent^n\y6. \yLook for ent^n\y7. \wI'm the ONE!^n^n\y9. \rReturn^n",g_text,get_mode[get_mod])
	else format(text,1023,"%s^n\rGet you ent!^n\y^n1. \wMode: %s^n^n\y2. \wIgnore ent^n\y3. \wIgnore class^n\y4. \wReset ignore list.^n^n\y5. \wLock ent^n\y6. \rLook for ent^n\y7. \wI'm the ONE!^n^n\y9. \rReturn^n",g_text,get_mode[get_mod])
	show_menu(id, KeysGet_ent, text, -1, "Get_ent") // Display menu
}

public PressedGet_ent(id, key) {
	/* Menu:
	* Get you ent!
	* 
	* 1. Mode:
	* 
	* 2. Ignore ent
	* 3. Ignore class
	* 4. Reset ignore list.
	* 
	* 5. Lock ent
	* 6. Look for ent
	* 7. I'm the ONE!
	* 
	* 9. Return
	*/

	new ent = entity_get_edict(lab,EV_ENT_enemy)
	
	switch (key) {
		case 0: { // 1
			if(get_mod<2) get_mod++
			else get_mod=0
		}
		case 1: { // 2
			if(is_ignored_ent(ent)==0) add_ignored_ent(ent)
		}
		case 2: { // 3
			if(is_ignored_class(ent)==0) add_ignored_class(ent)
		}
		case 3: { // 4
			ignore_num=0
			ignors_num=0
		}
		case 4: { // 5
			look_for_ent = 0
		}
		case 5: { // 6
			look_for_ent = 1
		}
		case 6: { // 7
			look_for_ent = 0
			set_enemy(id)
		}
		case 8: { // 9
			lab_mode=-1
		}
	}
}

public ShowEnt_search(id) 
{	
	new text[1024]
	
	format(text,1023,"%s^n^n\y1. \wNext class^n\y2. \wPrevious class^n^n\y3. \wNext ent^n\y^n\y7. Refresh^n^n\y9. \rReturn^n",g_text)
	
	show_menu(id, KeysEnt_search, text, -1, "Ent_search") // Display menu
}

public PressedEnt_search(id, key) {
	/* Menu:
	* 
	* 1. Next class
	* 2. Previous class
	* 
	* 3. Next ent
	* 
	* 7. Refresh
	* 
	* 9. Return
	*/

	switch (key) {
		case 0: { // 1
			if(current_class_num+1>class_list_num) current_class_num=0
			else current_class_num++
			first_ent()
		}
		case 1: { // 2
			if(current_class_num==0) current_class_num=class_list_num-1
			else current_class_num--
			first_ent()
		}
		case 2: { // 3
			next_ent()
		}
		case 6: { // 7
			get_all_classes()
		}
		case 8: { // 9
			lab_mode=-1
			set_enemy(current_ent)
		}
	}
}

public ShowDetect(id) {
	new text[1024]
	new Keys
	n_data=0	
	
	format(text,1023,"%s",g_text)
	
	n_data++		
	if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
	{
		format(text,1023,"%s^n\rINTEGERS:\w",text)
	}
	if((detect_page+1)*13>n_data)
		for(new i=0;i<37;i++)
		{
			if(n_int[i])
			{
				if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
				{
					format(text,1023,"%s^n\w%s %d",text,sint[i],ints[i])
				}
				n_data++
			}
		}
	n_data++
	if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
	{
		format(text,1023,"%s^n\rFLOATS:\w",text)
	}
	if((detect_page+1)*13>n_data)
		for(new i=0;i<37;i++)
		{
			if(n_float[i])
			{
				if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
				{
					format(text,1023,"%s^n\w%s %5.2f",text,sfloat[i],floats[i])
				}
				n_data++
			}
		}
	n_data++
	if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
	{
		format(text,1023,"%s^n\rVECTORS:\w",text)
	}
	if((detect_page+1)*13>n_data)
		for(new i=0;i<23;i++)
		{
			if(n_vec[i])
			{
				if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
				{
					format(text,1023,"%s^n\w%s {%4.1f,%4.1f,%4.1f} ",text,svec[i],vecs[i][0],vecs[i][1],vecs[i][2])
				}
				n_data++
			}
		}
	n_data++
	if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
	{
		format(text,1023,"%s^n\rEDICTS:\w",text)
	}
	if((detect_page+1)*13>n_data)
		for(new i=0;i<11;i++)
		{
			if(n_edict[i])
			{
				if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
				{
					format(text,1023,"%s^n\w%s %d",text,sedict[i],edicts[i])
				}
				n_data++
			}
		}
	n_data++
	if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
	{
		format(text,1023,"%s^n\rSTRINGS:\w",text)
	}
	if((detect_page+1)*13>n_data)
		for(new i=0;i<13;i++)
		{
			if(n_string[i])
			{
				if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
				{
					format(text,1023,"%s^n\w%s %s",text,sstring[i],strings[i])
				}
				n_data++
			}
		}
	n_data++
	if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
	{
		format(text,1023,"%s^n\rBYTES:\w",text)
	}
	if((detect_page+1)*13>n_data)
		for(new i=0;i<6;i++)
		{
			if(n_byte[i])
			{
				if(detect_page*13<=n_data && (detect_page+1)*13>n_data)
				{
					format(text,1023,"%s^n\w%s %d",text,sbyte[i],bytes[i])
				}
				n_data++
			}
		}
		
	if(n_data>13)
	{
		format(text,1023,"%s^n^n\y7. \wNext^n\y^n9. \wReset^n\y0. \wExit^n",text)
		Keys = (1<<6)|(1<<8)|(1<<9)
	}
	else
	{
		format(text,1023,"%s^n^n\y^n9. \wReset^n\y0. \wExit^n",text)
		Keys = (1<<8)|(1<<9)
	}
		
	
	
	show_menu(id, Keys, text, -1, "Detect") // Display menu
}

public PressedDetect(id, key) 
{
	switch (key) {
		case 6: { // 7
			if(n_data>(detect_page+1)*13) detect_page++
			else detect_page=0
		}
		case 8: { // 9
			n_format()
			detect_page=0
		}
		case 9: { // 0
			lab_mode=-1
		}
	}
}


//////////////////////////////////////////////////////////
//			touch				//
//////////////////////////////////////////////////////////

public touch(id,ent)	// when touch solid
{
	if(is_ignored(ent)==0 && is_owner(id)) last_touth=ent
}

public touch2(ent,id)	// when touch trigers (i think)
{
	if(is_ignored(ent)==0 && is_owner(id)) last_touth=ent
}

//////////////////////////////////////////////////////////
//		        Ignore code			//
//////////////////////////////////////////////////////////

public is_ignored(ent)
{
	if(is_valid_ent(ent))
	{
		if(is_ignored_class(ent) || is_ignored_ent(ent)) return 1
		return 0
	}
	return -1
}

public is_ignored_class(ent)
{
	if(is_valid_ent(ent))
	{
		new class[32]
		entity_get_string( ent, EV_SZ_classname,class,31)
	
		for(new i=0;i<ignore_num;i++)
		{
			if(equali(class,ignore[i])) return 1
		}
		return 0
	}
	return -1
}

public is_ignored_ent(ent)
{
	if(is_valid_ent(ent))
	{
		for(new i=0;i<ignors_num;i++)
		{
			if(ent==ignors[i]) return 1
		}
		return 0
	}
	return -1
}

public add_ignored_class(ent)
{
	if(ignore_num<128 )
	{
		if(is_valid_ent(ent))
		{
			new class[32]
			entity_get_string( ent, EV_SZ_classname,class,31)
			format(ignore[ignore_num],31,"%s",class)
		}
		else format(ignore[ignore_num],31,"%s",sstring[EV_SZ_classname])
		
		ignore_num++
	}
}

public add_ignored_ent(ent)
{
	if(ignors_num<128)
	{		
		ignors[ignors_num]=ent
		ignors_num++
	}
}

//////////////////////////////////////////////////////////
//		     Ent search code	   		//
//////////////////////////////////////////////////////////

public get_all_classes()
{
	class_list_num=0
	current_class_num=0
	
	for(new i=1;i<768;i++)
	{
		if(!is_listed_class(i)) add_listed_class(i)
	}
	first_ent()
}

public is_listed_class(ent)
{
	if(is_valid_ent(ent))
	{
		new class[32]
		entity_get_string( ent, EV_SZ_classname,class,31)
	
		for(new i=0;i<class_list_num;i++)
		{
			if(equali(class,class_list[i])) return 1
		} 
		return 0
	}
	return -1	
}

public add_listed_class(ent)
{
	if(is_valid_ent(ent))
	{
		if(class_list_num<128)
		{
			new class[32]
			entity_get_string( ent, EV_SZ_classname,class,31)
			
			format(class_list[class_list_num],31,"%s",class)
			class_list_num++
		}
	}
}

public first_ent()
{
	current_ent=find_ent_by_class(-1,class_list[current_class_num])
	if(current_ent==0)
	{
		if(current_class_num+1>class_list_num) current_class_num=0
		else current_class_num++
		first_ent()
	}
	set_enemy(current_ent)
}

public next_ent()
{
	current_ent=find_ent_by_class(current_ent,class_list[current_class_num])
	if(current_ent==0) current_ent=find_ent_by_class(-1,class_list[current_class_num])
	
	set_enemy(current_ent)
	
}

//////////////////////////////////////////////////////////
//		   Radio command code	   		//
////////////////////////////////////////////////////////// 


public radio1(id)
{
	if(is_valid_ent(lab) && is_owner(id))
	{
		new ent = entity_get_edict(lab, EV_ENT_enemy)
		if(is_valid_ent(ent))
		{
			new class[32]
			entity_get_string(ent,EV_SZ_classname,class,31)
			if(!equal("player",class))
			{
				ent=find_ent_by_class(ent,class)
			
				if(ent==0) ent=find_ent_by_class(-1,class)
				set_enemy(ent)
				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

public radio2(id)
{
	if(is_valid_ent(lab) && is_owner(id))
	{
		new ent = entity_get_edict(lab, EV_ENT_enemy)
		if(is_valid_ent(ent))
		{
			new class[32]
			entity_get_string(ent,EV_SZ_classname,class,31)
			if(!equal("player",class))
			{
				if(laser==0) laser=1
				else if(laser==1) laser=2
				else laser=0
				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

public radio3(id)
{
	if(is_valid_ent(lab) && is_owner(id))
	{
		new ent = entity_get_edict(lab, EV_ENT_enemy)
		if(is_valid_ent(ent))
		{
			new class[32]
			entity_get_string(ent,EV_SZ_classname,class,31)
			if(!equal("player",class))
			{
				if(look_for_ent) look_for_ent=0
				else look_for_ent=1
				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

//////////////////////////////////////////////////////////
//		     Random code	   		//
////////////////////////////////////////////////////////// 

public is_owner(id)
{
	if(is_valid_ent(lab))
		if(id==entity_get_edict(lab, EV_ENT_owner)) return 1
	return 0
}

public set_enemy(ent)
{
	if(is_valid_ent(lab))
	{
		entity_set_edict(lab, EV_ENT_enemy, ent)
		n_status=0
	}
	ent_info()
}

public ent_info()
{
	if(is_valid_ent(lab))
	{
		new ent = entity_get_edict(lab,EV_ENT_enemy)
		new name[32]
		if(is_valid_ent(ent)) entity_get_string(ent,EV_SZ_classname,name,31)
		else format(name,31,"invalid_ent")
		
		format(g_text,63,"\yent(%d) class: \r%s^n",ent,name)
	}
	else format(g_text,63,"\yLab entity error!^n")
}
	
	
//////////////////////////////////////////////////////////
//		     	N code	   			//
//////////////////////////////////////////////////////////

public n_format()
{
	for(new i=0;i<37;i++)
	{
		n_int[i]=0	
		n_float[i]=0
	}
	for(new i=0;i<23;i++)
	{
		n_vec[i]=0
	}
	for(new i=0;i<11;i++)
	{
		n_edict[i]=0
	}
	for(new i=0;i<13;i++)
	{
		n_string[i]=0
	}
	for(new i=0;i<6;i++)
	{
		n_byte[i]=0
	}
}

//////////////////////////////////////////////////////////
//		Ent position code	   		//
//////////////////////////////////////////////////////////

public use_laser(id,ent)
{
	new Float: ent_min[3],Float: ent_max[3],Float: id_ori[3];
	
	new e_min[3],e_max[3],ori[3],ents[3];	
	
	entity_get_vector(ent,EV_VEC_absmin,ent_min)
	entity_get_vector(ent,EV_VEC_absmax,ent_max)	
	entity_get_vector(id,EV_VEC_origin,id_ori);
	
	for(new i=0;i<3;i++)
	{
		e_min[i]=floatround(ent_min[i])
		e_max[i]=floatround(ent_max[i])
		ori[i]=floatround(id_ori[i])
		ents[i]=(e_min[i]+e_max[i])/2
	}
	
	Create_Line(id,ori,ents)
	if(laser==2)
	{
		Create_Box(id,e_min,e_max)
	}
}

public Create_Box(id,mins[],maxs[])
{
	DrawLine(id,maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2])
	DrawLine(id,maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2])
	DrawLine(id,maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2])

	DrawLine(id,mins[0], mins[1], mins[2], maxs[0], mins[1], mins[2])
	DrawLine(id,mins[0], mins[1], mins[2], mins[0], maxs[1], mins[2])
	DrawLine(id,mins[0], mins[1], mins[2], mins[0], mins[1], maxs[2])

	DrawLine(id,mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2])
	DrawLine(id,mins[0], maxs[1], mins[2], maxs[0], maxs[1], mins[2])
	DrawLine(id,maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2])
	DrawLine(id,maxs[0], mins[1], mins[2], maxs[0], mins[1], maxs[2])
	DrawLine(id,maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2])
	DrawLine(id,mins[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2])
}

public DrawLine(id,x1, y1, z1, x2, y2, z2) 
{
	new start[3]
	new stop[3]
	
	start[0]=(x1)
	start[1]=(y1)
	start[2]=(z1)
	
	stop[0]=(x2)
	stop[1]=(y2)
	stop[2]=(z2)

	Create_Line(id,start, stop)
}

public Create_Line(id,start[],stop[])
{
	message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(0)
	write_coord(start[0])
	write_coord(start[1])
	write_coord(start[2])
	write_coord(stop[0])
	write_coord(stop[1])
	write_coord(stop[2])
	write_short(sprite_line)
	write_byte(1)
	write_byte(5)
	write_byte(floatround(NEXT_THINK*10))
	write_byte(3)
	write_byte(0)
	write_byte(255)	// RED
	write_byte(0)	// GREEN
	write_byte(0)	// BLUE					
	write_byte(250)	// brightness
	write_byte(5)
	message_end()
}

public showOnRadar(id, ent) 
{
	if(m_fakeHostage && m_fakeHostageDie)	//only 0 is false
	{
		new Float: ori_min[3]
		new Float: ori_max[3]	
		
		entity_get_vector(ent,EV_VEC_absmin,ori_min)
		entity_get_vector(ent,EV_VEC_absmax,ori_max)	
		
		message_begin(MSG_ONE_UNRELIABLE, m_fakeHostage, {0,0,0}, id);
		write_byte(id);
		write_byte(21);
		write_coord(floatround((ori_max[0]+ori_min[0])/2));
		write_coord(floatround((ori_max[1]+ori_min[1])/2));
		write_coord(floatround((ori_max[2]+ori_min[2])/2));
		message_end();
	
		message_begin(MSG_ONE_UNRELIABLE, m_fakeHostageDie, {0,0,0}, id);
		write_byte(21);
		message_end();
	}
}

//////////////////////////////////////////////////////////
//		     	end code	   		//
//////////////////////////////////////////////////////////
