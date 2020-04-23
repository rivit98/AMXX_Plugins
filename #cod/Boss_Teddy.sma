#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <cod>
#include <colorchat>
#include <fun>

#define PLUGIN "CSO Boss Teddy Bear Final"
#define VERSION "4.0"
#define AUTHOR "Itachi Uchiha- Mods Scripter"

//Configs Boss
#define CLASS_NAME_BOSS "Boss_Teddy_CSO"
#define HEALTH_BOSS 100000.0
#define SPEED_TEDDY 150.0

//Damage Attack
#define DAMAGE_ATTACK 50.0
#define DAMAGE_TENTACLE 50.0
#define DAMAGE_TENTACLE_TOUCH 20.0
#define DAMAGE_HOLE1 50.0
#define DAMAGE_HALLOWEEN 20.0
#define DAMAGE_FINAL 50.0

//Remove Task Anti Bug
#define HP_SPRITE 1
#define ATTACK_TASK 2
#define CORRER_TEDDY 3
#define TENTACLE_TEDDY 4
#define HOLE_TEDDY 5
#define HOLE1_TEDDY 6
#define METEOR_TEDDY 7

//Resources..
#define ice_model "models/Teddy/dd_iceblock.mdl"
#define frozer "Teddy/congelacion.wav"//"Teddy/impalehit.wav"

enum
{
	ANIM_DUMMY = 0,
	SCENE_APPEAR,
	ZBS_IDLE1,
	ZBS_WALK,
	ZBS_RUN,
	ZBS_ATTACK1,
	ZBS_ATTACK2,
	ZBS_ATTACK_SLIDING,
	ZBS_ATTACK_CANDY,
	ZBS_ATTACK_HOLE,
	ZBS_ATTACK_HOLE2,
	ZBS_ATTACK_METEOR,
	SCENE_CHANGE,
	TEDDY_DEATH
}
new const news[][] = 
{
	"sprites/Teddy/shockwave.spr"	
}
static g_news[sizeof news]

enum {
	shockwave
}
new const Boss_Model_CSO[] = "models/Teddy/Teddy_CSO.mdl"
new const Boss_Tentacle_CSO[] = "models/Teddy/Dulce.mdl"
new const Boss_Hole_Effect[] = "models/Teddy/ef_hole.mdl"
new const Boss_Halloween[] = "models/Teddy/halloween.mdl"
new const Boss_Halloween2[] = "sprites/Teddy/blue.spr"
new const Hp_Sprite_Boss[] = "sprites/Teddy/hp.spr"

new const Sound_Boss_CSO[20][] = 
{
	"Teddy/zbs_attack2.wav",		
	"Teddy/death.wav",
	"Teddy/footstep1.wav",
	"Teddy/footstep2.wav",
	"Teddy/zbs_fail.wav",
	"Teddy/zbs_clear.wav",
	"Teddy/candy_attack.wav",
	"Teddy/scene_appear1.wav",
	"Teddy/zbs_attack1.wav",
	"Teddy/zbs_attack_sliding.wav",
	"Teddy/zbs_attack_hole.wav",
	"Teddy/zbs_attack_candy.wav",
	"Teddy/scene_change.wav",
	"Teddy/zbs_attack_hole2_1.wav",
	"Teddy/zbs_attack_meteor.wav",
	"Teddy/zbs_attack_meteor_exp.wav",
	"Teddy/zbs_attack_hole2_2.wav",
	"Teddy/footstep3.wav",
	"Teddy/gift_explode.wav",
	"Teddy/footstep4.wav"
}

new Boss_Model_Linux, Damage_Off, Start_Boss_CSO, Damage_Touch, y_hpbar, y_think, y_bleeding[2], bool:g_bCongelado[33],
iceent[33], g_msgScreenFade, g_exploSpr, g_explosfr, frostgib, y_npc_hp

new Float:VAngles[3], Float:Origin[3], Float:Attack_Time;

new g_damagedealt[33];

new g_iEntBarrier;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_think(CLASS_NAME_BOSS, "cso_boss_think")
	register_touch(CLASS_NAME_BOSS, "*", "cso_boss_touch")
	register_forward(FM_PlayerPreThink, "fw_Player_Frozer")
	RegisterHam(Ham_Spawn, "player", "Bug_Frozer", 1)
	register_think("Halloween_Meteos", "fire_helloween_think")
	register_touch("Halloween_Meteos", "*", "npc_ball_touch")
	register_touch("Damage_Tentacle_Teddy", "*", "Tentacle_Touch")
	
	g_msgScreenFade = get_user_msgid("ScreenFade")
	
	//register_clcmd("say /teddy", "npc_position")
	register_clcmd("say /god", "god")
	//register_clcmd("say /teddy2", "create_cso_boss")
	
	g_iEntBarrier = find_ent_by_tname( -1, "barrier" );
	
	register_clcmd("say /teddy", "TeddyMenu");
}
public plugin_cfg()						// Cvar's goes here
{
	server_cmd("mp_freezetime 0.0")
}
public plugin_precache()
{
	Boss_Model_Linux = precache_model(Boss_Model_CSO)
	precache_model(Boss_Tentacle_CSO)
	precache_model(Boss_Hole_Effect)
	precache_sound(frozer)
	precache_model(ice_model)
	precache_model(Hp_Sprite_Boss)
	precache_model(Boss_Halloween)
	precache_model(Boss_Halloween2)
	
	frostgib = precache_model("sprites/Teddy/frostgib.spr")
	g_exploSpr = engfunc(EngFunc_PrecacheModel, "sprites/Teddy/shockwave.spr")
	g_explosfr = precache_model("sprites/Teddy/frost_exp.spr")
	y_npc_hp = precache_model("sprites/Teddy/zerogxplode.spr")
	y_bleeding[0] = precache_model("sprites/Teddy/blood.spr")
	y_bleeding[1] = precache_model("sprites/Teddy/bloodspray.spr")
	
	for(new i = 0; i < sizeof(Sound_Boss_CSO); i++)
		precache_sound(Sound_Boss_CSO[i])
	
	for(new i; i <= charsmax(news); i++)
		g_news[i] = precache_model(news[i])
}
public event_newround()
{	
	if(pev_valid(y_think))
	{		
		remove_task(y_think+HP_SPRITE)
		remove_task(y_think+ATTACK_TASK)
		remove_task(y_think+CORRER_TEDDY)
		remove_task(y_think+TENTACLE_TEDDY)
		remove_task(y_think+HOLE_TEDDY)
		remove_task(y_think+HOLE1_TEDDY)
		remove_task(y_think+METEOR_TEDDY)
		remove_entity_name(CLASS_NAME_BOSS)
		remove_entity_name("teddy_final")
		remove_entity_name("DareDevil")
		remove_entity_name("Halloween_Meteos")
		remove_entity_name("Damage_Tentacle_Teddy")
	}
	if(pev_valid(y_hpbar)) remove_entity(y_hpbar)
}

public npc_position(id)
{
	pev(id, pev_angles, VAngles)
	pev(id, pev_origin, Origin)

	client_print( id, print_center, "POZYCJA POBRANA");
	
	return PLUGIN_HANDLED;
}
public Bug_Frozer(id)
{
	if(is_user_connected(id))
	{
		g_bCongelado[id] = false
	}
}
public create_cso_boss()
{
	event_newround()
	new ent = create_entity("info_target")
	y_think = ent
	
	Damage_Touch = 0
	Start_Boss_CSO = 0
	
	set_pev(ent, pev_origin, Origin)
	//set_pev(ent, pev_angles, VAngles)
	
	set_pev(ent, pev_gamestate, 1)
	set_pev(ent, pev_takedamage, 1.0)
	set_pev(ent, pev_health, HEALTH_BOSS + 1000.0)
	set_pev(ent, pev_classname, CLASS_NAME_BOSS)
	engfunc(EngFunc_SetModel, ent, Boss_Model_CSO)
	
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	anim(ent, SCENE_APPEAR)
	
	new Float:maxs[3] = {35.0, 55.0, 200.0}
	new Float:mins[3] = {-35.0, -55.0, -35.0}
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	set_pev(ent, pev_modelindex, Boss_Model_Linux)
	set_pev(ent, pev_nextthink, get_gametime() + 5.0)
	
	if(!Damage_Off)
	{
		Damage_Off = 1
		RegisterHamFromEntity(Ham_TakeDamage, ent, "cso_boss_take_damage", 1);
	}
	y_hpbar = create_entity("env_sprite")
	set_pev(y_hpbar, pev_scale, 0.4)
	set_pev(y_hpbar, pev_owner, ent)
	engfunc(EngFunc_SetModel, y_hpbar, Hp_Sprite_Boss)	
	set_task(0.1, "cso_boss_ready", ent+HP_SPRITE, _, _, "b");
	
	return PLUGIN_HANDLED;
}
public cso_boss_ready(ent)
{
	ent -= HP_SPRITE
	if(!pev_valid(ent))
	{
		remove_task(ent+HP_SPRITE)
		return
	}
	static Float:Origin[3], Float:cso_boss_health
	pev(ent, pev_origin, Origin)
	Origin[2] += 265.0	
	engfunc(EngFunc_SetOrigin, y_hpbar, Origin)
	pev(ent, pev_health, cso_boss_health)
	if(HEALTH_BOSS < (cso_boss_health - 1000.0))
	{
		set_pev(y_hpbar, pev_frame, 100.0)
	} else {
		set_pev(y_hpbar, pev_frame, 0.0 + ((((cso_boss_health - 1000.0) - 1 ) * 100) / HEALTH_BOSS))
	}
}
//----------------------------Attacks Teddy----------------------------
public Teddy_Attack(ent)
{
	if(!pev_valid(ent) || Start_Boss_CSO)
		return
	Start_Boss_CSO = 1
	anim(ent, ZBS_ATTACK1)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	new randomx = random_num(0,1)
	switch(randomx) {
		case 0: 
		{
			anim(ent, ZBS_ATTACK1)
			emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[8], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_task(0.3, "Damage_Teddy", ent+ATTACK_TASK)
			set_task(1.0, "simple_attack_reload", ent+ATTACK_TASK)
		}
		case 1: 
		{
			anim(ent, ZBS_ATTACK2)
			emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_task(0.7, "Damage_Teddy2", ent+ATTACK_TASK)	
			set_task(1.3, "simple_attack_reload", ent+ATTACK_TASK)
		}
	}
}
public Damage_Teddy(ent)
{
	ent -= ATTACK_TASK
	if(!pev_valid(ent))
		return	
	
	static Float:Orig[3]
	pev(ent, pev_origin, Orig)
	ShockWave(Orig, 5, 70, 500.0, {255, 0, 0})
	ShockWave(Orig, 5, 70, 400.0, {144, 238, 144})
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 250.0 && get_user_team(i) == 2)
		{
			shake_screen(i)
			ScreenFade(i, 2, {79, 79, 79}, 120)
			ExecuteHam(Ham_TakeDamage, i, 0, i, DAMAGE_ATTACK, DMG_SLASH)
		}
	}
}
public Damage_Teddy2(ent)
{
	ent -= ATTACK_TASK
	if(!pev_valid(ent))
		return	
	
	static Float:Orig[3]
	pev(ent, pev_origin, Orig)
	ShockWave(Orig, 5, 70, 500.0, {255, 0, 0})
	ShockWave(Orig, 5, 70, 400.0, {144, 238, 144})
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 250.0 && get_user_team(i) == 2)
		{
			shake_screen(i)
			ScreenFade(i, 2, {79, 79, 79}, 120)
			ExecuteHam(Ham_TakeDamage, i, 0, i, DAMAGE_ATTACK, DMG_SLASH)
			
			static Float:Jugador[3]
			Jugador[2] = 400.0
			Jugador[0] = 400.0
			set_pev(i, pev_velocity, Jugador)
		}
	}
}
public simple_attack_reload(ent)
{
	ent -= ATTACK_TASK
	Start_Boss_CSO = 0
}

//----------------------------Correr Teddy----------------------------
public Correr_Teddy(ent)
{
	if(!pev_valid(ent) || Start_Boss_CSO)
		return
	Start_Boss_CSO = 1
	Damage_Touch = 1
	anim(ent, ZBS_ATTACK_SLIDING)
	
	emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[9], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(0.7, "CorrerTeddy", ent+CORRER_TEDDY)
	set_task(2.5, "Correr_Teddy3", ent+CORRER_TEDDY)
}
public CorrerTeddy(ent)
{
	ent -= CORRER_TEDDY
	set_task(0.2, "Correr_Teddy2", ent+CORRER_TEDDY, _, _, "b")
}
public Correr_Teddy2(ent)
{
	ent -= CORRER_TEDDY
	if(!pev_valid(ent))
		return
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	static Float:Origin[3]
	get_position(ent, 4000.0, 0.0, 0.0, Origin)
	control_ai2(ent, Origin, 1000.0)
}
public Correr_Teddy3(ent)
{
	ent -= CORRER_TEDDY
	if(!pev_valid(ent))
		return
	Damage_Touch = 0
	remove_task(ent+CORRER_TEDDY)
	set_task(2.0, "reload_run", ent+CORRER_TEDDY)
}
public reload_run(ent)
{
	ent -= CORRER_TEDDY
	remove_task(ent+CORRER_TEDDY)
	Start_Boss_CSO = 0
	anim(ent, ZBS_IDLE1)
}

//----------------------------Candy Teddy----------------------------
public Tentacle_Hammer(ent)
{
	if(!pev_valid(ent) || Start_Boss_CSO)
		return	
		
	Start_Boss_CSO = 1
	anim(ent, ZBS_ATTACK_CANDY)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(10.0, "reload_run2", ent+TENTACLE_TEDDY)
	
	set_task(0.9, "Start_Tentacle", ent+TENTACLE_TEDDY)
	set_task(4.7, "Start_Tentacle", ent+TENTACLE_TEDDY)
	set_task(7.5, "Start_Tentacle", ent+TENTACLE_TEDDY)
	
	set_task(0.9, "Damage_Teddy3", ent+TENTACLE_TEDDY)
	set_task(3.0, "Damage_Teddy3", ent+TENTACLE_TEDDY)
	set_task(4.7, "Damage_Teddy3", ent+TENTACLE_TEDDY)
	set_task(6.4, "Damage_Teddy3", ent+TENTACLE_TEDDY)
	set_task(7.5, "Damage_Teddy3", ent+TENTACLE_TEDDY)
	set_task(7.0, "Damage_Teddy3", ent+TENTACLE_TEDDY)
	set_task(8.5, "Sound_Tentacle_Hammer", ent+TENTACLE_TEDDY)
}
public Sound_Tentacle_Hammer(ent)
{
	ent -= TENTACLE_TEDDY
	emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[11], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public Damage_Teddy3(ent)
{
	ent -= TENTACLE_TEDDY
	if(!pev_valid(ent))
		return	
	
	static Float:Orig[3]
	pev(ent, pev_origin, Orig)
	ShockWave(Orig, 5, 70, 550.0, {255, 0, 0})
	ShockWave(Orig, 5, 70, 450.0, {144, 238, 144})
	
	emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[8], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 300.0 && get_user_team(i) == 2)
		{
			shake_screen(i)
			ScreenFade(i, 2, {79, 79, 79}, 120)
			ExecuteHam(Ham_TakeDamage, i, 0, i, DAMAGE_TENTACLE, DMG_SLASH)
		}
	}
}
public reload_run2(ent)
{
	ent -= TENTACLE_TEDDY
	remove_task(ent+CORRER_TEDDY)
	Start_Boss_CSO = 0
	anim(ent, ZBS_IDLE1)
}
public Start_Tentacle(ent)
{
	ent -= TENTACLE_TEDDY
	if(!pev_valid(ent))
		return
	
	static Float:beam_origin[25][3]
	
	get_position(ent, 200.0, 00.0, 50.0, beam_origin[0])
	get_position(ent, 300.0, 00.0, 50.0, beam_origin[1])
	get_position(ent, 400.0, 00.0, 50.0, beam_origin[2])
	get_position(ent, 500.0, 00.0, 50.0, beam_origin[3])
	get_position(ent, 600.0, 00.0, 50.0, beam_origin[4])
	
	get_position(ent, 200.0, 150.0, 50.0, beam_origin[5])
	get_position(ent, 300.0, 150.0, 50.0, beam_origin[6])
	get_position(ent, 400.0, 150.0, 50.0, beam_origin[7])
	get_position(ent, 500.0, 150.0, 50.0, beam_origin[8])
	get_position(ent, 600.0, 150.0, 50.0, beam_origin[9])
	
	get_position(ent, 200.0, 250.0, 50.0, beam_origin[10])
	get_position(ent, 300.0, 250.0, 50.0, beam_origin[11])
	get_position(ent, 400.0, 250.0, 50.0, beam_origin[12])
	get_position(ent, 500.0, 250.0, 50.0, beam_origin[13])
	get_position(ent, 600.0, 250.0, 50.0, beam_origin[14])
	
	get_position(ent, 200.0, -150.0, 50.0, beam_origin[15])
	get_position(ent, 300.0, -150.0, 50.0, beam_origin[16])
	get_position(ent, 400.0, -150.0, 50.0, beam_origin[17])
	get_position(ent, 500.0, -150.0, 50.0, beam_origin[18])
	get_position(ent, 600.0, -150.0, 50.0, beam_origin[19])
	
	get_position(ent, 200.0, -250.0, 50.0, beam_origin[20])
	get_position(ent, 300.0, -250.0, 50.0, beam_origin[21])
	get_position(ent, 400.0, -250.0, 50.0, beam_origin[22])
	get_position(ent, 500.0, -250.0, 50.0, beam_origin[23])
	get_position(ent, 600.0, -250.0, 50.0, beam_origin[24])
	
	
	for(new i = 0; i < 25; i++)
	Create_Tentacle1(beam_origin[i])
}

public Create_Tentacle1(Float:StartOrigin[3])
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	
	set_pev(Ent, pev_classname, "Damage_Tentacle_Teddy")
	engfunc(EngFunc_SetModel, Ent, Boss_Tentacle_CSO)
	set_pev(Ent, pev_origin, StartOrigin)
	
	anim(Ent, 0)
	
	new Float:maxs[3] = {5.0, 5.0, 30.0}
	new Float:mins[3] = {-5.0, -5.0, -30.0}
	entity_set_size(Ent, mins, maxs)
	
	set_task(1.0, "Remover_Tentacle", Ent+TENTACLE_TEDDY)
}
public Remover_Tentacle(Ent)
{
	Ent -= TENTACLE_TEDDY
	if(!pev_valid(Ent)) return
	engfunc(EngFunc_RemoveEntity, Ent)
}
public Tentacle_Touch(Ent, id)
{
	if(!pev_valid(Ent))
		return
		
	new Classname[32]
	if(pev_valid(id)) pev(id, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "Damage_Tentacle_Teddy"))
		return
		
	if(is_user_alive(id))
	{
		ScreenFade(id, 2, {79, 79, 79}, 120)
		ExecuteHam(Ham_TakeDamage, id, 0, id, DAMAGE_TENTACLE_TOUCH, DMG_SLASH)
	}
}

//----------------------------Hole1 Teddy----------------------------
public Teddy_Hole1(ent)
{
	if(!pev_valid(ent) || Start_Boss_CSO)
		return	
		
	Start_Boss_CSO = 1
	anim(ent, ZBS_ATTACK_HOLE)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[10], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(8.0, "reload_run3", ent+HOLE_TEDDY)
	set_task(5.0, "Damage_Teddy4", ent+HOLE_TEDDY)
	set_task(0.2, "attack_hole", ent+HOLE_TEDDY)
}
public Damage_Teddy4(ent)
{
	ent -= HOLE_TEDDY
	if(!pev_valid(ent))
		return	
	
	static Float:Orig[3]
	pev(ent, pev_origin, Orig)
	ShockWave(Orig, 5, 70, 550.0, {255, 0, 0})
	ShockWave(Orig, 5, 70, 450.0, {144, 238, 144})
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 300.0 && get_user_team(i) == 2)
		{
			shake_screen(i)
			ScreenFade(i, 2, {79, 79, 79}, 120)
			ExecuteHam(Ham_TakeDamage, i, 0, i, DAMAGE_HOLE1, DMG_SLASH)
			//user_kill(i)
		}
	}
}
public attack_hole(Teddy)
{
	Teddy -= HOLE_TEDDY
	new ent = create_entity("info_target")
	
	static Float:Origin[3]
	pev(Teddy, pev_origin, Origin)
	
	Origin[2] -= 10.0
	
	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_classname, "teddy_final")
	engfunc(EngFunc_SetModel, ent, Boss_Hole_Effect)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	new Float:maxs[3] = {1.0,1.0,1.0}
	new Float:mins[3] = {-1.0,-1.0,-1.0}
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	set_pev(ent, pev_animtime, get_gametime())
	anim(ent, 0)
	
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)	
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(Teddy, i) <= 1000.0 && get_user_team(i) == 2)
		{
			static arg[2]
			arg[0] = Teddy
			arg[1] = i
			
			set_task(0.01, "Jalar_Humanos", HOLE1_TEDDY, arg, sizeof(arg), "b")
		}
	}
	
	set_task(5.8, "stop_jalamiento", Teddy+2012)	
}
public Jalar_Humanos(arg[2])
{
	static Float:Origin[3], Float:Speed
	pev(arg[0], pev_origin, Origin)
	
	Speed = (1000.0 / entity_range(arg[0], arg[1])) * 75.0
	
	control_ai2(arg[1], Origin, Speed)
}
public stop_jalamiento(Teddy)
{
	Teddy -= 2012
	
	static ent
	ent = find_ent_by_class(-1, "teddy_final")
	
	remove_entity(ent)
	remove_task(HOLE1_TEDDY)
}
public reload_run3(ent)
{
	ent -= HOLE_TEDDY
	Start_Boss_CSO = 0
	anim(ent, ZBS_IDLE1)
}

//----------------------------Hole2 Teddy----------------------------
public Teddy_Hole2(ent)
{
	if(!pev_valid(ent) || Start_Boss_CSO)
		return	
		
	Start_Boss_CSO = 1
	anim(ent, ZBS_ATTACK_HOLE2)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[13], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(8.0, "reload_run3", ent+HOLE_TEDDY)
	set_task(5.0, "Damage_Teddy5", ent+HOLE_TEDDY)
	set_task(0.1, "attack_hole", ent+HOLE_TEDDY)
	
	set_task(5.0, "Hole_Teddy_Sound", ent+HOLE_TEDDY)
}
public Hole_Teddy_Sound(ent)
{
	ent -= HOLE_TEDDY
	emit_sound(ent, CHAN_BODY, Sound_Boss_CSO[16], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public Damage_Teddy5(ent)
{
	ent -= HOLE_TEDDY
	if(!pev_valid(ent))
		return	
	
	static Float:Orig[3]
	pev(ent, pev_origin, Orig)
	ShockWave(Orig, 5, 70, 750.0, {255, 0, 0})
	ShockWave(Orig, 5, 70, 650.0, {144, 238, 144})
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 450.0 && get_user_team(i) == 2)
		{
			shake_screen(i)
			Congelar(i)
		}
	}
}
public Congelar(id)
{
	if (!is_user_alive(id))
	return;
	
	ice_entity(id, 1)
	frost_explode(id)
	
	if (pev(id, pev_flags) & FL_ONGROUND)
	set_pev(id, pev_gravity, 999999.9)
	else
	set_pev(id, pev_gravity, 0.000001)
	
	g_bCongelado[id] = true
	
	set_task(7.0, "Descongelar", id)
}

public Descongelar(id)
{
	//if (!is_user_alive(id))
	//return;
	
	ice_entity(id, 0)
	remove_frost(id)
	
	g_bCongelado[id] = false
	
	set_pev(id, pev_gravity, 1.0)
	set_pev(id, pev_maxspeed, 250.0)
}

//----------------------------Meteor Teddy----------------------------
public Attack_Meteor_Halloween(ent)
{
	if(!pev_valid(ent) || Start_Boss_CSO)
		return	
		
	Start_Boss_CSO = 1
	anim(ent, 11)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[14], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	//set_task(8.0, "reload_run4", ent+METEOR_TEDDY)
	set_task(6.0, "Damage_Teddy6", ent+METEOR_TEDDY)
	set_task(6.0, "Meteor_Sound", ent+METEOR_TEDDY)
	set_task(3.9, "Regalitos_Halloweeen", ent+METEOR_TEDDY)
}
public Meteor_Sound(ent)
{
	emit_sound(ent, CHAN_AUTO, Sound_Boss_CSO[15], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
public Damage_Teddy6(ent)
{
	ent -= METEOR_TEDDY
	if(!pev_valid(ent))
		return	
	
	static Float:Orig[3]
	pev(ent, pev_origin, Orig)
	ShockWave(Orig, 5, 70, 550.0, {255, 0, 0})
	ShockWave(Orig, 5, 70, 450.0, {144, 238, 144})
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 300.0 && get_user_team(i) == 2)
		{
			shake_screen(i)
			ScreenFade(i, 2, {79, 79, 79}, 120)
			//user_kill(i)
		}
	}
}
public reload_run4(ent)
{
	ent -= METEOR_TEDDY
	Start_Boss_CSO = 0
	anim(ent, ZBS_IDLE1)
}
//Code Sacado De Dias.... Solo Esto..
public Regalitos_Halloweeen(ent)
{
	ent -= METEOR_TEDDY
	if(!pev_valid(ent))
		return	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	static Float:Origin[3]
	get_position(ent, 150.0, 0.0, 50.0, Origin)
	//emit_sound(ent, CHAN_BODY, npc_sound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)

	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 4000 && get_user_team(i) == 2)
		{
			shake_screen(i)
			ScreenFade(i, 10, {255, 0, 0}, 120)
		}
	}
	set_task(0.1, "fire_attack_teddy", ent+METEOR_TEDDY)
	set_task(3.8, "remove_attack_teddy", ent+METEOR_TEDDY)
}

public remove_attack_teddy(ent)
{
	ent -= METEOR_TEDDY
	if(!pev_valid(ent))
		return	
	remove_task(ent+METEOR_TEDDY)
	set_task(2.1, "reload_run4", ent+METEOR_TEDDY)
}

public npc_ball_touch(ent, id)
{
	if(!pev_valid(ent))
		return
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(y_npc_hp)
	write_byte(10)
	write_byte(30)
	write_byte(4)
	message_end()	
	emit_sound(ent, CHAN_BODY, Sound_Boss_CSO[18], 1.0, ATTN_NORM, 0, PITCH_NORM)
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 250 && get_user_team(i) == 2)
		{
			shake_screen(i)
			ExecuteHam(Ham_TakeDamage, i, 0, i, DAMAGE_HALLOWEEN, DMG_SLASH)
			ScreenFade(i, 3, {255, 0, 0}, 120)
		}
	}
	remove_entity(ent)
}

public fire_attack_teddy(ent)
{
	ent -= METEOR_TEDDY
	if(!pev_valid(ent))
		return
	static Float:explosion[24][3], Float:ball_place[24][3]	
	explosion[0][0] = 200.0
	explosion[0][1] = 0.0
	explosion[0][2] = 500.0
	explosion[1][0] = 400.0
	explosion[1][1] = 0.0
	explosion[1][2] = 500.0
	explosion[2][0] = -200.0
	explosion[2][1] = 0.0
	explosion[2][2] = 500.0
	explosion[3][0] = -400.0
	explosion[3][1] = 0.0
	explosion[3][2] = 500.0
	explosion[4][0] = 0.0
	explosion[4][1] = 200.0
	explosion[4][2] = 500.0
	explosion[5][0] = 0.0
	explosion[5][1] = 400.0
	explosion[5][2] = 500.0
	explosion[6][0] = 0.0
	explosion[6][1] = -200.0
	explosion[6][2] = 500.0
	explosion[7][0] = 0.0
	explosion[7][1] = -400.0
	explosion[7][2] = 500.0
	explosion[8][0] = 200.0
	explosion[8][1] = 200.0
	explosion[8][2] = 500.0
	explosion[9][0] = 400.0
	explosion[9][1] = 400.0
	explosion[9][2] = 500.0
	explosion[10][0] = 200.0
	explosion[10][1] = 400.0
	explosion[10][2] = 500.0
	explosion[11][0] = 400.0
	explosion[11][1] = 200.0
	explosion[11][2] = 500.0
	explosion[12][0] = -200.0
	explosion[12][1] = 200.0
	explosion[12][2] = 500.0
	explosion[13][0] = -400.0
	explosion[13][1] = 400.0
	explosion[13][2] = 500.0
	explosion[14][0] = -200.0
	explosion[14][1] = 400.0
	explosion[14][2] = 500.0
	explosion[15][0] = -400.0
	explosion[15][1] = 200.0
	explosion[15][2] = 500.0
	explosion[16][0] = -200.0
	explosion[16][1] = -200.0
	explosion[17][2] = 500.0
	explosion[17][0] = -200.0
	explosion[17][1] = -200.0
	explosion[17][2] = 500.0
	explosion[18][0] = -200.0
	explosion[18][1] = -400.0
	explosion[18][2] = 500.0
	explosion[19][0] = -400.0
	explosion[19][1] = -200.0
	explosion[19][2] = 500.0
	explosion[20][0] = 200.0
	explosion[20][1] = -200.0
	explosion[20][2] = 500.0
	explosion[21][0] = 400.0
	explosion[21][1] = -400.0
	explosion[21][2] = 500.0
	explosion[22][0] = 200.0
	explosion[22][1] = -400.0
	explosion[22][2] = 500.0
	explosion[23][0] = 400.0
	explosion[23][1] = -200.0
	explosion[23][2] = 500.0
	for(new i = 0; i < sizeof(explosion); i++)
	{
		get_position(ent, explosion[i][0], explosion[i][1], explosion[i][2], ball_place[i])
		npc_fireball_big(ent, ball_place[i])
	}
	set_task(1.0, "fire_attack_teddy", ent+METEOR_TEDDY)
}

public npc_fireball_big(fireboss, Float:Origin[3])
{
	new ent = create_entity("info_target")
	static Float:Angles[3]
	pev(fireboss, pev_angles, Angles)
	entity_set_origin(ent, Origin)
	Angles[0] = -100.0
	entity_set_vector(ent, EV_VEC_angles, Angles)
	Angles[0] = 100.0
	entity_set_vector(ent, EV_VEC_v_angle, Angles)
	entity_set_string(ent, EV_SZ_classname, "Halloween_Meteos")
	entity_set_model(ent, Boss_Halloween)
	entity_set_int(ent, EV_INT_solid, 2)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	new Float:maxs[3] = {15.0, 15.0, 15.0}
	new Float:mins[3] = {-15.0, -15.0, -15.0}
	entity_set_size(ent, mins, maxs)
	set_pev(ent, pev_owner, fireboss)
	static Float:Velocity[3]
	VelocityByAim(ent, random_num(250, 1000), Velocity)
	set_pev(ent, pev_light_level, 180)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)	
	entity_set_vector(ent, EV_VEC_velocity, Velocity)
	burning(ent, 0.5)
}

public burning(ball, Float:size)
{
	static ent
	ent = create_entity("env_sprite")
	set_pev(ent, pev_takedamage, 0.0)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_classname, "Halloween_Meteos")
	engfunc(EngFunc_SetModel, ent, Boss_Halloween2)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)
	set_pev(ent, pev_light_level, 180)
	set_pev(ent, pev_scale, size)
	set_pev(ent, pev_owner, ball)
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 8.0)
	set_pev(ent, pev_frame, 0.1)
	set_pev(ent, pev_spawnflags, SF_SPRITE_STARTON)
	dllfunc(DLLFunc_Spawn, ent)
	fire_helloween_think(ent)
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	return ent
}
public fire_helloween_think(ent)
{
	if(!pev_valid(ent))
		return
	if(!pev_valid(pev(ent, pev_owner)))
	{
		remove_entity(ent)
		return
	}
	static owner
	owner = pev(ent, pev_owner)
	static Float:Origin[3]
	pev(owner, pev_origin, Origin)
	Origin[2] += 25.0
	entity_set_origin(ent, Origin)
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
}
//----------------------------Skills Full Final----------------------------


public fw_Player_Frozer(id)
{
	if (!is_user_alive(id))
	return;
	
	if (g_bCongelado[id])
	{
		set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})
		set_pev(id, pev_maxspeed, 1.0)
	}
}
public cso_boss_touch(ent, id)
{
	if(!pev_valid(id))
		return
		
	if(is_user_alive(id) && Damage_Touch)
	{
		ExecuteHam(Ham_TakeDamage, id, 0, id, DAMAGE_FINAL, DMG_SLASH)
		shake_screen(id)
		ScreenFade(id, 10, {255, 0, 0}, 120)
	}
}
public cso_boss_think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_iuser3))
		return
	if(pev(ent, pev_health) - 1000.0 < 0.0)
	{
		cso_boss_death(ent)
		set_pev(ent, pev_iuser3, 1)
		return
	}
	if(!Start_Boss_CSO)
	{
		static victim
		static Float:Origin[3], Float:ent_place[3], Float:player_place[3], Float:EnemyOrigin[3]
		victim = enemy_distance(ent)
		pev(victim, pev_origin, EnemyOrigin)
		pev(ent, pev_origin, Origin)
		
		if(is_user_alive(victim))
		{
			if(entity_range(victim, ent) <= 170)
			{
				Anim_Victim(ent, Origin, victim, EnemyOrigin)
				Teddy_Attack(ent)
				set_pev(ent, pev_nextthink, get_gametime() + 0.1)
			} else {
				if(pev(ent, pev_sequence) != ZBS_WALK)
					anim(ent, ZBS_WALK)
				set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
				
				if(get_gametime() - 10.0 > Attack_Time)
				{
					new Random_Skill_Teddy = random_num(0,4)
					switch(Random_Skill_Teddy) {
						case 0: Correr_Teddy(ent)
						case 1: Tentacle_Hammer(ent)
						case 2: Teddy_Hole1(ent)
						case 3: Teddy_Hole2(ent)
						case 4: Attack_Meteor_Halloween(ent)
					}
					Attack_Time = get_gametime()
				}
				for(new i = 0; i < get_maxplayers(); i++)
				{
					if(is_user_alive(i) && entity_range(ent, i) <= 600 && get_user_team(i) == 2)
					{
						shake_screen(i)
					}
				}
				
				emit_sound(ent, CHAN_STREAM, Sound_Boss_CSO[19], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				pev(ent, pev_origin, ent_place)
				pev(victim, pev_origin, player_place)
				Anim_Victim(ent, ent_place, victim, player_place)
				
				control_ai(ent, victim, SPEED_TEDDY)
				
				if(pev(ent, pev_iuser4) != victim)
					set_pev(ent, pev_iuser4, victim)
				set_pev(ent, pev_nextthink, get_gametime() + 0.0)
			}
		} else {
			if(pev(ent, pev_sequence) != ZBS_IDLE1)
				anim(ent, ZBS_IDLE1)
			set_pev(ent, pev_nextthink, get_gametime() + 0.0)
		}		
	} else {
		set_pev(ent, pev_nextthink, get_gametime() + 0.0)
	}
	return
}
public cso_boss_death(ent)
{	
	emit_sound(ent, CHAN_BODY, Sound_Boss_CSO[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	anim(ent, TEDDY_DEATH)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
	set_pev(ent, pev_deadflag, DEAD_DYING)
	
	remove_task(ent+HP_SPRITE)
	remove_task(ent+ATTACK_TASK)
	remove_task(ent+CORRER_TEDDY)
	remove_task(ent+TENTACLE_TEDDY)
	remove_task(ent+HOLE_TEDDY)
	remove_task(ent+HOLE1_TEDDY)
	remove_task(ent+METEOR_TEDDY)
	remove_entity_name("teddy_final")
	remove_entity_name("DareDevil")
	remove_entity_name("Halloween_Meteos")
	remove_entity_name("Damage_Tentacle_Teddy")
	
	
	set_task(7.0, "delete_cso_boss", ent)
	return HAM_SUPERCEDE	
}
public delete_cso_boss(ent)
{
	remove_entity(ent);
	remove_entity(y_hpbar);
	
	for( new i = 1; i <= 32; i++ )
	{
		if( !is_user_bot( i ) || !is_user_hltv( i ) )
		{
			cod_add_user_honor( i, g_damagedealt[i] );
			ColorChat( i, GREEN, "[COD]^x01 Zadales^x03 BOSSOWI^x04 %d^x01 obrazen, otrzymales^x03 %d^x01 honoru!", g_damagedealt[i], g_damagedealt[i] );
		}
	}
}
public cso_boss_take_damage(victim, inflictor, attacker, Float:damage, damagebits)
{
	static Float:Origin[3];
	fm_get_aim_origin(attacker, Origin);
	
	create_blood(Origin);

	emit_sound(victim, CHAN_BODY, Sound_Boss_CSO[7], 1.0, ATTN_NORM, 0, PITCH_NORM);
		
	g_damagedealt[attacker] += floatround(damage);
}
public enemy_distance(entid)
{
	new Float:range2;
	new Float:maxrange=2000.0;
	new indexid=0;

	for(new i=1;i<=get_maxplayers();i++)
	{
		if(is_user_alive(i) && is_valid_ent(i) && attacking1(entid, i) && get_user_team(i) == 2)
		{
			range2 = entity_range(entid, i)
			if(range2 <= maxrange)
			{
				maxrange=range2;
				indexid=i;
			}
		}			
	}	
	return (indexid) ? indexid : 0
}
public Anim_Victim(ent, Float:ent_place[3], target, Float:player_place[3]) 
{
	if(target) 
	{
		new Float:newAngle[3]
		entity_get_vector(ent, EV_VEC_angles, newAngle)
		new Float:x = player_place[0] - ent_place[0]
		new Float:z = player_place[1] - ent_place[1]
		new Float:radians = floatatan(z/x, radian)
		newAngle[1] = radians * (180 / 3.14)
		if (player_place[0] < ent_place[0])
			newAngle[1] -= 180.0
       		entity_set_vector(ent, EV_VEC_v_angle, newAngle)
		entity_set_vector(ent, EV_VEC_angles, newAngle)
	}
}
public bool:attacking1(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false
	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}
		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]
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
		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0)
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0)
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0)
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}
public control_ai(ent, victim, Float:speed)
{
	static Float:fl_Velocity[3]
	static Float:VicOrigin[3], Float:EntOrigin[3]
	pev(ent, pev_origin, EntOrigin)
	pev(victim, pev_origin, VicOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed

		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = 0.0
	} else
	{
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}
stock control_ai2(ent, Float:VicOrigin[3], Float:speed)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}
stock ScreenFade(id, Timer, Colors[3], Alpha) {	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}
stock shake_screen(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}
stock anim(ent, sequence) {
         set_pev(ent, pev_sequence, sequence)
         set_pev(ent, pev_animtime, halflife_time())
         set_pev(ent, pev_framerate, 1.0)
}
stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle)
	vAngle[0] = 0.0
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
stock create_blood(const Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(y_bleeding[1])
	write_short(y_bleeding[0])
	write_byte(218)
	write_byte(7)
	message_end()
}
stock ShockWave(Float:Orig[3], Life, Width, Float:Radius, Colorr[3]) 
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Orig, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, Orig[0])
	engfunc(EngFunc_WriteCoord, Orig[1])
	engfunc(EngFunc_WriteCoord, Orig[2]-40.0)
	engfunc(EngFunc_WriteCoord, Orig[0])
	engfunc(EngFunc_WriteCoord, Orig[1]) 
	engfunc(EngFunc_WriteCoord, Orig[2]+Radius)
	write_short(g_news[0]) 
	write_byte(0) 
	write_byte(0) 
	write_byte(Life) 
	write_byte(Width) 
	write_byte(0) 
	write_byte(Colorr[0]) 
	write_byte(Colorr[1]) 
	write_byte(Colorr[2]) 
	write_byte(255) 
	write_byte(0) 
	message_end()
}
stock ice_entity( id, status ) 
{
	if(status)
	{
		static ent, Float:o[3]
		if(!is_user_alive(id))
		{
			ice_entity( id, 0 )
			return
		}
		
		if( is_valid_ent(iceent[id]) )
		{
			if( pev( iceent[id], pev_iuser3 ) != id )
			{
				if( pev(iceent[id], pev_team) == 6969 ) remove_entity(iceent[id])
			}
			else
			{
				pev( id, pev_origin, o )
				if( pev( id, pev_flags ) & FL_DUCKING  ) o[2] -= 15.0
				else o[2] -= 35.0
				entity_set_origin(iceent[id], o)
				return
			}
		}
		
		pev( id, pev_origin, o )
		if( pev( id, pev_flags ) & FL_DUCKING  ) o[2] -= 15.0
		else o[2] -= 35.0
		ent = create_entity("info_target")
		set_pev( ent, pev_classname, "DareDevil" )
		
		entity_set_model(ent, ice_model)
		dllfunc(DLLFunc_Spawn, ent)
		set_pev(ent, pev_solid, SOLID_BBOX)
		set_pev(ent, pev_movetype, MOVETYPE_FLY)
		entity_set_origin(ent, o)
		entity_set_size(ent, Float:{ -3.0, -3.0, -3.0 }, Float:{ 3.0, 3.0, 3.0 } )
		set_pev( ent, pev_iuser3, id )
		set_pev( ent, pev_team, 6969 )
		set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 255)
		iceent[id] = ent
	}
	else
	{
		if( is_valid_ent(iceent[id]) )
		{
			if( pev(iceent[id], pev_team) == 6969 ) remove_entity(iceent[id])
			iceent[id] = -1
		}
	}
}

frost_explode(ent)
{
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	// Make the explosion
	create_blast(originF)
	
	emit_sound(ent, CHAN_AUTO, frozer, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	message_begin(MSG_ONE, g_msgScreenFade, _, ent)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
}
public remove_frost(id)
{
	// Gradually remove screen's blue tint
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short((1<<12)) // duration
	write_short(0) // hold time
	write_short(0x0000) // fade type
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
}
create_blast(const Float:originF[3])
{
    // Medium ring
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
    write_byte(TE_BEAMCYLINDER) // TE id
    engfunc(EngFunc_WriteCoord, originF[0]) // x
    engfunc(EngFunc_WriteCoord, originF[1]) // y
    engfunc(EngFunc_WriteCoord, originF[2]) // z
    engfunc(EngFunc_WriteCoord, originF[0]) // x axis
    engfunc(EngFunc_WriteCoord, originF[1]) // y axis
    engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
    write_short(g_exploSpr) // sprite
    write_byte(0) // startframe
    write_byte(0) // framerate
    write_byte(4) // life
    write_byte(60) // width
    write_byte(0) // noise
    write_byte(0) // red
    write_byte(191) // green
    write_byte(255) // blue
    write_byte(200) // brightness
    write_byte(0) // speed
    message_end()
    
    // Largest ring
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
    write_byte(TE_BEAMCYLINDER) // TE id
    engfunc(EngFunc_WriteCoord, originF[0]) // x
    engfunc(EngFunc_WriteCoord, originF[1]) // y
    engfunc(EngFunc_WriteCoord, originF[2]) // z
    engfunc(EngFunc_WriteCoord, originF[0]) // x axis
    engfunc(EngFunc_WriteCoord, originF[1]) // y axis
    engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
    write_short(g_exploSpr) // sprite
    write_byte(0) // startframe
    write_byte(0) // framerate
    write_byte(4) // life
    write_byte(60) // width
    write_byte(0) // noise
    write_byte(0) // red
    write_byte(191) // green
    write_byte(255) // blue
    write_byte(200) // brightness
    write_byte(0) // speed
    message_end()
    
    // Luz Dinamica
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
    write_byte(TE_DLIGHT) // TE id
    engfunc(EngFunc_WriteCoord, originF[0]) // x
    engfunc(EngFunc_WriteCoord, originF[1]) // y
    engfunc(EngFunc_WriteCoord, originF[2]) // z
    write_byte(50) // radio
    write_byte(0) // red
    write_byte(191) // green
    write_byte(255) // blue
    write_byte(30) // vida en 0.1, 30 = 3 segundos
    write_byte(30) // velocidad de decaimiento
    message_end()

    engfunc(EngFunc_MessageBegin, MSG_BROADCAST,SVC_TEMPENTITY, originF, 0)
    write_byte(TE_EXPLOSION)
    engfunc(EngFunc_WriteCoord, originF[0]) // x axis
    engfunc(EngFunc_WriteCoord, originF[1]) // y axis
    engfunc(EngFunc_WriteCoord, originF[2]+10) // z axis
    write_short(g_explosfr)
    write_byte(17)
    write_byte(15)
    write_byte(TE_EXPLFLAG_NOSOUND)
    message_end();
    
    
    engfunc(EngFunc_MessageBegin, MSG_BROADCAST,SVC_TEMPENTITY, originF, 0)
    write_byte(TE_SPRITETRAIL) // TE ID
    engfunc(EngFunc_WriteCoord, originF[0]) // x axis
    engfunc(EngFunc_WriteCoord, originF[1]) // y axis
    engfunc(EngFunc_WriteCoord, originF[2] + 40) // z axis
    engfunc(EngFunc_WriteCoord, originF[0]) // x axis
    engfunc(EngFunc_WriteCoord, originF[1]) // y axis
    engfunc(EngFunc_WriteCoord, originF[2]) // z axis
    write_short(frostgib) // Sprite Index
    write_byte(30) // Count
    write_byte(10) // Life
    write_byte(4) // Scale
    write_byte(50) // Velocity Along Vector
    write_byte(10) // Rendomness of Velocity
    message_end();
}

public god( id )
{
	if( has_flag( id, "a" ) )
	{
		set_user_godmode( id, 1 )
	}
}

public TeddyMenu(id)
{
	if( has_flag( id, "a" ) )
	{
		new menu = menu_create("\yMenu Teddy Boss", "TeddyMenuHNDL")

		menu_additem(menu, "Wczytaj Config i pozycje", "1", 0);
		menu_additem(menu, "Przenies wszystkich do CT", "2", 0);
		menu_additem(menu, "Zresp wszystkich graczy", "3", 0);
		menu_additem(menu, "Zacznij Event", "4", 0);
		menu_additem(menu, "Ustaw poprzedni config", "5", 0);
		menu_additem(menu, "NOCLIP ON", "6", 0);
		menu_additem(menu, "NOCLIP OOFF", "7", 0);
     	
		menu_display(id, menu, 0) 
	}
	return PLUGIN_HANDLED;
} 
public TeddyMenuHNDL(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new key = str_to_num(data)

	switch(key)
	{
		case 1:
		{
			set_cvar_num("mp_roundtime", 9);
			//set_cvar_num("semiclip", 0);
			//set_cvar_num("bb_komendy", 0);
			pev(id, pev_angles, VAngles);
			pev(id, pev_origin, Origin);
 			client_print(id, print_center, "Config wczytany.");
			TeddyMenu(id);
		}
		case 2:
		{
			for (new i = 1; i <= get_maxplayers(); i++)
			{
				if( is_user_connected( i ) && !is_user_bot( i ) && !is_user_hltv( i ) && get_user_team( i ) == 1 )
					cs_set_user_team( i, CS_TEAM_CT );
			}
			client_print(id, print_center, "Wszyscy przeniesieni do CT.");
			TeddyMenu(id);
		}
		case 3:
		{
			for (new i = 1; i <= get_maxplayers(); i++)
			{
				if( is_user_connected( i ) && !is_user_bot( i ) && !is_user_hltv( i ) )
					ExecuteHamB(Ham_CS_RoundRespawn, i)
			}
			client_print(id, print_center, "Wszyscy gracze zrespieni.");
			TeddyMenu(id);
		}
		case 4:
		{
			client_cmd( id, "say /rele" );
			create_cso_boss();
			client_print(0, print_center, "EVENT ROZPOCZETY!");
			
			set_pev(g_iEntBarrier,pev_solid,SOLID_NOT)
			set_pev(g_iEntBarrier,pev_renderamt,Float:{ 0.0 })
		}
		case 5:
		{
			set_cvar_num("mp_roundtime", 3);
			set_cvar_num("semiclip", 1);
			//set_cvar_num("bb_komendy", 1);
			client_print(id, print_center, "Poprzedni config wczytany.");
		}
		case 6:
		{
			set_user_noclip( id, 1 )
		}
		case 7:
		{
			set_user_noclip( id, 0 )
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}