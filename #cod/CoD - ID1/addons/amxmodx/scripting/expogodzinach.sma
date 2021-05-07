#include <amxmodx>

#define minut(%1) ((%1)*60.0)

#define ILE_RAZY_WIEKSZY 2

new pcvarOdgodziny, 
     pcvarDogodziny;

public plugin_init()
{
	register_plugin("Podwojny exp w nocy", "1.1", "RiviT")
	
	pcvarOdgodziny = register_cvar("eog_expodgodziny", "22");
	pcvarDogodziny = register_cvar("eog_expdogodziny", "8");
	
      new timestr[3];
	get_time("%H", timestr, 2);
	new godzina = str_to_num(timestr);
	
	new odgodziny = get_pcvar_num(pcvarOdgodziny), 
	     dogodziny = get_pcvar_num(pcvarDogodziny);
	
	if(odgodziny > dogodziny)
	{
		if(godzina >= odgodziny || godzina < dogodziny)
			ZmienCvary()
	}
	else
	{
		if(godzina >= odgodziny && godzina < dogodziny)
			ZmienCvary()
	}		

}

public ZmienCvary()
{		
      server_cmd("cod_killxp %i;cod_winxp %i; cod_damagexp %i; cod_hsxp %i", (get_cvar_num("cod_killxp")*ILE_RAZY_WIEKSZY), (get_cvar_num("cod_winxp")*ILE_RAZY_WIEKSZY), (get_cvar_num("cod_damagexp")*ILE_RAZY_WIEKSZY), (get_cvar_num("cod_hsxp")*ILE_RAZY_WIEKSZY));
      server_cmd("cod_plantexp %i;cod_defuseexp %i; cod_rescueexp %i; cod_bombget %i; cod_bombdrop %i", (get_cvar_num("cod_plantexp")*ILE_RAZY_WIEKSZY), (get_cvar_num("cod_defuseexp")*ILE_RAZY_WIEKSZY), (get_cvar_num("cod_rescueexp")*ILE_RAZY_WIEKSZY), (get_cvar_num("cod_bombget")*ILE_RAZY_WIEKSZY), (get_cvar_num("cod_bombdrop")*ILE_RAZY_WIEKSZY));
}
