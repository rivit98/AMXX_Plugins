#include <amxmodx>

#define FUNCTION_SIZE 64

enum _:kInfo{
	PLUGINID,
	bool:ACTIVE,
	FUNCTION[FUNCTION_SIZE]
};

new gData[33][kInfo];

public plugin_init(){
	register_plugin("messagemode fixer", "1.0", "RiviT");
	register_clcmd("say", "_hookSay");
	register_clcmd("say_team", "_hookSay");
	register_clcmd("say /cancel", "_cancelMessagemode")
}

public _cancelMessagemode(id){
	resetData(id);
}

public _hookSay(id){
	if(gData[id][ACTIVE] == false){
		return 0;
	}

	new saytext[192]//, ret;
	read_args(saytext, 191);
	remove_quotes(saytext);

	new iFunction = get_func_id(gData[id][FUNCTION], gData[id][PLUGINID]);
	if(iFunction == -1){
		client_print(id, 3, "saomething goes wrong! TRY AGAIN SORRY");
		log_amx("function [%s] not found", gData[id][FUNCTION])
		resetData(id);
		return 1;
	}
	gData[id][ACTIVE] = false;
	callfunc_begin_i(iFunction, gData[id][PLUGINID]);
	callfunc_push_int(id);
	callfunc_push_str(saytext);
	callfunc_push_int(strlen(saytext));
	callfunc_end();


	return 1;
}

public resetData(id){
	for(new i = 0; i < kInfo; i++){
		gData[id][i] = 0;
	}
}

public client_disconnect(id){
	resetData(id)
}

public client_authorized(id){
	resetData(id)
}

public plugin_natives(){
	register_native("get_messagemode", "_get_messagemode");
	register_native("cancel_messagemode", "resetData", 1)
}

public _get_messagemode(plugin, params){
	new id = get_param(1);
	new function[FUNCTION_SIZE];
	get_string(2, function, 63);

	client_print(id, print_center, "******* Enter input on the chat *******");
	client_print(id, 3, "******* Enter input on the chat *******");
	client_print(id, 3, "******* Enter input on the chat *******");

	gData[id][PLUGINID] = plugin;
	gData[id][ACTIVE] = true;
	formatex(gData[id][FUNCTION], FUNCTION_SIZE, "%s", function);
}