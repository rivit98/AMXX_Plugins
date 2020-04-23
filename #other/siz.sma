#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include < engine >
#include < hamsandwich >
#include <fun>


#define ACCESS_HAS ADMIN_RCON

#define PLUGIN_NAME "Schowaj i Znajdz"
#define HAS_VERSION "2.0"

new hidesongs[][] = 
{ 
	"Prospero03", "Prospero05", "Suspense05", 
	"Suspense03", "Suspense01" 
}

new seekerssongs[][] = 
{ 
	"Half-Life03", "Half-Life04", "Half-Life05", 
	"Half-Life06", "Half-Life07", "Half-Life09", 
	"Half-Life10", "Half-Life14", "Half-Life15" 
}

new seekedsongs[][] = 
{ 
	"Half-Life01", "Half-Life02", "Half-Life08", 
	"Half-Life11", "Half-Life12", "Half-Life13", 
	"Half-Life16", "Half-Life17" 
}

new mincats = 1; 
new mice = 1; 
new Float:hidetime = 45.0; 

new flashlight[33];
new color[33];

new g_color[][] = 
{ 
	{100,0,0},{0,100,0},{0,0,100},{0,100,100},{100,100,0}
}

new skies[][] = { "space" };

new flashlight_custom, flashlight_radius, flashlight_only_ct;
new gmsgFlashlight, gmsgTeamInfo;

new active; 
new phase; 
new killed[32];
new s_gravity, s_roundtime, s_freezetime, s_limitteams, s_autoteambalance, s_alltalk, s_footsteps, s_friendlyfire, s_startmoney;  // Used to save original server CVars values
new Float:s_buytime; 
new transferring[33]; 
new gmsgScreenFade;
//new inround = 0
new counter; 
new hasdbg = 0; 
new sound[33];
new bool:hostageMade;

#define RED get_pcvar_num(soul_bodyglow_r)
#define GREEN get_pcvar_num(soul_bodyglow_g)
#define BLUE get_pcvar_num(soul_bodyglow_b)

new soul_bodyglow_r;
new soul_bodyglow_g;
new soul_bodyglow_b;
new soul_bodyglow;
new g_iCamera[ 33 ];
new bool:g_bFlying[ 33 ];
new bool:g_bActivated[ 33 ];

new amx_hs_light, amx_hs_flash, radius_cvar;
new autolaunch;

new g_opt[33][2];
new g_decompte;

new amx_namegame;

// Fakemeta Convertion
#define OFFSET_TEAM		114
#define OFFSET_NVGOGGLES	129
#define HAS_NVGOGGLES		(1<<0)

#define fm_create_entity(%1)	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
#define fm_is_valid_ent(%1)	pev_valid(%1)

enum
{
	FM_TEAM_UNASSIGNED,
	FM_TEAM_T,
	FM_TEAM_CT,
	FM_TEAM_SPECTATOR,
	
	FM_TEAM_MAX
};

stock get_maxcats() 
{
	new playersnum, Float:div, ndiv, result;
	playersnum = get_playersnum(1);
	div = float(playersnum) / 6;
	ndiv = floatround(div,floatround_floor);
	
	if( ndiv < mincats )
		result = mincats;
	else
		result = ndiv;

	return result;
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, HAS_VERSION, "djeyL/xKanGur/INeedHelp/xPaw/Tolsty"); 
	
	register_cvar("amx_cc_version", HAS_VERSION, FCVAR_SERVER);
	set_cvar_string("amx_cc_version", HAS_VERSION)
	register_cvar("amx_cc_decompte", "0");
	amx_hs_light		= register_cvar("siz_light","1");
	amx_hs_flash		= register_cvar("siz_flash","4"); 
	amx_namegame  = register_cvar( "amx_namegame", "Schowaj i Znajdz v2.0" );
	radius_cvar		= register_cvar("siz_radius_cvar","110");
	autolaunch		= register_cvar("amx_autostart","1");	
	flashlight_custom	= register_cvar("siz_flashlight_custom","1");
	flashlight_radius	= register_cvar("siz_flashlight_radius","23");
	flashlight_only_ct	= register_cvar("siz_flashlight_only_ct","1"); 
	
	register_concmd("amx_siz", "hideandseek", ACCESS_HAS, "- <on|off|mincats x|mice x|hidetime x>");
	register_clcmd("jointeam",	"jointeam");
	register_clcmd("say /muzyka",	"stopsound");
	register_clcmd("chooseteam",	"chooseteam");
	register_clcmd("buy",		"buy");

	register_event("SendAudio",	"endround",	"a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw");
	register_event("TextMsg",	"gamestart",	"a", "2&#Game_C", "2&#Game_w");
	register_event("RoundTime",	"newround",	"bc");
	register_event("CurWeapon",	"switchweapon",	"be", "1=1");
	register_event("DeathMsg",	"deathmsg",	"a");
	register_event("ScreenFade",	"FlashedEvent",	"be","4=255","5=255","6=255","7>199");
	register_event("Flashlight",	"event_flashlight", "b");
	
	register_forward(FM_PlayerPreThink, "fwdPlayerPreThink", 0);
	register_forward( FM_GetGameDescription, "GameDesc" );


	soul_bodyglow = register_cvar("soul_bodyglow","1");
	soul_bodyglow_r = register_cvar("soul_bodyglow_r","255");
	soul_bodyglow_g = register_cvar("soul_bodyglow_g","255");
	soul_bodyglow_b = register_cvar("soul_bodyglow_b","0");

	register_forward( FM_CmdStart, "FwdCmdStart" );

	register_clcmd("say /freelook", "CmdActivate");
	register_clcmd("say /firstperson", "CmdActivate");
	register_clcmd("freelook", "CmdActivate");
	register_clcmd("firstperson", "CmdActivate");

	new iEntity;
	new iMaxPlayers = get_maxplayers( );
	for( new client = 1; client <= iMaxPlayers; client++ ) {
		iEntity = create_entity( "info_target" );
		entity_set_string( iEntity, EV_SZ_classname, "player_soul" );
		entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_FLY ); // noclip is buggy when going deep into walls :(
		entity_set_int( iEntity, EV_INT_solid, SOLID_NOT );
		entity_set_model( iEntity, "models/w_usp.mdl" );
		set_rendering( iEntity, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 0 );
		g_iCamera[ client ] = iEntity;

	}
	
	active = 0;
	gmsgScreenFade	= get_user_msgid("ScreenFade");
	gmsgFlashlight	= get_user_msgid("Flashlight");
	gmsgTeamInfo	= get_user_msgid( "TeamInfo" );
	
	set_cvar_num("mp_flashlight",1);
	set_task(15.0, "lauchgame", 165);
}

public GameDesc( ) {
static namegame[32];
get_pcvar_string( amx_namegame, namegame, 31 );
forward_return( FMV_STRING, namegame );
return FMRES_SUPERCEDE;
}

public render(client) {
	set_user_rendering(client,21,0,0,0,0,0)
}

public FwdPlayerSpawn( client ) {
	if( is_user_alive( client ) && g_bFlying[ client ] ) {
		ResetCamera( client );
	}
}

public FwdPlayerDeath( client ) {
	if( !is_user_alive( client ) && g_bFlying[ client ] ) {
		ResetCamera( client );
	}
}

public CmdActivate(client) {
	if(get_user_team(client) == 2) 
		return PLUGIN_HANDLED;

	if( g_bActivated[client] )
		g_bActivated[client] = false;
	else {
		g_bActivated[client] = true;
	}

	return PLUGIN_CONTINUE;
}

public FwdCmdStart( client, ucHandle ) {
	if( !is_user_alive( client ) ) {
		return;
	}

	static iButtons;
	iButtons = get_uc( ucHandle, UC_Buttons );

	if( g_bActivated[client] ) {
		if( g_bFlying[ client ] ) {
			ResetCamera( client );
			g_bActivated[client] = false;
		} else if( pev( client, pev_flags ) & FL_ONGROUND && !( iButtons & IN_DUCK )) {
			g_bFlying[ client ] = true;
			attach_view( client, g_iCamera[ client ] );
			static Float:vOrigin[ 3 ]; 
			entity_get_vector( client, EV_VEC_origin, vOrigin );
			entity_set_vector( g_iCamera[ client ], EV_VEC_origin, vOrigin );
			vOrigin[2] -= 15;
			entity_set_vector( client , EV_VEC_origin, vOrigin );
			if( get_pcvar_num(soul_bodyglow) ) {
				set_rendering(client,kRenderFxGlowShell,RED,GREEN,BLUE,kRenderNormal,50);
				client_print(client, print_chat, "[SiZ] Twoje cialo jest bardziej widocznie w trybie freelook!");
			}

			g_bActivated[client] = false;

		} else {
			g_bActivated[client] = false;
			client_print(client, print_chat, "[SiZ] Nie mozesz przejsc w tryb freelook bedac w powietrzu lub kucajac!");
		}
	}
	if( g_bFlying[ client ] ) {

		static Float:vAimVelocity[ 3 ];
		velocity_by_aim( client, 250, vAimVelocity );

		new Float:vVelocity[ 3 ];
		if( iButtons & IN_FORWARD ) {
			vVelocity[ 0 ] += vAimVelocity[ 0 ];
			vVelocity[ 1 ] += vAimVelocity[ 1 ];
			vVelocity[ 2 ] += vAimVelocity[ 2 ];
		}
		if( iButtons & IN_BACK ) {
			vVelocity[ 0 ] -= vAimVelocity[ 0 ];
			vVelocity[ 1 ] -= vAimVelocity[ 1 ];
			vVelocity[ 2 ] -= vAimVelocity[ 2 ];
		}
		if( iButtons & IN_MOVERIGHT ) {
			vVelocity[ 0 ] += vAimVelocity[ 1 ];
			vVelocity[ 1 ] -= vAimVelocity[ 0 ];
		}
		if( iButtons & IN_MOVELEFT ) {
			vVelocity[ 0 ] -= vAimVelocity[ 1 ];
			vVelocity[ 1 ] += vAimVelocity[ 0 ];
		}
		entity_set_vector( g_iCamera[ client ], EV_VEC_velocity, vVelocity );
		entity_get_vector( client, EV_VEC_v_angle, vVelocity );
		entity_set_vector( g_iCamera[ client ], EV_VEC_angles, vVelocity );
	}

}

ResetCamera( client ) {
	g_bFlying[ client ] = false;
	attach_view( client, client );
	static Float:vOrigin[ 3 ]; 
	entity_get_vector( client, EV_VEC_origin, vOrigin );
	vOrigin[2] += 15;
	delay_duck(client)
	entity_set_vector( client , EV_VEC_origin, vOrigin );
	render(client)
}  

delay_duck(client)
{
	set_task(0.01, "force_duck", client);
	set_entity_flags(client, FL_DUCKING, 1);
}

public force_duck(client)
{
	set_entity_flags(client, FL_DUCKING, 1);
} 

public stopsound(id) {

	if(sound[id]) {
		client_cmd(id,"mp3 stop");
		client_cmd(id, "stopsound");
		client_print(id, print_chat, "[SiZ] Muzyka wylaczona!");
		sound[id] = false;
	}
	else {
		new a = random_num(0, sizeof(hidesongs) - 1);
		client_print(id, print_chat, "[SiZ] Muzyka wlaczona!");
		client_cmd(id, "mp3 play media/%s", hidesongs[a]);
		sound[id] = true;
	}
}

public client_putinserver(id) 
{
	sound[id] = true;
	random_num(0, sizeof( g_color ) - 1);
}

public lauchgame(taskid) 
{
	if(!get_pcvar_num(autolaunch))
		return;
	
	server_cmd("amx_siz on");
}

public plugin_precache()
{
	new fog = fm_create_entity("env_fog");
	//DispatchKeyValue(fog, "density", "0.000650");
	fm_set_kvd(fog, "density", "0.000650");

	new r = random_num(1, 128);
	new g = random_num(1, 128);
	new b = random_num(1, 128);
	
	new rouge[3], vert[3], bleu[3];
	num_to_str(r,rouge,2);
	num_to_str(g,vert,2);
	num_to_str(b,bleu,2);
	
	new test[12];
	formatex(test,11,"%s %s %s",rouge,vert,bleu);
	//DispatchKeyValue(fog,"rendercolor",test);
	fm_set_kvd(fog,"rendercolor",test);

	new rand = random_num(0, sizeof(skies)-1);
	set_cvar_string("sv_skyname", skies[rand]);

	register_forward(FM_KeyValue, "fwd_KeyValue", 1);
}

public client_connect(id)
{
	sound[id] = true;
	if(!is_user_bot(id)) 
	{
		get_user_info(id,"_vgui_menus",g_opt[id],1);
		set_user_info(id,"_vgui_menus","0");
	}
}

public client_disconnect(id)
{
	sound[id] = true;

	new i;
	transferring[id] = 0;
	
	for (i=0; i<32; i++)
	{
		if (killed[i] == id)
		{
			break;
		}
	}
	
	if(i == 32) 
		return;
	
	if (killed[i] == id)
	{
		for (i++; i<32 && killed[i]!=0; i++)
		{
			killed[i-1] = killed[i];
		}
		killed[i] = 0;
	}

	if( is_user_alive( id ) && g_bFlying[ id ] ) {
		ResetCamera( id );
	}
}


public hideandseek(id, level, cid)
{
	new arg[16];
	new pnum;
	new cts;
	new players[32];
	new i;
	
	if (read_argv(1, arg, 15) == 0)
	{
		console_print(id, "* Schowaj i znajdz v%s by xKanGur jest aktualnie %s [Czas na ukrycie: %d, szukajacych: %d, ukrywajacych: %d, www.CS-Wysypisko.pl]", HAS_VERSION, active ? "wlaczony." : "wylaczony.", floatround(hidetime), mincats, mice);
		return PLUGIN_HANDLED;
	}
	
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED;
	}
	
	if (equal(arg, "mincats") || equal(arg, "chatsmin"))
	{
		if (read_argv(2, arg, 15) == 0)
		{
			console_print(id, "* SiZ: Ilosc szukajacych = %d", mincats);
			return PLUGIN_HANDLED;
		}
		else
		{
			if (cmd_access(id, level, cid, 1))
			{
				if (active != 0)
				{
					console_print(id, "* SiZ: Nie mozesz zmienic zasad podczas gry!");
					return PLUGIN_HANDLED;
				}
				i = str_to_num(arg);
				if (i>0)
				{
					mincats = i;
					console_print(id, "* SiZ: Ilosc 'szukajacych' ustawiono %d", mincats);
				}
				else
				{
					console_print(id, "* SiZ: bledna wartosc 'szukajacych' (minimum: 1)");
				}
				return PLUGIN_HANDLED;
			}
		}
	}
	else if (equal(arg, "mice") || equal(arg, "souris"))
	{
		if (read_argv(2, arg, 15) == 0)
		{
			console_print(id, "* SiZ: Ilosc ukrywajacych sie = %d", mice);
			return PLUGIN_HANDLED;
		}
		else
		{
			if (cmd_access(id, level, cid, 1))
			{
				if (active != 0)
				{
					console_print(id, "* SiZ: Nie mozesz zmienic zasad podczas gry!");
					return PLUGIN_HANDLED;
				}
				
				i = str_to_num(arg);
				if (i>=0)
				{
					mice = i;
					console_print(id, "* SiZ: Ilosc 'ukrywajacych' ustawiono na %d", mice);
				}
				else
				{
					console_print(id, "* SiZ: bledna wartosc 'ukrywajacych' (minimum: 0)");
				}
				return PLUGIN_HANDLED;
			}
		}
	}
	else if (equal(arg, "hidetime") || equal(arg, "dureeplanque"))
	{
		if (read_argv(2, arg, 15) == 0)
		{
			console_print(id, "* SiZ: Czas na schowanie sie = %d sekund", floatround(hidetime));
			return PLUGIN_HANDLED;
		}
		else
		{
			if (cmd_access(id, level, cid, 1))
			{
				if (active != 0)
				{
					console_print(id, "* SiZ: Nie mozesz zmienic zasad podczas gry!");
					return PLUGIN_HANDLED;
				}
				
				i = str_to_num(arg);
				if (i>=15)
				{
					hidetime = float(i);
					console_print(id, "* SiZ: 'Czas na schowanie' ustawiono na %d sekund", floatround(hidetime));
				}
				else
				{
					console_print(id, "* SiZ: Bledna wartosc 'czasu na schowanie' (minimum: 15 sekund)");
				}
				return PLUGIN_HANDLED;
			}
		}
	}
	else if ((equali(arg, "on") || equal(arg, "1") || equal(arg, "start")) && active == 0)
	{
		client_print(0, print_chat, "[SiZ] Rozpoczecie gry!");
		
		new ConfigsDir[128]
		get_configsdir(ConfigsDir, 127)
		server_cmd("exec %s/siz-on.cfg", ConfigsDir);
		
		active = 1;
		phase = 0;
		
		s_gravity = get_cvar_num("sv_gravity");
		s_roundtime = get_cvar_num("mp_roundtime");
		s_freezetime = get_cvar_num("mp_freezetime");
		s_limitteams = get_cvar_num("mp_limitteams");
		s_autoteambalance = get_cvar_num("mp_autoteambalance");
		s_alltalk = get_cvar_num("sv_alltalk");
		s_footsteps = get_cvar_num("mp_footsteps");
		s_friendlyfire = get_cvar_num("mp_friendlyfire");
		s_startmoney = get_cvar_num("mp_startmoney");
		s_buytime = get_cvar_float("mp_buytime");
		server_cmd("amx_restrict on");
		
		set_cvar_num("sv_gravity", 150);
		set_cvar_num("mp_roundtime", 6);
		set_cvar_num("mp_freezetime", 1);
		set_cvar_num("mp_limitteams", 0);
		set_cvar_num("mp_autoteambalance", 0);
		set_cvar_num("sv_alltalk", 1);
		set_cvar_num("mp_friendlyfire", 0);
		set_cvar_num("mp_startmoney", 16000);
		set_cvar_num("mp_buytime", 5);
		
		if(get_pcvar_num(amx_hs_light)) {
			fm_set_lights("d"); 
		}
		
		new maxcats = get_maxcats();
		get_players(players, cts, "e", "CT");
		if (cts > maxcats)
		{
			for (i=maxcats; i<cts; i++)
			{
				if (hasdbg) 
					client_print(0, print_chat,"* SiZ[init]: Wystarczajaco graczy w druzynie szukajacych")
				
				fm_set_user_team(players[i], FM_TEAM_T);
			}
		}
		else if (cts < mincats)
		{
			get_players(players, pnum, "e", "TERRORIST");
			for (i=0; cts<mincats && i<pnum; i++)
			{
				if (hasdbg) 
					client_print(0, print_chat, "* SiZ[init]: Potrzeba wiecej graczy w druzynie szukajacych")
				
				fm_set_user_team(players[i], FM_TEAM_CT);
				cts++;
			}
		}
		set_task(2.0, "plugin_timer", 412563, "", 0, "b")
	}
	else if ((equali(arg, "off") || equal(arg, "0") || equal(arg, "stop")) && active != 0)
	{
		client_print(0, print_chat, "[SiZ] Gra przerwana!");
		
		new ConfigsDir[128]
		get_configsdir(ConfigsDir, 127)
		server_cmd("exec %s/siz-off.cfg", ConfigsDir)
		
		active = 0;
		
		if (task_exists(412563))
			remove_task(412563);
		
		set_cvar_num("sv_gravity", s_gravity);
		set_cvar_num("mp_roundtime", s_roundtime);
		set_cvar_num("mp_freezetime", s_freezetime);
		set_cvar_num("mp_limitteams", s_limitteams);
		set_cvar_num("mp_autoteambalance", s_autoteambalance);
		set_cvar_num("sv_alltalk", s_alltalk);
		set_cvar_num("mp_footsteps", s_footsteps);
		set_cvar_num("mp_friendlyfire", s_friendlyfire);
		set_cvar_num("mp_startmoney", s_startmoney);
		set_cvar_float("mp_buytime", s_buytime);
		server_cmd("amx_restrict off");
		if(get_pcvar_num(amx_hs_light)) {
				fm_set_lights("d"); 
		}

		remove_task(412564);
		remove_task(412565);
		remove_task(412566);
		remove_task(147258);
		
		get_players(players, pnum);
		for(i=0; i<pnum; i++)
		{
			fm_set_user_maxspeed(players[i], 240.0);
			fm_set_user_gravity(players[i], 1.0);
			fm_set_user_godmode(players[i], 0);
		}
		set_cvar_num("sv_restart", 3);
	}
	return PLUGIN_HANDLED;
}

public plugin_timer()
{
	new ts[32];
	new cts[32];
	new tnum;
	new ctnum;
	new i;
	new specialcase = 0;
	new maxcats = get_maxcats();
	get_players(ts, tnum, "e", "TERRORIST");
	get_players(cts, ctnum, "e", "CT");
	
	if(ctnum==0)
		specialcase = 1;
	
	if(tnum>=mice && ctnum>=mincats)
	{
		if(active == 1)
		{
			client_print(0, print_chat, "[SiZ] Wystarczajaca ilosc graczy!");
			active = 2;
			set_cvar_num("sv_restart", 1);
		}
		else if (active == 3)
		{
			if (phase == 1)
			{
				for(i=0; i<tnum; i++)
				{
					fm_set_user_maxspeed(ts[i], 400.0);
					fm_set_user_gravity(ts[i], 1.0);
				}
				for(i=0; i<ctnum; i++)
				{
					fm_set_user_maxspeed(cts[i], 0.1);
					fm_set_user_gravity(cts[i], 10.0);
				}
			}
			else if (phase == 2)
			{
				for(i=0; i<tnum; i++)
				{
					fm_set_user_maxspeed(ts[i], 0.1);
					fm_set_user_gravity(ts[i], 10.0);
				}
				for(i=0; i<ctnum; i++)
				{
					fm_set_user_maxspeed(cts[i], 400.0);
					fm_set_user_gravity(cts[i], 1.0);
				}
			}
		}
	}
	else
	{
		if (ctnum < mincats)
		{
			for(i=tnum-1; i>=0 && ctnum<maxcats; i--)
			{
				if (hasdbg) 
					client_print(0,print_chat,"* SiZ[timer]: Potrzeba wiecej graczy w druzynie szukajacych")
				
				fm_set_user_team(ts[i], FM_TEAM_CT);
				ctnum++;
				tnum--;
			}
		}
		else if (ctnum>maxcats)
		{
			for(i=ctnum-maxcats; i>=0 && tnum<mice; i--)
			{
				if (hasdbg) 
					client_print(0,print_chat,"* SiZ[timer]: Potrzeba wiecej graczy w druzynie szukajacych");
				
				fm_set_user_team(cts[i], FM_TEAM_T);
				ctnum --;
				tnum ++;
			}
		}
		
		if (ctnum>=mincats && ctnum<=maxcats && tnum>=mice)
		{
			if(!specialcase)
				set_cvar_num("sv_restart", 1);

		}
		else
		{
			if (active == 1)
			{
				set_hudmessage(0, 255, 0, 0.05, 0.4, 0, 6.0, 5.0, 0.5, 0.15, 7);
				show_hudmessage(0, "[SiZ] Oczekiwanie na graczy...");
			}
			else
			{
				set_hudmessage(0, 255, 0, 0.05, 0.4, 0, 6.0, 5.0, 0.5, 0.15, 7);
				show_hudmessage(0, "[SiZ] Oczekiwanie na graczy...");
				
				active = 1;
				remove_task(412564);
				remove_task(412565);
				
				for(i=0; i<tnum; i++)
				{
					fm_set_user_maxspeed(ts[i], 240.0);
					fm_set_user_gravity(ts[i], 1.0);
				}
				for(i=0; i<ctnum; i++)
				{
					fm_set_user_maxspeed(cts[i], 240.0);
					fm_set_user_gravity(cts[i], 1.0);
				}
				if(get_pcvar_num(amx_hs_light)) {
					fm_set_lights("d"); 
						
				}
				
				set_cvar_num("sv_restart", 1);
			}
		}
	}
	
	get_players(ts, tnum, "b");
	for(tnum--; tnum>=0; tnum--)
	{
		fm_set_user_maxspeed(ts[tnum], 240.0);
		fm_set_user_gravity(ts[tnum], 1.0);
	}
}

public newround()
{

	new players[32];
	new pnum;
	new i;
	new maxcats = get_maxcats();
	
	if (read_data(1) == floatround(get_cvar_float("mp_roundtime")*60.0))
	{
		remove_task(147258);
		//inround = 1;
		
		if(active < 2)
			return;
			
		get_players(players, pnum, "e", "CT");
		get_players(players, i, "e", "TERRORIST");
		if (pnum>=mincats && pnum<=maxcats && i>=mice)
		{
			set_hudmessage(0, 255, 0, 0.05, 0.4, 0, 6.0, 5.0, 0.5, 0.15, 7);
			show_hudmessage(0, "[SiZ] Terrorysci, macie %d sekund na ukrycie sie!", floatround(hidetime));
			client_cmd(0, "spk radio/com_getinpos");
			set_cvar_num("mp_footsteps", 0);
			
			if (active == 2)
				active = 3;
			
			phase = 1;
			
			if(get_pcvar_num(amx_hs_light)) {
				fm_set_lights("d"); 

			}
			
			for (i=0; i<32; i++)
			{
				killed[i] = 0;
			}
			
			get_players(players,pnum,"e","TERRORIST");
			new a = random_num(0, sizeof(hidesongs) - 1);
			for (i=0; i<pnum; i++)
			{
				engclient_cmd(players[i], "weapon_knife");
				fm_set_user_godmode(players[i], 1);
				fm_set_user_nvg(players[i], 1);
				
				
				flashlight[players[i]] = 0
				render(players[i])
				if(sound[players[i]])
					client_cmd(players[i], "mp3 play media/%s", hidesongs[a]);
			}
			
			get_players(players,pnum,"e","CT");
			for (i=0; i<pnum; i++)
			{
				engclient_cmd(players[i], "weapon_knife");
				f2b(players[i], 1);
				fm_set_user_godmode(players[i], 1);
				fm_set_user_nvg(players[i], 0);
				printad(players[i], hidetime);
				render(players[i])
				if(sound[i])
					client_cmd(players[i], "mp3 play media/%s", hidesongs[a]);
			}
			
			remove_task(412564);
			set_task(hidetime, "round_timer", 412564);
			
			remove_task(412565);
			set_task(hidetime - 3.0, "soon_timer", 412565);
			
			remove_task(412566);
			counter = floatround(hidetime);
			set_task(1.0, "countdown", 412566, "", 0, "b");
			
			//set_task(240.0,"kill", 0 );
			
			new decompte = get_cvar_num("amx_cc_decompte");
			if(decompte > 0) 
			{
				new Float:tasktime = get_cvar_float("mp_roundtime")*60.0 - float(decompte);
				
				if(tasktime > 4.0) 
					set_task(tasktime-3.0, "lancerDecompte", 789456+decompte);
			}
		}
	}
}
public kill()
{

   
        new iPlayers[32], iNum
        get_players(iPlayers, iNum, "ah")

        for(new i; i<iNum ; i++)
        {
            user_kill(iPlayers[i], 1)
        }

}  

public lancerDecompte(id) 
{
	g_decompte = id - 789456;
	set_task(1.0, "afficherDecompte", 147258, "", 0, "b");
}

public afficherDecompte() 
{
	set_hudmessage(255, 255, 255, 0.05, 0.45, 0, 1.0, 1.0, 0.2, 0.2, 8);
	
	g_decompte--;
	if(g_decompte == 0) 
	{
		new players[32], inum, id;
		get_players(players, inum, "ae", "TERRORIST");
		for(new i = 0; i < inum; i++) 
		{
			id = players[i];
			set_pdata_int(id, 444, get_user_deaths(id) - 1);
			user_kill(id, 1);
		}
		remove_task(147258);
		return
	}
	show_hudmessage(0, "%d przed koncem!", g_decompte);
}

public countdown()
{
	set_hudmessage(255, 20, 0, 0.10, 0.50, 0, 1.0, 1.0, 0.2, 0.2, 9);
	counter--;
	show_hudmessage(0, "%d", counter);
}

public round_timer()
{
	new players[32];
	new pnum;
	
	if (active == 3)
	{
		remove_task(412566);
		client_print(0, print_chat, "[SiZ] CT, znajdzcie Terrorystow i zabijcie ich!");
		client_print(0, print_chat, "[SiZ] T, mozecie przejsc do trybu freelook, Wpisz /freelook, aby wrocic /firstperson !");
		client_cmd(0, "spk radio/com_go");
		phase = 2;
		
		if(get_pcvar_num(amx_hs_light)) {
			fm_set_lights("a"); 
		
		}
		get_players(players, pnum, "ae", "CT");
		new a = random_num(0, sizeof(seekerssongs) - 1);
		
		for (pnum--; pnum>=0; pnum--)
		{
			f2b(players[pnum], 0);
			if(sound[players[pnum] ])
				client_cmd(players[pnum], "mp3 play media/%s",seekerssongs[a]);
			fm_give_item(players[pnum], "weapon_knife");
			fm_give_item(players[pnum], "weapon_deagle");
			fm_give_item(players[pnum], "ammo_50ae");
			fm_give_item(players[pnum], "ammo_50ae");
			fm_give_item(players[pnum], "ammo_50ae");
			fm_give_item(players[pnum], "ammo_50ae");
			fm_give_item(players[pnum], "ammo_50ae");
			fm_give_item(players[pnum], "ammo_50ae");
			fm_give_item(players[pnum], "weapon_m4a1");
			fm_give_item(players[pnum], "ammo_556nato");
			fm_give_item(players[pnum], "ammo_556nato");
			fm_give_item(players[pnum], "ammo_556nato");
			fm_give_item(players[pnum], "ammo_556nato");
			fm_give_item(players[pnum], "ammo_556nato");
			fm_give_item(players[pnum], "ammo_556nato");
			new flashs = get_pcvar_num(amx_hs_flash);
			
			if(flashs ==1)
				fm_give_item(players[pnum], "weapon_flashbang");
			else if(flashs ==2) 
			{
				fm_give_item(players[pnum], "weapon_flashbang");
				fm_give_item(players[pnum], "weapon_flashbang");
			}
		}
		
		a = random_num(0, sizeof(seekedsongs) - 1);
		get_players(players, pnum, "ae", "TERRORIST");
		for (pnum--; pnum>=0; pnum--)
		{
			fm_set_user_godmode(players[pnum], 0);
			if(sound[players[pnum] ])
				client_cmd(players[pnum], "mp3 play media/%s",seekedsongs[a]);

			fm_set_user_maxspeed(players[pnum], 400.0)
		}
	}
}

public soon_timer()
{
	if (active == 3)
	{
		client_print(0, print_chat,"[SiZ] Terrorysci zostaniecie przytwierdzeni do ziemi!");
		client_cmd(0, "spk radio/position");
	}
}

public jointeam(id) 
{
	if (active == 0)
	{
		return PLUGIN_CONTINUE;
	}
	
	if (transferring[id] == 1)
	{
		transferring[id] = 0;
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;
}

public chooseteam(id)
{
	if (active == 0)
	{
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;
}

public switchweapon(id)
{
	if(!active)
		return;
	
	if( active > 0 && active < 3 ) 
	{
		fm_set_user_maxspeed(id, 400.0);
		return;
	}
	new team = get_user_team(id);
	
	switch( phase )
	{
		case 1:
		{
			switch( team ) {
				case 2:
				{
					fm_set_user_maxspeed(id, 0.1);
				}
				case 1:
				{
					fm_set_user_maxspeed(id, 400.0);
				}
			}
		}
		case 2:
		{
			switch( team ) {
				case 1:
				{
					fm_set_user_maxspeed(id, 0.1);
				}
				case 2:
				{
					fm_set_user_maxspeed(id, 400.0);
				}
			}
		}
	}
}

public buy(id)
{
	if (active == 3)
	{
		new team[32];
		get_user_team(id, team, 31);
		
		if (equali(team, "TERRORIST"))
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public deathmsg()
{
	new i;
	new team[32];
	new victim = read_data(2);

	flashlight[victim] = 0;

	if (active == 3)
	{
		printad(victim, 1000.0);
		get_user_team(victim, team, 31);
		
		if (equali(team, "TERRORIST"))
		{
			client_cmd(0, "spk radio/enemydown");
			for (i=0; i<32 && killed[i]!=0; i++)
			{
			}
		
			if (i == 32)
			{
				for (i=1; i<32; i++)
					killed[i-1] = killed[i];
			}
			killed[i] = victim;
		}
	}

}

public gamestart() 
{
	remove_task(147258);
}

public endround()
{
	//inround = 0;
	if (active)
	{
		set_task(2.5,"delayed_endround");
		
		if(get_pcvar_num(amx_hs_light)) {
			fm_set_lights("d"); 
		}
	}
}

public delayed_endround()
{
	remove_task(147258);
	new newcats = 0;
	new players[32];
	new cts[32];
	new ctnum;
	new pnum;
	new i;
	
	if (active != 3)
	{
		return PLUGIN_CONTINUE;
	}
	remove_task(412564);
	remove_task(412565);
	remove_task(412566);
	
	get_players(cts, ctnum, "e", "CT");
	get_players(players, pnum, "e", "TERRORIST");
	
	if (ctnum<mincats || pnum<mice)
	{
		client_print(0, print_chat,"[SiZ] Gracz wyszedl z serwera! Nastepuje wymieszanie skladow...");
		return PLUGIN_CONTINUE;
	}
	
	new maxcats = get_maxcats();
	get_players(players,pnum,"ae","TERRORIST");
	for (i=0; i<pnum && newcats<maxcats; i++)
	{
		if (hasdbg) 
			client_print(0,print_chat,"* SiZ[endround]: Terrorysta ktory nie zostal znaleziony bedzie szukal w nastepnej rundzie")
		
		fm_set_user_team(players[i], FM_TEAM_CT);
		newcats++;
	}
	
	if (newcats < maxcats)
	{
		for (i=31; i>=0 && killed[i]==0; i--)
		{
			
		}
		for (; i>=0 && newcats<maxcats; i--)
		{
			if (hasdbg) 
				client_print(0,print_chat,"* SiZ[endround]: Zostal zabity, przenosze do CT");
			
			fm_set_user_team(killed[i], FM_TEAM_CT);
			newcats++;
		}
	}
	
	for(i=0; i < ctnum; i++)
	{
		if (hasdbg) 
			client_print(0,print_chat,"* SiZ: CT przenosze do druzyny Terrorystow");
	
		fm_set_user_team(cts[i], FM_TEAM_T);
	}
	return PLUGIN_CONTINUE;
}

public printad(id, Float:duration)
{
	set_hudmessage(255, 127, 0, -1.0, 0.1, 2, 1.0, duration, 0.0, 1.0, 8);
	show_hudmessage(id, "www.CS-Wysypisko.pl");
}

stock f2b(id, type)
{
	message_begin(MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id);
	write_short(5000);
	write_short(5000);
	write_short(type==1?5:0);
	write_byte(0);
	write_byte(20);
	write_byte(40);
	write_byte(255);
	message_end();
}

public emitsound(entity, const sample[])
{
	if(!get_pcvar_num(amx_hs_flash))
		return PLUGIN_CONTINUE;
	
	if(!equali(sample,"weapons/flashbang-1.wav") && !equali(sample,"weapons/flashbang-2.wav"))
		return PLUGIN_CONTINUE;
	
	flashbang_explode(entity);
	return PLUGIN_CONTINUE;
}

public flashbang_explode(greindex)
{
	if(!fm_is_valid_ent(greindex)) 
		return;
	
	new Float:origin[3];
	//entity_get_vector(greindex,EV_VEC_origin,origin);
	pev(greindex,pev_origin,origin);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(27);
	write_coord(floatround(origin[0])); 
	write_coord(floatround(origin[1]));
	write_coord(floatround(origin[2])); 
	write_byte(get_pcvar_num(radius_cvar)); 
	write_byte(205);	
	write_byte(255); 
	write_byte(205); 
	write_byte(150); 
	write_byte(200); 
	message_end();
}

public FlashedEvent(id)
{
	if(get_pcvar_num(amx_hs_flash))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public event_flashlight(id) 
{
	if(!get_pcvar_num(flashlight_custom)) 
		return;
	
	//new CsTeams:team = cs_get_user_team(id)
	
	new team = get_user_team(id)
	
	if(team != 2 && get_pcvar_num(flashlight_only_ct))
	{
		flashlight[id] = 0;
	}
	else
	{
		if(flashlight[id]) 
		{
			flashlight[id] = 0;
			color[id] = random_num(0, sizeof( g_color ) - 1);
		}
		else 
		{
			flashlight[id] = 1;
		}
	}
	
	message_begin(MSG_ONE,gmsgFlashlight,_,id);
	write_byte(flashlight[id]);
	write_byte(100);
	message_end();
	//entity_set_int(id,EV_INT_effects,entity_get_int(id,EV_INT_effects) & ~EF_DIMLIGHT);
	set_pev(id,pev_effects,pev(id,pev_effects) & ~EF_DIMLIGHT);
}

public fwdPlayerPreThink(id) 
{
	if(get_pcvar_num(flashlight_custom)) {
		
	
		new a = color[id];
		if(flashlight[id]) 
		{
			new origin[3];
			get_user_origin(id,origin,3);
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
			write_byte(TE_DLIGHT);
			write_coord(origin[0]); 
			write_coord(origin[1]); 
			write_coord(origin[2]); 
			write_byte(get_pcvar_num(flashlight_radius)); 
			write_byte(g_color[a][0]); 
			write_byte(g_color[a][1]); 
			write_byte(g_color[a][2]); 
			write_byte(1);
			write_byte(60); 
			message_end();
		}
	}

	new weapon = get_user_weapon(id);
   	new team = get_user_team(id);
   	if(team == 2) {	

   		if( pev(id, pev_takedamage) )
   		{
			set_pev(id, pev_takedamage, 0.0);
		
   		}
   	} else if( !(pev(id, pev_takedamage)) ){
		set_pev(id, pev_takedamage, 1.0);
   	}

	if(team == 1) {

			if( weapon != CSW_KNIFE )
			{
					client_cmd(id, "drop");
					engclient_cmd(id, "weapon_knife");
			}
 	}
	return FMRES_IGNORED;

}

public fwd_KeyValue(entId, kvd_id)
{
    if(!pev_valid(entId))
        return FMRES_IGNORED;
    
    static className[64];
    get_kvd(kvd_id, KV_ClassName, className, 63);
    
    if(containi(className, "func_bomb_target") != -1
    || containi(className, "info_bomb_target") != -1
    || containi(className, "hostage_entity") != -1
    || containi(className, "monster_scientist") != -1
    || containi(className, "func_hostage_rescue") != -1
    || containi(className, "info_hostage_rescue") != -1
    || containi(className, "info_vip_start") != -1
    || containi(className, "func_vip_safetyzone") != -1
    || containi(className, "func_escapezone") != -1)
        engfunc(EngFunc_RemoveEntity, entId);
    
    if(!hostageMade)
    {
        hostageMade = true;
        new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
        engfunc(EngFunc_SetOrigin, ent, Float:{0.0,0.0,-55000.0});
        engfunc(EngFunc_SetSize, ent, Float:{-1.0,-1.0,-1.0}, Float:{1.0,1.0,1.0});
        dllfunc(DLLFunc_Spawn, ent);
    }
    
    return FMRES_HANDLED;
}  

// Stocks
stock fm_give_item(index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock fm_set_user_gravity(index, Float:gravity = 1.0) {
	set_pev(index, pev_gravity, gravity);

	return 1;
}

stock fm_set_user_godmode(index, godmode = 0) {
	set_pev(index, pev_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM);

	return 1;
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0) {
	engfunc(EngFunc_SetClientMaxspeed, index, speed);
	set_pev(index, pev_maxspeed, speed);

	return 1;
}

stock fm_set_user_nvg(index, nvgoggles = 1)
{
    new current = get_pdata_int(index, OFFSET_NVGOGGLES);
    
    if( !(current & HAS_NVGOGGLES) && nvgoggles )
    {
        current |= HAS_NVGOGGLES;
    }
    else if( (current & HAS_NVGOGGLES) && !nvgoggles )
    {
        current &= ~HAS_NVGOGGLES;
    }
    else
    {
        return 0;
    }
    
    set_pdata_int(index, OFFSET_NVGOGGLES, current);
    
    return 1;
}

fm_set_lights(const lights[])
    engfunc(EngFunc_LightStyle, 0, lights);

stock fm_set_kvd(entity, const key[], const value[], const classname[] = "") {
	if (classname[0])
		set_kvd(0, KV_ClassName, classname);
	else {
		new class[32];
		pev(entity, pev_classname, class, sizeof class - 1);
		set_kvd(0, KV_ClassName, class);
	}

	set_kvd(0, KV_KeyName, key);
	set_kvd(0, KV_Value, value);
	set_kvd(0, KV_fHandled, 0);

	return dllfunc(DLLFunc_KeyValue, entity, 0);
}

stock fm_set_user_team(client, team) {
	set_pdata_int(client, OFFSET_TEAM, team);

	static const TeamInfo[FM_TEAM_MAX][] =
	{
		"UNASSIGNED",
		"TERRORIST",
		"CT",
		"SPECTATOR"
	};

	message_begin(MSG_ALL, gmsgTeamInfo);
	write_byte(client);
	write_string(TeamInfo[team]);
	message_end();
}
