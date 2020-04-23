#include amxmodx
#include fakemeta

public plugin_init()
{
	register_plugin("", "", "")
	
	new classname[128]
	for(new i = 0; i <= engfunc(EngFunc_NumberOfEntities); i++)
	{
		if(!pev_valid(i)) continue;
		
		pev(i, pev_classname, classname, 127)
		log_to_file("addons/amxmodx/list_entity.txt", classname)
	}
}