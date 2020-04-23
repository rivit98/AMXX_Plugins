#include <amxmodx>
#include <fakemeta_util>

new Float:origin[3] = {43.0, 339.3, -531.9};
new Float:mins[3] = {-357.0, -172.0, -109.0};
new Float:maxs[3] = {357.0, 172.0, 109.0};

public plugin_precache()
{
	new mapname[64];
	get_mapname(mapname, charsmax(mapname));
	if(!equal(mapname, "de_rats_1337")) return;

	register_plugin("rats buyzone fix", "", "Rivit");

	createFakeBuyzone();
}

public createFakeBuyzone()
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"))
    if (!ent)
    {
    	set_fail_state("Error while creating new buyzone!");
    	return;
    }

    set_pev(ent, pev_team, 2);
    dllfunc(DLLFunc_Spawn, ent);
    engfunc(EngFunc_SetOrigin, ent, origin);
    engfunc(EngFunc_SetSize, ent, mins, maxs);
}