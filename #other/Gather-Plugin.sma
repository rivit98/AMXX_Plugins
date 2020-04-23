#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <ColorChat>

#define PLUGIN	"Gather Plugin"
#define VERSION	"1.3b"
#define AUTHOR	"R3X"

#define CHANGE		0	// if 1 -> change nicks when tags not defined by .tag
#define FIRSTTEAM	"|#1|"	// Tag #1 If .tag not set
#define SECONDTEAM	"|#2|"	// Tag #2 If .tag not set

new g_pauser=0;
new bool:g_paused=false;
new bool:g_started;
new bool:g_exec;
new g_score_ct[2];
new g_score_t[2];
new g_half;
new cvar_pause, cvar_unpause;

new bool:g_changetags[2]= {
	true,
	true
};

new g_tags[2][65]= {
	"",
	""
};

new const g_cmds[][]= {
	"kick",
	"ban",
	"banip",
	"ff",
	"demo",
	"start",
	"restart",
	"stop",
	"map",
	"tag",
	"cancel",
	"warmup",
	"pause",
	"unpause"
};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	/*
	gp_pause_access 0
		all users
	gp_pause_access 1
		admins
	gp_unpause_access 0
		admins
	gp_unpause_access 1
		admins and player who paused
	*/
	cvar_pause=register_cvar("gp_pause_access","1");
	cvar_unpause=register_cvar("gp_unpause_access","1");
	register_concmd("amx_tagt",	"tagChange", ADMIN_BAN, "<T tagname>");
	register_concmd("amx_tagct",	"tagChange", ADMIN_BAN, "<CT tagname>");
	register_clcmd("chooseteam","changeTeam");
	register_clcmd("say", "chatFilter", ADMIN_BAN);
	register_clcmd("say .score","showScore");
	register_event("TeamScore", "teamScore", "a");
	register_logevent("PoczatekRundy", 2, "1=Round_Start"); 
	server_cmd("pausable 0");
}

public PoczatekRundy(){
	if(g_half != 0){
		set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 6.0);
		show_hudmessage(0, "[%s] %d:%d [%s]",g_tags[0],g_score_ct[0]+g_score_ct[1], g_score_t[0]+g_score_t[1],g_tags[1]);
	}
}
public changeTeam(id)
{
	if(g_started)
	{
		ColorChat(0, GREEN,"[MIX-LIVE]^x01 Za pozno na zmiane teamu, poczekaj do konca polowy!");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public chatFilter(id) {
	new message[128];
	read_argv(1, message, 127);
	for(new i=0;i<sizeof(g_cmds);i++) {
		new cmd[33];
		formatex(cmd,32,".%s",g_cmds[i]);
		if(containi(message,cmd) == 0) {
				//admin level required
				switch(i) {
				case 0,1,2,3,4,5,6,7,8,9,10,11:	{
					if(!(get_user_flags(id) & ADMIN_BAN))
						return PLUGIN_CONTINUE;
					}
				}
				callBack(id,i);
				return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public showMatchEnd() {
	switch( g_half ) {
		case 1: {
			ColorChat(0, GREEN,"[MIX]^x01 Pierwsza polowa zakonczona!");
			ColorChat(0, GREEN,"[MIX]^x01 Zmiana druzyn!");
			showScore2(1);
		}
		case 2: {
			ColorChat(0, GREEN,"[MIX]^x01 Mecz skonczony.");
			ColorChat(0, GREEN,"[MIX]^x01 Dziekujemy za gre!");
			showScore2(2);
			prepareMatch();
		}
	}
	g_exec=false;
}

prepareMatch() {
	//game not started
	g_started = false;
	g_half	= 0;
	
	//reset score
	g_score_ct[0]	= 0;
	g_score_ct[1]	= 0;
	g_score_t[0]	= 0;
	g_score_t[1]	= 0;
	
	//clear tags
	g_changetags[0]	= true;
	g_changetags[1]	= true;
	g_tags[0]	= "";
	g_tags[1]	= "";
}

public restartRound(arg[]) {
	new id = arg[0];
	new args[1];
	args[0]	= id+1;
	g_exec	= true;
	switch( id ) {
		case 0: {
			ColorChat(0, GREEN,"[MIX-LIVE]^x01 Gra rozpocznie sie za:");
			ColorChat(0, GREEN,"[MIX-LIVE]^x01 5");
		}
		case 1,2: {
			ColorChat(0, GREEN,"[MIX-LIVE]^x01 %d",5-id);
			server_cmd("sv_restartround 1");
		}
		case 3: {
			ColorChat(0, GREEN,"[MIX-LIVE]^x01 2");
		}
		case 4: {
			ColorChat(0, GREEN,"[MIX-LIVE]^x01 1");
			server_cmd("sv_restartround 1");
			set_task(2.0, "restartRound", 0, args,1);
		}
		case 5: {
			ColorChat(0, GREEN,"[MIX-LIVE]^x01 Zaczynamy !");
			ColorChat(0, GREEN,"[MIX-LIVE]^x01 GL&HF!");
			set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 6.0, 3.0);
			show_hudmessage(0, "Jest LIVE^n^nZaczynamy polowe: %d",g_half); 
			g_exec=false;
		}
}
	if(id < 4)
		set_task(1.0, "restartRound", 0, args,1);
}

public callBack(id, cID) {
	new message[128], cmd[33], arg[65], arg2[65];
	read_argv (1, message, 128);
	parse(message,cmd,32,arg,64,arg2,64);
	replace(cmd,32,".","");
	
	switch(cID) {
		case 0: { // Kick Player
			console_cmd(id,"amx_kick %s", arg);
		}
		case 1: { // Ban Player
			new bantime=str_to_num(arg2);
			if(bantime==0)
				bantime=1;
			console_cmd(id,"amx_ban %s %d", arg, bantime);
		}
		case 2: { // BanIP Player
			new bantime=str_to_num(arg2);
			if(bantime==0)
				bantime=1;
			console_cmd(id,"amx_banip %s %d", arg, bantime);
		}
		case 3: { // Set FriendlyFire
			if(equali(arg,"on")) {
				console_cmd(id,"amx_cvar mp_friendlyfire 1");
			}
			else if(equali(arg,"off")) {
				console_cmd(id,"amx_cvar mp_friendlyfire 0");
			}
		}
		case 4: { // Record Demo
			new demoname[71];
			new datetime[31],mapname[21];
			get_time("%d-%m-%Y-%H-%M-%S", datetime, 30);
			get_mapname(mapname,20);
			formatex(demoname,70,"demo-%s-%s.dem",mapname,datetime);
			new player = cmd_target(id, arg, 0);
			if(player==0)
				ColorChat(0, GREEN,"[Nagrywanie Demo]^x01 ^x03%s^x01 Nie znaleziono gracza!",arg);
			else {
				console_cmd(player,"record %s",demoname);
				new name[36];
				get_user_name(player,name,35);
				ColorChat(0, GREEN,"[Nagrywanie Demo]^x01 Gracz: ^x03%s^x01 znaleziony.",name);
			}
		}
		case 5: { // Start Match
			if(g_half==2 && !g_started) {
				ColorChat(0, GREEN,"[MIX]^x01 Poczekaj na koniec resetu.");
				return PLUGIN_HANDLED;
			}
			if(g_exec) {
				ColorChat(0, GREEN,"[MIX]^x01 Wykonuje...");
				return PLUGIN_HANDLED;
			}
			if(g_started) {
				ColorChat(0, GREEN,"[MIX-LIVE]^x01 Trwa gra -- wpisz najpierw ^x04.stop^x01.");
				return PLUGIN_HANDLED;
			}
			if(equal(g_tags[0],"") && g_changetags[0]) {
				copy(g_tags[0], 20 ,FIRSTTEAM);
				g_changetags[0]=false;
			}
			if(equal(g_tags[1],"")&& g_changetags[1]) {
				copy(g_tags[1], 20 ,SECONDTEAM);
				g_changetags[1]=false;
			}
			
			// Exec configs & set bools.
			server_cmd("exec 2.cfg");
			checkAll();
			new args[1];
			args[0]=0;
			restartRound(args);
			if(g_half==0)
				g_half=1;
			else if(g_half==1)
				g_half=2;
			
			g_started=true;
		}
		case 6: { // Restart
			if(g_exec) {
				ColorChat(0, GREEN,"[MIX]^x01 Wykonuje...");
				return PLUGIN_HANDLED;
			}
			if(!g_started) {
				ColorChat(0, GREEN,"[MIX-NOT]^x01 Nie gramy jeszcze -- wpisz pierw ^x04.start^x01.");
				return PLUGIN_HANDLED;
			}
			
			new args[1];
			args[0] = 0;
			restartRound(args);
			g_score_ct[g_half-1]	= 0;
			g_score_t[g_half-1]	= 0;
			g_started		= true;
		}	
		case 7: { // Stop match.
			if(g_exec)
			{
				ColorChat(0, GREEN,"[MIX]^x01 Wykonuje...");
				return PLUGIN_HANDLED;
			}
			if(!g_started)
			{
				ColorChat(0, GREEN,"[MIX-NOT]^x01 Nie gramy jeszcze -- wpisz pierw ^x04.start^x01.");
				return PLUGIN_HANDLED;
			}
			
			g_exec = true;
			server_cmd("exec warmup.cfg");
			set_task(2.0,"showMatchEnd");
			g_started = false;
		}
		case 8: { // Changelevel
			console_cmd(id,"amx_map %s", arg);
		}
		case 9: { // Tag System
			if(!(g_half==0 || (g_half==2 && !g_started))) {
				ColorChat(0, GREEN,"[TAG]^x01 Mozesz zrobic to tylko, kiedy nie trwa mix.");
				return PLUGIN_HANDLED;
			}
			
			if(equali(arg, "OFF")) {
				new ct[21],t[21];
				if(g_half == 0 || g_half == 1) {
					copy(ct ,20, g_tags[0]);
					copy(t ,20, g_tags[1]);
				}
				else if(g_half == 2) {
					copy(ct ,20, g_tags[1]);
					copy(t ,20, g_tags[0]);
				}
				untagThem(CS_TEAM_CT, ct);
				untagThem(CS_TEAM_T, t);
				g_tags[0]="";
				g_tags[1]="";
			}
			else if(equal(arg,"") || equal(arg2,"")) {
				ColorChat(0, GREEN,"[TAG]^x01 Obecne tagi:");
				ColorChat(0, GREEN,"[TAG]^x01^t#1: ^x04%s",g_tags[0]);
				ColorChat(0, GREEN,"[TAG]^x01^t#2 : ^x04%s",g_tags[1]);
				ColorChat(0, GREEN,"[TAG]^x01 Uzyj: ^x04.tag^x03 #1|#2 ^x04<nazwa teamu> ^x01lub ^x04.tag ^x03OFF^x01, w celu nie ustawiania tagu.");
			}
			else if(equali(arg,"#1")) {
				client_cmd(id,"amx_tagct %s", arg2);
			}
			else if(equali(arg,"#2")) {
				client_cmd(id,"amx_tagt %s", arg2);
			}
			else if(equali(arg,"sCT")) {
				new a;
				if(g_half == 0 || g_half == 1) {
					a=0;
				}
				else if(g_half == 2) {
					a=1;
				}
				g_tags[a]=arg2;
				g_changetags[a]=false;
				
				client_cmd(id,"say .tag");
			}
			else if(equali(arg,"sT")) {
				new a;
				if(g_half == 0 || g_half == 1) {
					a=1;
				}
				else if(g_half == 2) {
					a=0;
				}
				g_tags[a]=arg2;
				g_changetags[a]=false;
				g_changetags[0]=true;
				client_cmd(id,"say .tag");
			}
			else {
				ColorChat(0, GREEN,"[TAG]^x01 Uzyj: ^x04.tag^x03 #1|#2 ^x04<nazwa teamu> ^x01lub ^x04.tag ^x03OFF^x01, w celu nie ustawiania tagu.");
			}
			
		}
		case 10: { // Cancel Game.
			if(g_half == 0) {
				ColorChat(0, GREEN,"[MIX-NOT]^x01 Nie gramy jeszcze.");
				return PLUGIN_HANDLED;
			}
			
			prepareMatch();
			server_cmd("sv_restartround 3");
			ColorChat(0, GREEN,"[MIX-NOT]^x01 !! Mix Anulowany !!");
			ColorChat(0, GREEN,"[MIX-NOT]^x01 !! Koniec Gry !!");
		}
		case 11: {//Warmup
			server_cmd("exec warmup.cfg");
			ColorChat(0, GREEN,"[MIX-NOT]^x01 !! Warmup !!");	
		}
		case 12: {//pause
			if(g_paused)
			{
				ColorChat(0, GREEN,"[Pauza]^x01 Aktualnie trwa pauza.");
			}
			else
				pause_server(id);
		}
		case 13: {//unpause
			if(!g_paused)
			{
				ColorChat(0, GREEN,"[Pauza]^x01 Kontynuujemy mix'a.");
			}
			else
				pause_server(id);
		}
	}
	return PLUGIN_HANDLED;
}
public showScore(id) {
	if(g_half == 0)
		ColorChat(0, GREEN,"[MIX-NOT]^x01 Zaczekaj na start mix'a.");
	else
		show_hudmessage(0, "[%s] %d:%d [%s]",g_tags[0],g_score_ct[0]+g_score_ct[1], g_score_t[0]+g_score_t[1],g_tags[1]);
	
	return PLUGIN_HANDLED;
}
public showScore2(type) {
	if(g_half == 0)
		ColorChat(0, GREEN,"[MIX-NOT]^x01 Zaczekaj na start mix'a.");
	else{
		new comment[50]="";
		if(type==1)
			copy(comment,49,"Wynik Pierwszej Polowy^n");
		else if(type==2)
			copy(comment,49,"Koncowy wynik^n");
		set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 6.0);
		show_hudmessage(0, "%s [%s] %d:%d [%s]",comment,g_tags[0],g_score_ct[0]+g_score_ct[1], g_score_t[0]+g_score_t[1],g_tags[1]);
	}
	return PLUGIN_HANDLED;
}

public teamScore() {
	if(!g_started)
		return PLUGIN_CONTINUE;
	new team[32];
	read_data(1, team, 31);
	if (g_half == 1) { // first half
		if (team[0] == 'C')
			g_score_ct[0] = read_data(2);
		else if (team[0] == 'T')
			g_score_t[0] = read_data(2);	
	}
	else if (g_half == 2) { // second half
		if (team[0] == 'C')
			g_score_t[1] = read_data(2);
		else if (team[0] == 'T')
			g_score_ct[1] = read_data(2);
	}
	return PLUGIN_CONTINUE;
}

public tagChange(id,level,cid) {
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
	
	new cmd[11], tag[21];
	read_argv (0, cmd, 10);
	read_argv (1, tag, 20);
	if(equali("amx_tagt",cmd)) {
		setGTags(1,tag);
		tagThem(CS_TEAM_T);
	}
	else if(equali("amx_tagct",cmd)) {
		setGTags(2, tag);
		tagThem(CS_TEAM_CT);
	}
	return PLUGIN_HANDLED;
}

public tagPlayer(id) {
	new CsTeams:p_team=cs_get_user_team(id);
	new name[36];
	get_user_name(id,name,35);
	new tag[21];
	new a = 0;
	if(g_half==0 || (g_half==1 && g_started)) {
		if(p_team==CS_TEAM_CT)
			a=0;
		else if(p_team==CS_TEAM_T)
			a=1;
	}
	else if(g_half==2 || (g_half==1 && !g_started)) {
		if(p_team==CS_TEAM_CT)
			a=1;
		else if(p_team==CS_TEAM_T)
			a=0;
	}
	if(!g_changetags[a] && CHANGE==0)
		return;
	copy(tag ,20, g_tags[a]);
	if(contain(name,tag)!=0)
		client_cmd(id, "name ^"%s%s^"",tag,name);
}

tagThem(CsTeams:team) {
	new Players[32], playerCount, player;
	get_players(Players, playerCount);
	for (new i=0; i<playerCount; i++) {
		player = Players[i]; 
		new CsTeams:p_team=cs_get_user_team(player);
		if(p_team == team) {
			tagPlayer(player);
		}
	}
}

untagThem(CsTeams:team, tag[21]) {
	new Players[32], playerCount, i, player;
	get_players(Players, playerCount);
	for (i=0; i<playerCount; i++) {
		player = Players[i]; 
		new CsTeams:p_team=cs_get_user_team(player);
		new name[36];
		get_user_name(player,name,35);
		if(p_team == team) {
			if(contain(name,tag)==0) {
				replace(name, 35, tag,"");
				client_cmd(player,"name ^"%s^"",name);
			}
		}
	}
	new type=0;
	if(team==CS_TEAM_T)
		type=1;
	else if(team==CS_TEAM_CT)
		type=2;
	setGTags(type, "");
}

setGTags(type, tag[21]) {
	if(g_half==0 || g_half==1) {
		switch( type ) {
			case 1: copy(g_tags[1],64,tag);
			case 2: copy(g_tags[0],64,tag);
		}
	}
	if(g_half==2) {
		switch( type ) {
			case 1: copy(g_tags[0],64,tag);
			case 2: copy(g_tags[1],64,tag);
		}
	}
}

public client_infochanged(id) {
	if(equal(g_tags[0],"") || equal(g_tags[1],""))
		return;

	set_task(1.0, "tagPlayer",id);
}

public pause_server(id) {
	new p_acess=get_pcvar_num(cvar_pause);
	new up_acess=get_pcvar_num(cvar_unpause);
	if(g_paused)
	{
		if
		((up_acess==0 && access(id,ADMIN_BAN))
		|| (up_acess==1 && (access(id,ADMIN_BAN) || id==g_pauser)))
		{
			g_pauser=0;
			ColorChat(0, GREEN,"[Pauza]^x01 Kontynuujemy mix'a.");
		}
		else
		{
			ColorChat(0, GREEN,"[Pauza]^x01 Nie mozesz teraz tego zrobic.");
			return;
		}
	}
	else
	{
		if
		((p_acess==0) || (p_acess==1 && access(id,ADMIN_BAN)))
		{
			g_pauser=id;
			ColorChat(0, GREEN,"[Pauza]^x01 Pauzujemy.");
		}
		else
		{
			ColorChat(0, GREEN,"[Pauza]^x01 Nie mozesz teraz tego zrobic.");
			return;
		}
	}
	new name[36];
	get_user_name(id,name,35);
	ColorChat(0, GREEN,"[Pauza]^x01 say ^x04%s^x01 zatrzymal/wznowil gre.",name);
	server_cmd("amx_pause");
	g_paused=!g_paused;
}

public checkAll() {
	tagThem(CS_TEAM_CT);
	tagThem(CS_TEAM_T);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
