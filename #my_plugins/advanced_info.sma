#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta_util>
#include <engine>

#if AMXX_VERSION_NUM < 183
#include <dhudmessage>
#endif

// CONFIG STUFF
/*------------------------------------------------------------------*/

#define HELP_LINE					// comment this to disable help line during zone edit
#define MAX_TOLERANCE 		800		// Tolerance for zone approximation
#define MAX_ZONE_NAME 		32
#define MAX_INFO_LEN 		64
#define MAX_MESSAGES_HUD 	5
new const Float:player_zone_task_freq = 1.5;

/*------------------------------------------------------------------*/

new const m_bIsC4 = 385;
new const keys = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9) | (1 << 0)

new gMaxPlayers;
new g_msgHostageAdd, g_msgHostageDel;
new spr_dot;
new SyncHudObj;

enum _:kTasks (+= 100){
	TASKID_QUEUE = 100,
	TASKID_DECREMENT,
	TASKID_BLOCKER,
	TASKID_BOMB_CHECKER,
	TASKID_REMINDER,
	TASK_ZONE,
	TASKID_PLAYER_ZONE,
	TASKID_CAMPERS
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
new currentName[MAX_ZONE_NAME];
new Array:zones;
new zone_coords_num = 0;

enum _:kZoneData{
	COORD = 6,
	NAME[MAX_ZONE_NAME]
}

new tempData[kZoneData];

enum _:kCvars{
	CVAR_DISPLAY_STYLE,
	CVAR_ONLY_ZONE,
	CVAR_HUD_HOLDTIME,
	CVAR_HUD_POS,
	CVAR_HUD_COLOR,
	CVAR_INFO_DELAY,
	CVAR_BOMB_INFO,
	CVAR_BOMB_REMINDER,
	CVAR_BOMB_ON_RADAR,
	CVAR_PLAYER_ZONE,
	CVAR_PLAYER_ZONE_HUDPOS,
	CVAR_PLAYER_ZONE_COLOR,
	CVAR_KILL_RESP
};

new gPtrCvars[kCvars];
new activeColor[3];
new activeColor_player_zone[3];
//0 - TT, 1 - CT
new Array:messagesQueue[2]; 
new messagesOnScreen[2] = {0,0};
new messagesCount[2] = {0,0}
new const Float:hudpositions[3][2] = {
	{0.1, 0.01},
	{0.8, 0.25},
	{-1.0, 0.7}
}

new const Float:hudpositions_player_zone[4][2] = {
	{0.01, 0.2},
	{0.87, 0.02},
	{-1.0, 0.0},
	{0.02, 0.91}
}

new bool:infoBlocker;
new bool:isHostageMap;
new bool:bombPlanted;

public plugin_init() {
	register_plugin("Zone creator & advanced info", "1.0", "RiviT")

	register_clcmd("say /strefy", "ZoneCreator")
	register_clcmd("radio3", "ZoneCreator")
	register_clcmd("radio2", "ZoneCreator")
	register_clcmd("radio1", "ZoneCreator")
	register_clcmd("nameZ", "zonename_h")
	register_menucmd(register_menuid("Edit zone"), keys, "edit_zone_handler")

	register_event("DeathMsg", "DeathMsg", "a")
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_event("BombDrop",   "Event_BombPlanted", "a", "4=1");
	register_logevent("FreezeTimeEnd", 2, "1=Round_Start");

	RegisterHam(Ham_Spawn, "player", "HamSpawn", 1);

	cvarInit();
}

public cvarInit(){
	new gCvars[kCvars][][] = {
		{ "info_display_style", 	"2"			}, 	// Whose locations to show?  0 - nobody, 1 - victim, 2 - killer
		{ "info_display_zone_only", "0"			}, 	// Show only zone name in hud? 0 - no, 1 - yes
		{ "info_hud_holdtime", 		"5.0"		}, 	// Hud duration
		{ "info_hudpos", 			"2"			},	// hudpositions array, 0 - near radar, 1 - under death infos, 2 - under crosshair
		{ "info_hudcolor", 			"0 200 0"	},	// hud color RGB
		{ "info_block_time", 		"20.0"		},	// how long to block death messages after start round (in seconds)
		{ "info_bomb_info", 		"1"			},	// info about bomb status, 0 - off, 1 - on
		{ "info_bomb_reminder", 	"12.0"		},	// delay between bomb spot messages (cooldown, also duration of red blinking square on the radar)
		{ "info_bomb_on_radar", 	"1"			}, 	// display bomb position on radar? 0 - off, 1 - on
		{ "info_player_zone", 		"1"			},	// show player zone? 0 - off, 1 - on
		{ "info_hudpos_player", 	"2"			},	// hudpositions for player zone, 0 - under radar, 1 - above death infos, 2 - top mid, 3 - below chat
		{ "info_hudcolor_player", 	"90 222 50"	},	// hud color RGB
		{ "info_kill_resp_time",	"30.0"		}	// time after which resp-campers will be killed, 0.0 - disabled
	}

	for(new i = 0; i < kCvars; i++){
		gPtrCvars[i] = register_cvar(gCvars[i][0], gCvars[i][1]);
	}

	new mapname[4];
	get_mapname(mapname, charsmax(mapname));
	if(equal(mapname, "cs_")){
		isHostageMap = true;
	}

	gMaxPlayers = get_maxplayers();
	g_msgHostageAdd = get_user_msgid("HostagePos");
	g_msgHostageDel = get_user_msgid("HostageK");
	SyncHudObj = CreateHudSyncObj();
}

public plugin_precache(){
	zones = ArrayCreate(kZoneData, 10);
	messagesQueue[0] = ArrayCreate(MAX_INFO_LEN, 10);
	messagesQueue[1] = ArrayCreate(MAX_INFO_LEN, 10);

	spr_dot = precache_model("sprites/dot.spr");

	new currentmap[32], cfgdir[32];
	get_configsdir(cfgdir, charsmax(cfgdir)) 
	get_mapname(currentmap, charsmax(currentmap))
	formatex(save_path, charsmax(save_path), "%s/info_zone", cfgdir);
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
	for(new i = 0; i < 2; i++){
		if(messagesQueue[i] != Invalid_Array){
			ArrayDestroy(messagesQueue[i]);
		}
	}
}

public plugin_natives(){
	register_native("info_add_message", "native_info_add_message", 1);
	register_native("info_get_entity_zone", "native_info_get_entity_zone", 1);
}

public bool:native_info_get_entity_zone(id, buffer[], len){
	param_convert(2);
	return getEntZone(id, buffer, len);
}

public native_info_add_message(team, message[]){
	param_convert(2);

	if(team == 1 || team == 2){
		addMessageToQueue(team, message);
	}else{
		addMessageToQueue(1, message);
		addMessageToQueue(2, message);
	}
}


// EDITOR STUFF
/*------------------------------------------------------------------*/

public zonename_h(id){
	if (!(get_user_flags(id) & ADMIN_RCON)){
		return PLUGIN_CONTINUE;
	}
	new arg[MAX_ZONE_NAME];
	read_argv(1, arg, charsmax(arg));

	if(!strlen(arg))
	{
		client_cmd(id, "messagemode nameZ")
		client_print(id, 3, "Enter sth good")

		return PLUGIN_HANDLED
	}

	copy(currentName, MAX_ZONE_NAME, arg);

	edit_zone(id)

	return PLUGIN_HANDLED
}

public getZoneInfo(current_zone){
	ArrayGetArray(zones, current_zone, tempData);
	for(new i = 0; i < 6; i++){
		map_cors_edit[i] = tempData[i];
	}
	copy(currentName, MAX_ZONE_NAME, tempData[NAME])
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
				formatex(info, charsmax(info), "Edit zone: #%i %s", current_zone, tempData[NAME]);
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
			formatex(currentName, MAX_ZONE_NAME, "new_zone_%i", size)
			copy(tempData[NAME], MAX_ZONE_NAME, currentName)
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
	"\yEdit zone ^n^n\w1. Dimension: \y%c ^n\r    2. - | 3. +^n\y    4. - | 5. +^n  ^n6. Increment: %i ^n\r7. Delete zone^n\w8. Zone name: %s^n^n\y9. Zone ready!^n\r0. Back without saving",
	zone_coords[zone_coords_num], zone_increment, currentName)

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
			client_print(id, 3, "Enter zone name. Max %i characters", MAX_ZONE_NAME)
			client_cmd(id, "messagemode nameZ")

			return PLUGIN_CONTINUE
		}
		case 8:{
			for(new i = 0; i < 6; i++){
				tempData[i] = map_cors_edit[i];
			}
			copy(tempData[NAME], MAX_ZONE_NAME, currentName);
			ArraySetArray(zones, current_zone, tempData);
			arrayset(tempData, 0, kZoneData);

			client_print(id, 3, "Zone %s added! Don't forget to save zones!", currentName);

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
#if defined HELP_LINE
	static mid[3], i, orig[3];
#endif
	id -= TASK_ZONE;
	for(i = 0; i < 3; i++){
		mins[i] = map_cors_edit[0 + i*2];
		maxs[i] = map_cors_edit[1 + i*2];
#if defined HELP_LINE
		mid[i] = (mins[i] + maxs[i]) / 2;
#endif
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
		fprintf(fp, "%i %i %i %i %i %i %s^n",
			tempData[0], tempData[1], tempData[2], tempData[3], tempData[4], tempData[5], tempData[NAME])
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

		new cnt = 0;
		new size = strlen(data);
		for(new i = 0; i < size-1; i++){
			if(data[i] == ' '){
				if((++cnt) == 6){
					copy(tempData[NAME], MAX_ZONE_NAME, data[i+1]);
					break;
				}
			}
		}

		ArrayPushArray(zones, tempData);
	}

	fclose(fp);

	client_print(0, print_chat, "Zones loaded!");
	log_amx("Loaded %i zones", ArraySize(zones));
}


// QUEUE HANDLING
/*------------------------------------------------------------------*/

public addMessageToQueue(team, message[]){
	if(team != 1 && team != 2){ //just for sure
		return;
	}
	team--;

	ArrayPushString(messagesQueue[team], message);
	if(!task_exists(TASKID_QUEUE+team)){
		set_task(0.5, "messageWorker", TASKID_QUEUE+team);
	}
}

public messageWorker(team){
	team -= TASKID_QUEUE;

	new msg[64];
	ArrayGetString(messagesQueue[team], 0, msg, charsmax(msg));
	ArrayDeleteItem(messagesQueue[team], 0);

	if(messagesOnScreen[team] < MAX_MESSAGES_HUD){
		messagesOnScreen[team]++;

		new Float:time = get_pcvar_float(gPtrCvars[CVAR_HUD_HOLDTIME]);
		set_task(time+0.1, "decreaseMessages", TASKID_DECREMENT+team);
		showMessage(msg, team, time);
	}

	if(ArraySize(messagesQueue[team])){
		set_task(1.0, "messageWorker", TASKID_QUEUE+team);
	}
}

public decreaseMessages(team){
	team -= TASKID_DECREMENT;
	if(--messagesOnScreen[team] < 0){ //just for sure
		messagesOnScreen[team] = 0;
	}
}

public showMessage(msg[], team, Float:time){
	new hudPosIndex = get_pcvar_num(gPtrCvars[CVAR_HUD_POS]);
	new Float:hudPos = hudpositions[hudPosIndex][1] + (0.03 * messagesCount[team]);

	for(new id = 1; id <= gMaxPlayers; id++){
		if(!is_user_alive(id)){
			continue;
		}

		if(_:cs_get_user_team(id) == team + 1){ //ugly, i know
			set_dhudmessage(activeColor[0], activeColor[1], activeColor[2], hudpositions[hudPosIndex][0], hudPos, 0, 1.0, time, 0.1, 0.2);
			show_dhudmessage(id, msg)
		}
	}

	messagesCount[team] = (++messagesCount[team]) % MAX_MESSAGES_HUD
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

public bool:getEntZone(id, buffer[], len){
	static mins[3], maxs[3], mid[3], origin[3];
	static closestZone, closestZoneIdx, i, j, size, dist;
	static bool:res;

	if(1 <= id <= 32){
		if(!is_user_connected(id)){
			return false;
		}
		get_user_origin(id, origin, 0);
	}else{
		if(!pev_valid(id)){
			return false;
		}
		new Float:o[3]
		pev(id, pev_origin, o);
		for(j = 0; j < 3; j++){
			origin[j] = floatround(o[j], floatround_round)
		}
	}

	closestZone = 99999;
	closestZoneIdx = -1;
	size = ArraySize(zones);

	for(i = 0; i < size; i++){
		ArrayGetArray(zones, i, tempData);

		for(j = 0; j < 3; j++){
			mins[j] = tempData[0 + j*2];
			maxs[j] = tempData[1 + j*2];
			mid[j] = (mins[j] + maxs[j]) / 2;
		}

		res = checkIfInside(mins, maxs, origin);
		if(res){
			copy(buffer, len, tempData[NAME]);
			return true;
		}

		dist = get_distance(mid, origin);

		if(dist >= MAX_TOLERANCE){
			continue;
		}
		if(dist < closestZone){
			closestZone = dist;
			closestZoneIdx = i;
		}
	}

	if(closestZoneIdx != -1){
		ArrayGetArray(zones, closestZoneIdx, tempData);
		copy(buffer, len, tempData[NAME]);
		return true;
	}	

	return false;
}

public bool:can_see_fm(entindex1, entindex2)
{
	static Float:lookerOrig[3], Float:targetBaseOrig[3], Float:targetOrig[3], Float:temp[3], Float:flFraction;

	pev(entindex1, pev_origin, lookerOrig)
	pev(entindex1, pev_view_ofs, temp)
	lookerOrig[0] += temp[0]
	lookerOrig[1] += temp[1]
	lookerOrig[2] += temp[2]

	pev(entindex2, pev_origin, targetBaseOrig)
	pev(entindex2, pev_view_ofs, temp)
	targetOrig[0] = targetBaseOrig [0] + temp[0]
	targetOrig[1] = targetBaseOrig [1] + temp[1]
	targetOrig[2] = targetBaseOrig [2] + temp[2]

	engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
	if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		return false
	else 
	{
		get_tr2(0, TraceResult:TR_flFraction, flFraction)
		if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			return true
		else
		{
			targetOrig[0] = targetBaseOrig [0]
			targetOrig[1] = targetBaseOrig [1]
			targetOrig[2] = targetBaseOrig [2]
			engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				return true
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2] - 17.0
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					return true
			}
		}
	}
	return false
}

#if AMXX_VERSION_NUM < 183
stock bool:get_pdata_bool(ent, charbased_offset, intbase_linuxdiff = 5)
{
	return !!(get_pdata_int(ent, charbased_offset / 4, intbase_linuxdiff) & (0xFF<<((charbased_offset % 4) * 8)))
}
#endif

// EVENTS
/*------------------------------------------------------------------*/

public DeathMsg(vid, kid){
	if(infoBlocker){
		return HAM_IGNORED;
	}

	kid = read_data(1);
	vid = read_data(2);

	remove_task(vid + TASKID_PLAYER_ZONE)

	if(kid == vid || kid == 0){ //suicide or fall damage
		return HAM_IGNORED
	}

	new zone[MAX_ZONE_NAME], message[64];
	new showing_style = get_pcvar_num(gPtrCvars[CVAR_DISPLAY_STYLE]);
	new only_zone = get_pcvar_num(gPtrCvars[CVAR_ONLY_ZONE]);
	new team = _:cs_get_user_team(vid);
	new bool:res = false;
	switch(showing_style){
		case 1:{
			res = getEntZone(vid, zone, charsmax(zone));
			formatex(message, charsmax(message), "Zabity w: %s", zone);
		}
		case 2:{
			res = getEntZone(kid, zone, charsmax(zone));
			formatex(message, charsmax(message), "Zabity z: %s", zone);
		}
		default:{
		}
	}

	if(res && showing_style){
		if(only_zone){
			addMessageToQueue(team, zone);
		}else{
			addMessageToQueue(team, message)
		}
	}

	return HAM_IGNORED
}

public NewRound(){
	for(new i = 0; i < 2; i++){
		remove_task(TASKID_DECREMENT+i);
		remove_task(TASKID_QUEUE+i);
		ArrayClear(messagesQueue[i]);
		messagesOnScreen[i] = 0;
		messagesCount[i] = 0;
	}

	infoBlocker = false;
	bombPlanted = false;
	remove_task(TASKID_BLOCKER);
	remove_task(TASKID_REMINDER);
	remove_task(TASKID_BOMB_CHECKER);
	remove_task(TASKID_CAMPERS);

	if(get_pcvar_num(gPtrCvars[CVAR_BOMB_INFO]) && !isHostageMap){
		set_task(1.0, "paka_checker", TASKID_BOMB_CHECKER, _, _, "b");
	}

	new tmp[3][8], buf[16];
	get_pcvar_string(gPtrCvars[CVAR_HUD_COLOR], buf, charsmax(buf))
	parse(buf, tmp[0], 8, tmp[1], 8, tmp[2], 8);
	for(new i = 0; i < 3; i++){
		activeColor[i] = str_to_num(tmp[i]);
	}

	get_pcvar_string(gPtrCvars[CVAR_PLAYER_ZONE_COLOR], buf, charsmax(buf))
	parse(buf, tmp[0], 8, tmp[1], 8, tmp[2], 8);
	for(new i = 0; i < 3; i++){
		activeColor_player_zone[i] = str_to_num(tmp[i]);
	}
}

public FreezeTimeEnd(){
	new Float:time = get_pcvar_float(gPtrCvars[CVAR_INFO_DELAY]);
	if(time > 0.0){
		infoBlocker = true;
		set_task(time, "disableBlocker", TASKID_BLOCKER);
	}else{
		infoBlocker = false;
	}

	time = get_pcvar_float(gPtrCvars[CVAR_KILL_RESP]);
	if(time > 0.0){
		for(new i = 1; i <= gMaxPlayers; i++){
			if(!is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_T){
				continue;
			}
			set_dhudmessage(255, 255, 255, -1.0, 0.1, 0, 1.0, 5.0, 0.1, 0.2);
			show_dhudmessage(i, "Opusc respawn w ciagu %i sekund", floatround(time));
		}
		set_task(time, "killCampers", TASKID_CAMPERS)
	}
}

public Event_BombPlanted()
{
	bombPlanted = true;
	remove_task(TASKID_REMINDER);
}


// TASK STUFF
/*------------------------------------------------------------------*/

public disableBlocker(){
	infoBlocker = false;
}

public paka_checker(){
	static zone[MAX_ZONE_NAME], message[64], tmp[2];
	static Float:time;
	static iEnt;

	if(task_exists(TASKID_REMINDER)){
		return;
	}

	if(!bombPlanted){
		iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "weapon_c4");
		if(iEnt <= 0 || !pev_valid(iEnt)){
			return;
		}

		if(pev(iEnt, pev_owner) <= gMaxPlayers){
			iEnt = pev(iEnt, pev_owner);
		}
	}else{
		iEnt = 0;
		while((iEnt = find_ent_by_class( iEnt, "grenade" )))
		{
			if(get_pdata_bool(iEnt, m_bIsC4, 5)){
				break;
			}
		}
		if(iEnt <= 0 || !pev_valid(iEnt)){
			return;
		}
	}

	for(new id = 1; id <= gMaxPlayers; id++){
		if(!is_user_alive(id)){
			continue;
		}

		if(cs_get_user_team(id) != CS_TEAM_CT){
			continue;
		}

		if(can_see_fm(id, iEnt)){
			if(getEntZone(iEnt, zone, charsmax(zone))){
				time = get_pcvar_float(gPtrCvars[CVAR_BOMB_REMINDER]);
				tmp[0] = iEnt;
				tmp[1] = 1;
				reminderOff(tmp);
				tmp[1] = 0;
				set_task(2.0, "reminderOff", TASKID_REMINDER, tmp, 2, "a", floatround((time + 1.0) / 2.0))
				formatex(message, charsmax(message), "Bomba: %s", zone);
				addMessageToQueue(2, message);
			}
			//we found the bomb, nothing to do here
			return;
		}
	}
}

public reminderOff(param[]){
	if(get_pcvar_num(gPtrCvars[CVAR_BOMB_ON_RADAR]) == 0){
		return;
	}
	static Float:bombCoords[3];
	new ent = param[0];
	if(!pev_valid(ent)){
		return;
	}
	if(param[1] == 1){ // 1 - means, get new origin
		pev(ent, pev_origin, bombCoords);
	}

	for(new id = 1; id <= gMaxPlayers; id++){
		if(!is_user_alive(id)){
			return;
		}

		if(cs_get_user_team(id) != CS_TEAM_CT){
			continue;
		}

		message_begin(MSG_ONE_UNRELIABLE, g_msgHostageAdd, {0,0,0}, id)
		write_byte(1)
		write_byte(2)
		engfunc( EngFunc_WriteCoord, bombCoords[0]);
		engfunc( EngFunc_WriteCoord, bombCoords[1]);
		engfunc( EngFunc_WriteCoord, bombCoords[2]);
		message_end()
							
		message_begin(MSG_ONE_UNRELIABLE, g_msgHostageDel, {0,0,0}, id)
		write_byte(2)
		message_end()
	}
}

public killCampers(){
	new zone[MAX_ZONE_NAME];
	for(new i = 1; i <= gMaxPlayers; i++){
		if(!is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_T){
			continue;
		}

		if(getEntZone(i, zone, charsmax(zone))){
			if(containi(zone, "resp") != -1 && containi(zone, "tt") != -1){
				user_kill(i);
				set_dhudmessage(255, 255, 255, -1.0, 0.4, 0, 1.0, 5.0, 0.1, 0.2);
				show_dhudmessage(i, "Zostales zabity za siedzenie na respie");
			}
		}
	}
}

// PLAYER ZONE INFO
/*------------------------------------------------------------------*/

#if AMXX_VERSION_NUM < 183
public client_disconnect(id)
#else
public client_disconnected(id)
#endif
{
	remove_task(id + TASKID_PLAYER_ZONE);
}

public HamSpawn(id){
	if(!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id)){
		return HAM_IGNORED;
	}

	if(get_pcvar_num(gPtrCvars[CVAR_PLAYER_ZONE])){
		remove_task(id + TASKID_PLAYER_ZONE);
		set_task(player_zone_task_freq, "showPlayerZone", TASKID_PLAYER_ZONE + id, _, _, "b")
	}

	return HAM_IGNORED;
}

public showPlayerZone(id){
	new CsTeams:team, zone[MAX_ZONE_NAME], hudpos;

	id -= TASKID_PLAYER_ZONE;

	if(!is_user_alive(id)){
		remove_task(id + TASKID_PLAYER_ZONE);
		return;
	}

	team = cs_get_user_team(id);

	if(team != CS_TEAM_T && team != CS_TEAM_CT){
		remove_task(id + TASKID_PLAYER_ZONE);
		return;
	}

	hudpos = get_pcvar_num(gPtrCvars[CVAR_PLAYER_ZONE_HUDPOS]);

	if(getEntZone(id, zone, charsmax(zone))){
		set_hudmessage(activeColor_player_zone[0], activeColor_player_zone[1], activeColor_player_zone[2], hudpositions_player_zone[hudpos][0], hudpositions_player_zone[hudpos][1], 0, _, player_zone_task_freq, 0.4, 1.1, -1);
		ShowSyncHudMsg(id, SyncHudObj, zone);	
	}
}