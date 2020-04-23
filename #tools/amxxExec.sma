#include <amxmodx>
#include <amxmisc>


public plugin_cfg(){
	new lokalizacja_cfg[33];
	get_configsdir(lokalizacja_cfg, charsmax(lokalizacja_cfg));
	server_cmd("exec %s/amxx.cfg", lokalizacja_cfg);
	server_exec();
}