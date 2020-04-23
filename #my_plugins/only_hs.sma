#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new g_fwid

public plugin_init()
{
	register_plugin("Only HS", "1.1", "Rivit")

	register_concmd("only_hs", "switchCmd", ADMIN_PASSWORD, "- <0|1> : Hs Only Mode = Disabled|Enabled")
	
	register_clcmd("clcmd_fullupdate", "fullupdateCmd")
}

public fullupdateCmd()
	return PLUGIN_HANDLED_MAIN

public switchCmd(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED

	new arg[2]
	read_argv(1, arg, 1)
	
	switch(str_to_num(arg))
	{
		case 0:
			unregister_forward(FM_TraceLine, g_fwid, 1)

		case 1:	
			g_fwid = register_forward(FM_TraceLine, "forward_traceline", 1)
	}
	return PLUGIN_HANDLED
}

public forward_traceline(Float:start[3], Float:end[3], conditions, id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED

	new entity2 = get_tr(TR_pHit)
	if(!is_user_alive(entity2)) return FMRES_IGNORED

	if(id == entity2) return FMRES_IGNORED

	if(get_tr(TR_iHitgroup) != HIT_HEAD)
	{
		set_tr(TR_flFraction, 1.0)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}