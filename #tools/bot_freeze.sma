#include < amxmodx >
#include < fakemeta >
#include <hamsandwich>

new bool:fr = false;

public plugin_init()
{
	register_plugin( "bot freeze", "1.9.4", "RiviT" );

	register_clcmd("say /f", "f");
	RegisterHam(Ham_Spawn, "player", "onSpawn", 1)
}

public f(id){
	fr = !fr;
	freezeAll();
	client_print(id, 3, "Boty %smrozone", fr ? "za" : "od")
}

public freezeAll(){
	for(new id = 1; id <= get_maxplayers(); id++){
		freezeBot(id)
	}
}

public onSpawn(id){
	if(!is_user_alive(id)){
		return HAM_IGNORED;
	}

	if(fr){
		freezeBot(id)
	}

	return HAM_IGNORED;
}

public freezeBot(id){
	if(is_user_connected(id) && is_user_bot(id)){
		if(fr){
			set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN); 
		}else{
			set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN); 
		}
	}
}