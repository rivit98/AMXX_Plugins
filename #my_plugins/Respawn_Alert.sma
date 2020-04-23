#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta_util>
#include <ColorChat>

#define HELP_LINE					// comment this to disable help line during zone edit


new const keys = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9) | (1 << 0)

new spr_dot;

enum _:kTasks (+= 100){
	TASK_ZONE = 100,
	TASK_CHECK,
	TASK_STARTCHECK,
	TASK_SLAP
};

new save_path[128];
new zone_increment = 10;
new const zone_coords[] = "XYZ";
enum _:kZonesColors{
	ZONE_ACTIVE,
	ZONE_RED,
	ZONE_YELLOW,
	ZONE_LINE
}

new zone_colors[kZonesColors][3] = {
	{0, 255, 0},
	{255, 0, 0},
	{255, 255, 0},
	{255, 150, 50}
}

new map_cors_edit[6] // 0,1 - X || 2,3 - Y || 4,5 - Z
new current_zone = 0;
new Array:zones;
new zone_coords_num = 0;

enum _:kZoneData{
	COORD = 5
}

new tempData[kZoneData];
new const Prefix[] = "^4[Respawn_Alert]^1";

new PlayerWarn[33]
	
new cvar_checkstarttime,	// po ilu sekundach od startu rundy ma zaczac sprawdzac czy gracz jest na respie
	cvar_checkplayerspawn, 	// co ile sekund ma sprawdzac czy gracz jest na respie
	cvar_maxplayerwarn,	// po ilu warnach ukarac gracza
	cvar_typepenatly,	// typ kary
	cvar_takehp,		// ile hp zabrac gdy cvar_typepenatly = 0
	cvar_takemoney,		// zabiera pieniadze graczowi
	cvar_admin,		// czy admin ma byc sprawdzany. 0 - Nie | 1 - Tak
	
	Float:checkplayerspawn,
	max_warns,
	penatly,
	
	takehp,
	takemoney,
	admin_immunity;	

public plugin_init() {
	register_plugin("Respawn alert", "1.1", "RiviT")

	register_clcmd("say /strefy", "ZoneCreator")
	register_clcmd("radio3", "ZoneCreator")
	register_clcmd("radio2", "ZoneCreator")
	register_clcmd("radio1", "ZoneCreator")
	register_menucmd(register_menuid("Edit zone"), keys, "edit_zone_handler")

	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_logevent("RoundStart", 2, "1=Round_Start");
	
	Cvars();
}

public plugin_precache(){
	zones = ArrayCreate(kZoneData, 10);

	spr_dot = precache_model("sprites/dot.spr");

	new currentmap[32], cfgdir[32];
	get_configsdir(cfgdir, charsmax(cfgdir)) 
	get_mapname(currentmap, charsmax(currentmap))
	formatex(save_path, charsmax(save_path), "%s/respawn_zone", cfgdir);
	if (!dir_exists(save_path)){
		mkdir(save_path);
	}

	format(save_path, charsmax(save_path), "%s/%s.ini", save_path, currentmap);
	LoadAll();
}

public plugin_end(){
	if(zones != Invalid_Array){
		ArrayDestroy(zones);
	}
}

// EDITOR STUFF
/*------------------------------------------------------------------*/

public getZoneInfo(current_zone){
	ArrayGetArray(zones, current_zone, tempData);
	for(new i = 0; i < 6; i++){
		map_cors_edit[i] = tempData[i];
	}
}

public ZoneCreator(id) {
	if (!(get_user_flags(id) & ADMIN_RCON)){
		return PLUGIN_CONTINUE;
	}
	//if (!is_user_alive(id)) return PLUGIN_HANDLED

	new size = ArraySize(zones);

	if(current_zone >= size){
		current_zone = 0;
	}
	if(size){
		getZoneInfo(current_zone);
		if(!task_exists(TASK_ZONE+id)){
			set_task(0.2, "ShowZoneBox", TASK_ZONE+id, _, _, "b")
		}
	}else{
		remove_task(TASK_ZONE+id);
	}

	new menu = menu_create("Zone creator", "ZoneCreatorHandler")
	new cb = menu_makecallback("ZoneCreatorCb")

	menu_additem(menu, "New zone", "", 0, cb);
	menu_additem(menu, "Next zone", "", 0, cb);
	menu_additem(menu, "Edit", "" , 0, cb);
	menu_additem(menu, "\ySave zones", "", 0, cb);
	menu_additem(menu, "\rDelete all saved zones (deletes from file)", "", 0, cb);
	menu_additem(menu, "Restore zones from file", "", 0, cb)
	menu_additem(menu, "info", "", 0, cb)
	menu_display(id, menu)

	return PLUGIN_HANDLED
}

public ZoneCreatorCb(id, menu, item) {
	switch(item){
		case 0:{
		}
		case 1:{
			if(ArraySize(zones) < 2){
				return ITEM_DISABLED;
			}
		}
		case 2:{
			new info[128];
			if(ArraySize(zones)){
				//ArrayGetArray(zones, current_zone, tempData);
				formatex(info, charsmax(info), "Edit zone: #%i", current_zone);
				menu_item_setname(menu, item, info);
			}else{
				formatex(info, charsmax(info), "Edit zone: no zones");
				menu_item_setname(menu, item, info);
				return ITEM_DISABLED;
			}
		}
		case 3:{
			if(!ArraySize(zones)){
				return ITEM_DISABLED;
			}
		}
		case 4,5:{
			if(!file_exists(save_path)){
				return ITEM_DISABLED;
			}
		}
		case 6:{
			if(!ArraySize(zones)){
				return ITEM_DISABLED;
			}
			if(task_exists(TASK_ZONE+id)){
				menu_item_setname(menu, item, "Stop displaying zones");
			}else{
				menu_item_setname(menu, item, "Display zones");
			}
		}
	}

	return ITEM_ENABLED
}

public ZoneCreatorHandler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		remove_task(TASK_ZONE+id);
		return PLUGIN_HANDLED
	}

	switch (item) {
		case 0:{
			new origins[3];
			get_user_origin(id, origins, 0);
			for(new i = 0; i < 6; i++){
				map_cors_edit[i] = tempData[i] = origins[i/2] + (power(-1, i+1) * 32);
			}
			new size = ArraySize(zones);
			ArrayPushArray(zones, tempData);
			current_zone = size;

			client_print(id, 3, "Added zone!");
			edit_zone(id);
			return PLUGIN_CONTINUE
		}
		case 1,2:{
			if(item == 1){
				current_zone = (current_zone + 1) % ArraySize(zones);
			}

			getZoneInfo(current_zone);

			if(item == 2){
				edit_zone(id);
				return PLUGIN_CONTINUE;
			}
		}
		case 3:{
			SaveAll();
		}
		case 4:{
			DeleteAll();
		}
		case 5:{
			LoadAll();
		}
		case 6:{
			if(task_exists(TASK_ZONE+id)){
				remove_task(TASK_ZONE+id);
			}else{
				set_task(0.2, "ShowZoneBox", TASK_ZONE+id, _, _, "b")
			}
		}
	}

	menu_display(id, menu);

	return PLUGIN_CONTINUE
}

public edit_zone(id) {
	if(!task_exists(TASK_ZONE+id) && ArraySize(zones)){
		set_task(0.2, "ShowZoneBox", TASK_ZONE+id, _, _, "b")
	}

	new text[256];
	formatex(text, charsmax(text),
	"\yEdit zone ^n^n\w1. Dimension: \y%c ^n\r    2. - | 3. +^n\y    4. - | 5. +^n  ^n6. Increment: %i ^n\r7. Delete zone^n^n\y9. Zone ready!^n\r0. Back without saving",
	zone_coords[zone_coords_num], zone_increment)

	show_menu(id, keys, text)
}

public edit_zone_handler(id, key) {
	switch (key) {
		case 0:{
			zone_coords_num = (zone_coords_num + 1) % 3 
		}
		case 1:{
			if ((map_cors_edit[zone_coords_num * 2] + zone_increment) < (map_cors_edit[zone_coords_num * 2 + 1] - 16))
				map_cors_edit[zone_coords_num * 2] += zone_increment
		}
		case 2:{
			if ((map_cors_edit[zone_coords_num * 2] - zone_increment) > -8000)
				map_cors_edit[zone_coords_num * 2] -= zone_increment
		}
		case 3:{
			if ((map_cors_edit[zone_coords_num * 2 + 1] - zone_increment) > (map_cors_edit[zone_coords_num * 2] + 16))
				map_cors_edit[zone_coords_num * 2 + 1] -= zone_increment
		}
		case 4:{
			if ((map_cors_edit[zone_coords_num * 2 + 1] + zone_increment) < 8000)
				map_cors_edit[zone_coords_num * 2 + 1] += zone_increment
		}
		case 5:{
			if (zone_increment < 1000) zone_increment *= 10
			else zone_increment = 1
		}
		case 6:{
			ArrayDeleteItem(zones, current_zone);
			client_print(id, 3, "Zone deleted!");
			ZoneCreator(id);
			return PLUGIN_CONTINUE;
		}
		case 8:{
			for(new i = 0; i < 6; i++){
				tempData[i] = map_cors_edit[i];
			}
			ArraySetArray(zones, current_zone, tempData);
			arrayset(tempData, 0, kZoneData);

			client_print(id, 3, "Zone added! Don't forget to save zones!");

			ZoneCreator(id)
			return PLUGIN_CONTINUE
		}
		case 9:{
			ZoneCreator(id);
			return PLUGIN_CONTINUE;
		}
		default:{
			return PLUGIN_CONTINUE;
		}
	}

	edit_zone(id)

	return PLUGIN_HANDLED
}

public ShowZoneBox(id) {
	static mins[3], maxs[3], i;
	static mid[3], orig[3];
	id -= TASK_ZONE;
	for(i = 0; i < 3; i++){
		mins[i] = map_cors_edit[0 + i*2];
		maxs[i] = map_cors_edit[1 + i*2];
		mid[i] = (mins[i] + maxs[i]) / 2;
		orig[i] = 0;
	}
#if defined HELP_LINE
	get_user_origin(id, orig, 0);

	FX_Line(orig, mid, zone_colors[ZONE_LINE]);
#endif

	DrawLine(maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2], zone_colors[ZONE_ACTIVE])
	DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2], zone_colors[ZONE_ACTIVE])
	DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2], zone_colors[ZONE_ACTIVE])
	DrawLine(mins[0], mins[1], mins[2], maxs[0], mins[1], mins[2], zone_colors[ZONE_ACTIVE])
	DrawLine(mins[0], mins[1], mins[2], mins[0], maxs[1], mins[2], zone_colors[ZONE_ACTIVE])
	DrawLine(mins[0], mins[1], mins[2], mins[0], mins[1], maxs[2], zone_colors[ZONE_ACTIVE])
	DrawLine(mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2], zone_colors[ZONE_ACTIVE])
	DrawLine(mins[0], maxs[1], mins[2], maxs[0], maxs[1], mins[2], zone_colors[ZONE_ACTIVE])
	DrawLine(maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2], zone_colors[ZONE_ACTIVE])
	DrawLine(maxs[0], mins[1], mins[2], maxs[0], mins[1], maxs[2], zone_colors[ZONE_ACTIVE])
	DrawLine(maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2], zone_colors[ZONE_ACTIVE])
	DrawLine(mins[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2], zone_colors[ZONE_ACTIVE])

	switch (zone_coords_num) {
		case 0:{
			DrawLine(maxs[0], maxs[1], maxs[2], maxs[0], mins[1], mins[2], zone_colors[ZONE_YELLOW])
			DrawLine(maxs[0], maxs[1], mins[2], maxs[0], mins[1], maxs[2], zone_colors[ZONE_YELLOW])
			DrawLine(mins[0], maxs[1], maxs[2], mins[0], mins[1], mins[2], zone_colors[ZONE_RED])
			DrawLine(mins[0], maxs[1], mins[2], mins[0], mins[1], maxs[2], zone_colors[ZONE_RED])
		}
		case 1:{
			DrawLine(mins[0], mins[1], mins[2], maxs[0], mins[1], maxs[2], zone_colors[ZONE_RED])
			DrawLine(maxs[0], mins[1], mins[2], mins[0], mins[1], maxs[2], zone_colors[ZONE_RED])
			DrawLine(mins[0], maxs[1], mins[2], maxs[0], maxs[1], maxs[2], zone_colors[ZONE_YELLOW])
			DrawLine(maxs[0], maxs[1], mins[2], mins[0], maxs[1], maxs[2], zone_colors[ZONE_YELLOW])
		}
		case 2:{
			DrawLine(maxs[0], maxs[1], maxs[2], mins[0], mins[1], maxs[2], zone_colors[ZONE_YELLOW])
			DrawLine(maxs[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2], zone_colors[ZONE_YELLOW])
			DrawLine(maxs[0], maxs[1], mins[2], mins[0], mins[1], mins[2], zone_colors[ZONE_RED])
			DrawLine(maxs[0], mins[1], mins[2], mins[0], maxs[1], mins[2], zone_colors[ZONE_RED])
		}
	}
}

public DrawLine(x1, y1, z1, x2, y2, z2, color[3]) {
	static start[3], stop[3]; 
	start[0] = x1;
	start[1] = y1;
	start[2] = z1;
	stop[0] = x2;
	stop[1] = y2;
	stop[2] = z2;

	FX_Line(start, stop, color)
}

public FX_Line(start[3], stop[3], color[3]) {
	message_begin(MSG_ALL, SVC_TEMPENTITY)

	write_byte(TE_BEAMPOINTS)

	write_coord(start[0])
	write_coord(start[1])
	write_coord(start[2])

	write_coord(stop[0])
	write_coord(stop[1])
	write_coord(stop[2])

	write_short(spr_dot)

	write_byte(1) // framestart 
	write_byte(1) // framerate 
	write_byte(4) // life in 0.1's 
	write_byte(5) // width
	write_byte(0) // noise 

	write_byte(color[0]) // r, g, b 
	write_byte(color[1]) // r, g, b 
	write_byte(color[2]) // r, g, b 

	write_byte(60) // brightness 
	write_byte(0) // speed 

	message_end()
}

public SaveAll(){
	delete_file(save_path)

	new fp = fopen(save_path, "wt");
	if(!fp) return;

	new size = ArraySize(zones);
	for(new i = 0; i < size; i++){
		arrayset(tempData, 0, kZoneData);
		ArrayGetArray(zones, i, tempData);		
		fprintf(fp, "%i %i %i %i %i %i^n",
			tempData[0], tempData[1], tempData[2], tempData[3], tempData[4], tempData[5])
	}
	fclose(fp);

	client_print(0, print_chat, "Zones saved!")
}

public DeleteAll(){
	delete_file(save_path);

	client_print(0, print_chat, "Zones deleted!")
}

public LoadAll(){
	ArrayClear(zones);

	new data[128];
	new fp = fopen(save_path, "r");
	if(!fp) return;

	new orgs[6][7];
	while(!feof(fp)){
		fgets(fp, data, charsmax(data));
		trim(data)
		if(data[0] == ';' || (data[0] == '/' && data[0] == '/') || strlen(data) < 2){
			continue;
		}

		arrayset(tempData, 0, kZoneData);
		parse(data, orgs[0], 6, orgs[1], 6, orgs[2], 6, orgs[3], 6, orgs[4], 6, orgs[5], 6);
		for(new i = 0; i < 6; i++){
			tempData[i] = str_to_num(orgs[i]);
		}

		ArrayPushArray(zones, tempData);
	}

	fclose(fp);

	client_print(0, print_chat, "Zones loaded!")
	log_amx("Loaded %i zones", ArraySize(zones))
}


// UTILS
/*------------------------------------------------------------------*/

public bool:checkIfInside(mins[], maxs[], origin[]){
	if((mins[0] < origin[0] < maxs[0])
		&& (mins[1] < origin[1] < maxs[1])
		&& (mins[2] < origin[2] < maxs[2])){

		return true;
	}

	return false;
}

public bool:getEntZone(id){
	static mins[3], maxs[3], origin[3];
	static i, j, size;

	if(!is_user_connected(id)){
		return false;
	}
	get_user_origin(id, origin, 0);

	size = ArraySize(zones);

	for(i = 0; i < size; i++){
		ArrayGetArray(zones, i, tempData);

		for(j = 0; j < 3; j++){
			mins[j] = tempData[0 + j*2];
			maxs[j] = tempData[1 + j*2];
		}

		if(checkIfInside(mins, maxs, origin)){
			return true;
		}
	}

	return false;
}


/////////////////////////////////////


public NewRound()
{
	remove_task(TASK_CHECK);
	remove_task(TASK_STARTCHECK);
	arrayset(PlayerWarn, 0, 33);
	for(new i = 1; i <= get_maxplayers(); i++){
		remove_task(TASK_SLAP + i);
	}
}

public RoundStart()
	set_task(get_pcvar_float(cvar_checkstarttime), "CheckUserRespawn", TASK_CHECK);

public client_connect(id)
{
	PlayerWarn[id]=0;
}
	
public client_disconnect(id)
{
	PlayerWarn[id]=0;
}
	
public CheckUserRespawn()
{
	for(new i = 1; i <= 32; i++)
	{	
		if(!is_user_alive(i) || get_user_team(i) != 1 || task_exists(TASK_SLAP + i))	
			continue;
			
		if(admin_immunity && get_user_flags(i) & ADMIN_BAN) // jesli CheckAdmin=0 i gracz to admin to pomin
			continue;
			
		if(getEntZone(i))
		{
			if(PlayerWarn[i] < max_warns){
				PlayerWarn[i]++;
				ColorChat(i, RED, "%s Czas gry na respie skonczyl sie! Ostrzezenie^3 %i^1 /^3 %i", Prefix, PlayerWarn[i], max_warns);
			}	
		}
		else if(PlayerWarn[i] > 0){
			PlayerWarn[i]--;
			ColorChat(i, RED, "%s Aktualna liczba ostrzezen^3 %i^1 /^3 %i", Prefix, PlayerWarn[i], max_warns);
		}
		
		if(PlayerWarn[i] >= max_warns){
			PenatlyPlayer(i);
		}
	}
	
	set_task(checkplayerspawn, "CheckUserRespawn", TASK_STARTCHECK);
}

public PenatlyPlayer(index)
{
	switch(penatly)
	{
		case 0: 
		{
			PlayerSlap(index + TASK_SLAP);
		}				
		case 1:{
			new m = cs_get_user_money(index);
			if(m > 0){
				cs_set_user_money(index, max(0, cs_get_user_money(index) - takemoney), 1);
				ColorChat(index, RED, "%s Zbyt dlugo przebywasz na respie. Za kare zabrano Ci^3 %i$!", Prefix, takemoney);	
			}
		}
		case 2:
		{
			user_kill(index, 0)
			ColorChat(index, RED, "%s Na respie mozna przebywac max^4 %.0f sekund^1 od startu rundy!", Prefix, get_pcvar_float(cvar_checkstarttime));
		}			
		case 3:{
			server_cmd("kick #%d ^"Zbyt dlugo przebywales na respie. Max %.0f sekund od startu rundy!^"", get_user_userid(index), get_pcvar_float(cvar_checkstarttime))					
		}
	}	
}

public PlayerSlap(id)
{
	id -= TASK_SLAP;

	if(getEntZone(id))
	{
		user_slap(id, takehp);
		ColorChat(id, RED, "%s Zbyt dlugo przebywasz na respie. Za kare zostales^4 uderzony!", Prefix);	
		if(is_user_alive(id)){
			set_task(1.0, "PlayerSlap", id + TASK_SLAP);
		}
	}
}

public Cvars()
{
	cvar_checkstarttime		= 	register_cvar("respawn_guard_start", "30.0");
	cvar_checkplayerspawn	=	register_cvar("respawn_guard_interval", "3.0");
	cvar_maxplayerwarn		=	register_cvar("respawn_guard_max_warns", "3");
	cvar_typepenatly		=	register_cvar("respawn_guard_penalty_type", "0");
	cvar_takehp				=	register_cvar("respawn_guard_hp", "20");
	cvar_takemoney			=	register_cvar("respawn_guard_money", "2000");
	cvar_admin				=	register_cvar("respawn_guard_admin_immunity", "0");
	
	checkplayerspawn	=	get_pcvar_float(cvar_checkplayerspawn);
	max_warns		=	get_pcvar_num(cvar_maxplayerwarn);
	penatly			=	get_pcvar_num(cvar_typepenatly);
	takehp			=	get_pcvar_num(cvar_takehp);
	takemoney		=	get_pcvar_num(cvar_takemoney);
	admin_immunity		=	get_pcvar_num(cvar_admin);
}