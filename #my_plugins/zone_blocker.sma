#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta_util>
#include <engine>

#if AMXX_VERSION_NUM < 183
#include <dhudmessage>
#endif

new const keys = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9) | (1 << 0)
new spr_dot;

enum _:kTasks (+= 100){
	TASK_ZONE = 100,
	TASK_WALLS
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

enum _:kZoneData{
	COORD = 5,
	X_SIGN
}

new tempData[kZoneData];

new map_cors_edit[6] // 0,1 - X || 2,3 - Y || 4,5 - Z
new x_sign = 0;
new current_zone = 0;
new Array:zones;
new zone_coords_num = 0;
new Array:createdZones;

public plugin_init() {
	register_plugin("Zone creator & invisible walls", "1.0", "RiviT")

	register_clcmd("say /strefy", "ZoneCreator")
	register_clcmd("radio3", "ZoneCreator")
	register_clcmd("radio2", "ZoneCreator")
	register_clcmd("radio1", "ZoneCreator")

	register_menucmd(register_menuid("Edit zone"), keys, "edit_zone_handler");

	register_logevent("logevent_round_start", 2, "1=Round_Start")
}

public plugin_precache(){
	zones = ArrayCreate(kZoneData, 3);
	createdZones = ArrayCreate();

	spr_dot = precache_model("sprites/dot.spr");
	precache_model("models/gib_skull.mdl")

	new currentmap[32], cfgdir[32];
	get_configsdir(cfgdir, charsmax(cfgdir)) 
	get_mapname(currentmap, charsmax(currentmap))
	formatex(save_path, charsmax(save_path), "%s/invisible_walls", cfgdir);
	if (!dir_exists(save_path)){
		mkdir(save_path);
	}

	format(save_path, charsmax(save_path), "%s/%s.ini", save_path, currentmap);
	CreateWalls();
}

public plugin_end(){
	if(zones != Invalid_Array){
		ArrayDestroy(zones);
	}

	if(createdZones != Invalid_Array){
		ArrayDestroy(createdZones);
	}
}

// EDITOR STUFF
/*------------------------------------------------------------------*/

public getZoneInfo(current_zone){
	ArrayGetArray(zones, current_zone, tempData);
	for(new i = 0; i < 6; i++){
		map_cors_edit[i] = tempData[i];
	}
	x_sign = tempData[X_SIGN];
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
			tempData[X_SIGN] = x_sign = 0;

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
			LoadAll(id);
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
	"\yEdit zone ^n^n\w1. Dimension: \y%c ^n\r    2. - | 3. +^n\y    4. - | 5. +^n  ^n6. Increment: %i ^n\r7. Delete zone^n\w8. X_sign: %c^n^n\y9. Zone ready!^n\r0. Back without saving",
	zone_coords[zone_coords_num], zone_increment, zone_coords[x_sign])

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
		case 7:{
			x_sign = (x_sign + 1) % 3;
		}
		case 8:{
			for(new i = 0; i < 6; i++){
				tempData[i] = map_cors_edit[i];
			}
			tempData[X_SIGN] = x_sign;
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
	static mins[3], maxs[3];
	static mid[3], i, orig[3];
	id -= TASK_ZONE;
	for(i = 0; i < 3; i++){
		mins[i] = map_cors_edit[0 + i*2];
		maxs[i] = map_cors_edit[1 + i*2];
		mid[i] = (mins[i] + maxs[i]) / 2;

	}
	get_user_origin(id, orig, 0);
	FX_Line(orig, mid, zone_colors[ZONE_LINE]);

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

	switch (x_sign) {
		case 0:{
			DrawLine(mid[0], maxs[1], maxs[2], mid[0], mins[1], mins[2], zone_colors[ZONE_RED])
			DrawLine(mid[0], maxs[1], mins[2], mid[0], mins[1], maxs[2], zone_colors[ZONE_RED])
		}
		case 1:{
			DrawLine(mins[0], mid[1], mins[2], maxs[0], mid[1], maxs[2], zone_colors[ZONE_RED])
			DrawLine(maxs[0], mid[1], mins[2], mins[0], mid[1], maxs[2], zone_colors[ZONE_RED])
		}
		case 2:{
			DrawLine(maxs[0], maxs[1], mid[2], mins[0], mins[1], mid[2], zone_colors[ZONE_RED])
			DrawLine(maxs[0], mins[1], mid[2], mins[0], maxs[1], mid[2], zone_colors[ZONE_RED])
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
		fprintf(fp, "%i %i %i %i %i %i %i^n",
			tempData[0], tempData[1], tempData[2], tempData[3], tempData[4], tempData[5], tempData[X_SIGN])
	}
	fclose(fp);

	client_print(0, print_chat, "Zones saved!")
}

public DeleteAll(){
	delete_file(save_path);

	client_print(0, print_chat, "Zones deleted!")
}

public LoadAll(id){
	ArrayClear(zones);

	new data[128];
	new fp = fopen(save_path, "r");
	if(!fp) return;

	new orgs[7][7];
	while(!feof(fp)){
		fgets(fp, data, charsmax(data));
		trim(data)
		if(data[0] == ';' || (data[0] == '/' && data[0] == '/') || strlen(data) < 2){
			continue;
		}

		arrayset(tempData, 0, kZoneData);
		parse(data, orgs[0], 6, orgs[1], 6, orgs[2], 6, orgs[3], 6, orgs[4], 6, orgs[5], 6, orgs[6], 6);
		for(new i = 0; i < kZoneData; i++){
			tempData[i] = str_to_num(orgs[i]);
		}
		ArrayPushArray(zones, tempData);
	}

	fclose(fp);

	if(id){
		client_print(id, print_chat, "Zones loaded!")
		log_amx("Loaded %i zones", ArraySize(zones))
	}
}

public CreateWalls(){
	LoadAll(0);
	ArrayClear(createdZones);

	new Float:mins[3], Float:maxs[3], Float:mid[3];
	for(new i = 0; i < ArraySize(zones); i++){
		ArrayGetArray(zones, i, tempData);
		for(new j = 0; j < 3; j++){
			mins[j] = float(tempData[0 + j*2]);
			maxs[j] = float(tempData[1 + j*2]);
			mid[j] = (mins[j] + maxs[j]) / 2.0;
			mins[j] -= mid[j];
			maxs[j] -= mid[j];
		}

		new ent = create_entity("info_target");
		if(!ent) continue;

		entity_set_string(ent, EV_SZ_classname, "invisible_wall");
		entity_set_model(ent, "models/gib_skull.mdl");
		entity_set_origin(ent, mid);
		set_pev(ent, pev_effects, EF_NODRAW);
		entity_set_int(ent, EV_INT_solid, SOLID_NOT);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);

		entity_set_size(ent, mins, maxs);

		ArrayPushCell(createdZones, ent);
	}
}

public WallsX(){
	static mins[3], maxs[3], mid[3], i, j;
	for(i = 0; i < ArraySize(zones); i++){
		ArrayGetArray(zones, i, tempData);
		for(j = 0; j < 3; j++){
			mins[j] = tempData[0 + j*2];
			maxs[j] = tempData[1 + j*2];
			mid[j] = (mins[j] + maxs[j]) / 2;
		}

		switch (tempData[X_SIGN]) {
			case 0:{
				DrawLine(mid[0], maxs[1], maxs[2], mid[0], mins[1], mins[2], zone_colors[ZONE_RED])
				DrawLine(mid[0], maxs[1], mins[2], mid[0], mins[1], maxs[2], zone_colors[ZONE_RED])
			}
			case 1:{
				DrawLine(mins[0], mid[1], mins[2], maxs[0], mid[1], maxs[2], zone_colors[ZONE_RED])
				DrawLine(maxs[0], mid[1], mins[2], mins[0], mid[1], maxs[2], zone_colors[ZONE_RED])
			}
			case 2:{
				DrawLine(maxs[0], maxs[1], mid[2], mins[0], mins[1], mid[2], zone_colors[ZONE_RED])
				DrawLine(maxs[0], mins[1], mid[2], mins[0], maxs[1], mid[2], zone_colors[ZONE_RED])
			}
		}
	}
}

public getCT(){
	new cnt = 0;
	for(new i = 1; i < 33; i++){
		if(!is_user_alive(i)){
			continue;
		}

		if(cs_get_user_team(i) != CS_TEAM_CT){
			continue;
		}

		cnt++;
	}

	return cnt;
}

public logevent_round_start(){
	if(getCT() < 5){
		modifyWalls(SOLID_BBOX);

		if(!task_exists(TASK_WALLS)){
			set_task(0.2, "WallsX", TASK_WALLS, _, _, "b");
		}

		client_print(0, 3, "Zbyt malo graczy w CT - gramy na bs A");
	}else{
		modifyWalls(SOLID_NOT);
		remove_task(TASK_WALLS);

		client_print(0, 3, "Wystarczajaca liczba CT - gramy na oba bsy");
	}
}

public modifyWalls(solid){
	for(new i = 0; i < ArraySize(createdZones); i++){
		new ent = ArrayGetCell(createdZones, i);
		if(!pev_valid(ent)){
			log_amx("cos sie popsulo ze strefa #%i", i);
			continue;
		}

		set_pev(ent, pev_solid, solid);
	}
}