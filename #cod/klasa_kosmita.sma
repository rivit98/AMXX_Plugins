#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <codmod>

#pragma tabsize 0

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define FIRERATE 0.2
#define HITSD 0.7
#define RELOADSPEED 5.0
#define DAMAGE 45.0
#define DAMAGE_MULTI 3.0

#define CSW_WPN CSW_FAMAS
new const weapon[] = "weapon_famas"

new bool:ma_klase[33]
new g_iCurWpn[33], Float:g_flLastFireTime[33]
new g_sprBeam, g_sprExp, g_sprBlood, g_msgDamage, g_msgScreenFade, g_msgScreenShake

const m_pPlayer = 		41
const m_fInReload =		54
const m_pActiveItem = 		373
const m_flNextAttack = 		83
const m_flTimeWeaponIdle = 	48
const m_flNextPrimaryAttack = 	46
const m_flNextSecondaryAttack =	47

new const spr_beam[] = "sprites/plasma/plasma_beam.spr"
new const spr_exp[] = "sprites/plasma/plasma_exp.spr"
new const spr_blood[] = "sprites/blood.spr"
new const snd_fire[][] = { "plasma/plasma_fire.wav" }
new const snd_reload[][] = { "plasma/plasma_reload.wav" }
new const snd_hit[][] = { "plasma/plasma_hit.wav" }

const UNIT_SECOND =		(1<<12)
const ENG_NULLENT = 		-1
const WPN_MAXCLIP =		25
const ANIM_FIRE = 		5
const ANIM_DRAW = 		10
const ANIM_RELOAD =		9
const EV_INT_WEAPONKEY = 	EV_INT_impulse
const WPNKEY = 			2816

new const nazwa[] = "Kosmita [S.Premium]";
new const opis[] = "Dostaje Dzialo Gaussa";
new const bronie = (1<<CSW_FAMAS);
new const zdrowie = 15;
new const kondycja = 15;
new const inteligencja = 0;
new const wytrzymalosc = -5;
new const frakcja[] = "Klasy [S.Premium]";

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define gaussgun_WEAPONKEY 893
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

#define TASK_FBURN				100
#define ID_FBURN					( taskid - TASK_FBURN )

#define MAX_CLIENTS				32

new bool:g_fRoundEnd

#define FIRE_DURATION		6
#define FIRE_DAMAGE		25

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83
#define MAKE_MATTERY 7045

#define gaussgun_RELOAD_TIME 	2.5
#define gaussgun_RELOAD		4
#define gaussgun_DRAW		5
#define gaussgun_SHOOT1		2
#define gaussgun_SHOOT2		1

new g_flameSpr
new g_smokeSpr

new bool: ma_bron[33];

new Float:idle[33]
new bfg10k_ammo[33]
new bfg_shooting[33];

enum {NONE = 0, SHOOTING, SHOOTED };

new sprite_blast;
new sprite_laser;


new g_burning_duration[ MAX_CLIENTS + 1 ]

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "sound/weapons/gaussfire.wav" }

new gaussgun_V_MODEL[64] = "models/v_gaussgun.mdl"
new gaussgun_P_MODEL[64] = "models/p_gaussgun.mdl"
new gaussgun_W_MODEL[64] = "models/w_gaussgun.mdl"

//new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_gaussgun, cvar_recoil_gaussgun, g_itemid_gaussgun, cvar_clip_gaussgun, cvar_spd_gaussgun, cvar_gaussgun_ammo
new g_MaxPlayers, g_orig_event_gaussgun, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_gaussgun[33], g_clip_ammo[33], g_gaussgun_TmpClip[33], oldweap[33]
new gaussgun_sprite

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_awp", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("Klasa CodMan", "1.0", "dw11")
	cod_register_class(nazwa, opis, bronie, zdrowie, kondycja, inteligencja, wytrzymalosc, frakcja);	
	
		register_forward(FM_CmdStart, "CmdStart")
	register_forward(FM_PlayerPreThink, "PreThink");
	
	RegisterHam(Ham_Item_Deploy, "weapon_p90", "Weapon_Deploy", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_p90", "Weapon_WeaponIdle");
	
	register_event("ResetHUD", "ResetHUD", "abe");
	register_event("HLTV", "Nowa_Runda", "a", "1=0", "2=0");
	
	register_touch("bfg10000", "*" , "DotykWiazki");
	
	register_think("bfg10000", "BFGThink");

	RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m3", "fw_gaussgun_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_gaussgun_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_gaussgun_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m3", "gaussgun_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "gaussgun_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "gaussgun_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam( Ham_Spawn, "player", "PlayerSpawn_Post", 1 );
	register_forward(FM_SetModel, "fw_SetModel")
	register_event( "DeathMsg", "EV_DeathMsg", "a" );
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	//RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	//RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	//RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	//RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	//RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	//RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	//RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_dmg_gaussgun = register_cvar("zp_gaussgun_dmg", "1.5")
	cvar_recoil_gaussgun = register_cvar("zp_gaussgun_recoil", "1.01")
	cvar_clip_gaussgun = register_cvar("zp_gaussgun_clip", "5")
	cvar_spd_gaussgun = register_cvar("zp_gaussgun_spd", "0.5")
	cvar_gaussgun_ammo = register_cvar("zp_gaussgun_ammo", "50")
	g_MaxPlayers = get_maxplayers()

	register_event("CurWeapon", "event_CurWeapon", "b", "1=1")	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post1", 1)
	RegisterHam(Ham_Item_Deploy, weapon, "fw_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon, "fw_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon, "fw_PostFrame")	
	g_msgDamage = get_user_msgid("Damage")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public plugin_precache()
{
	sprite_blast = precache_model("sprites/dexplo.spr");
	sprite_laser = precache_model("sprites/dot.spr")
	precache_sound("weapons/bfg_fire.wav");
	precache_model("models/bfg_mattery.mdl");
	precache_model("models/v_bfg10000.mdl");
	precache_model("models/p_bfg10000.mdl");

	precache_model(gaussgun_V_MODEL)
	precache_model(gaussgun_P_MODEL)
	precache_model(gaussgun_W_MODEL)
	precache_model("models/plasma/v_plasma_16.mdl")
	precache_model("models/plasma/p_plasma.mdl")
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	gaussgun_sprite = precache_model("sprites/gaussgun.spr")

	g_flameSpr = precache_model( "sprites/flame.spr" );
	g_smokeSpr = precache_model( "sprites/black_smoke3.spr" );
	g_sprBlood = precache_model(spr_blood)
	g_sprBeam = precache_model(spr_beam)
	g_sprExp = precache_model(spr_exp)

	static i
	for(i = 0; i < sizeof snd_fire; i++)
		precache_sound(snd_fire[i])
	for(i = 0; i < sizeof snd_hit; i++)
		precache_sound(snd_hit[i])
	for(i = 0; i < sizeof snd_reload; i++)
		precache_sound(snd_reload[i])	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

/*================================================================================
public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_M3) return
	
	if(!g_has_gaussgun[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}
=================================================================================*/

public cod_class_enabled(id)
{
	if(!(get_user_flags(id) & ADMIN_LEVEL_F))
	{
		client_print(id, print_chat, "Nie masz uprawnien, aby uzywac tej klasy.")
		return COD_STOP;
	}
	ma_klase[id] = true;
	g_has_gaussgun[id] = true;
	give_gaussgun(id)
		ma_bron[id] = true;
	bfg10k_ammo[id] = 2;


	return COD_CONTINUE;
}


public cod_class_disabled(id)
{
	ma_klase[id] = false;
	g_has_gaussgun[id] = false;
	cod_take_weapon(id, CSW_M3)
		ma_bron[id] = false;
	bfg10k_ammo[id] = 0;

}

public CmdStart(id, uc_handle)
{
	new weapon = get_user_weapon(id);
	
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;	
		
	if(weapon == 30 && ma_bron[id])
	{
		if(!ma_klase[id])
		return FMRES_IGNORED
		
		if(!bfg10k_ammo[id] && (pev(id, pev_oldbuttons) & IN_ATTACK))
		{
			client_print(id, print_center, "Wykorzystales juz wszystkie wiazki!");
			return PLUGIN_CONTINUE;
		}
		new Button = get_uc(uc_handle, UC_Buttons)
		new OldButton = pev(id, pev_oldbuttons)	
		new ent = fm_find_ent_by_owner(-1, "weapon_p90", id);
		
		if(Button & IN_ATTACK && !(OldButton & IN_ATTACK) && bfg_shooting[id] == NONE)
		{
			Button &= ~IN_ATTACK;
			set_uc(uc_handle, UC_Buttons, Button);
			
			if(!bfg10k_ammo[id] || !idle[id]) 
				return FMRES_IGNORED;
			if(idle[id] && (get_gametime()-idle[id]<=0.7)) 
				return FMRES_IGNORED;
				
			set_pev(id, pev_weaponanim, 4);
			emit_sound(id, CHAN_ITEM, "weapons/bfg_fire.wav", 0.5, ATTN_NORM, 0, PITCH_NORM);
	
			message_begin(MSG_ONE, get_user_msgid("BarTime"), {0, 0, 0}, id)
			write_byte(1)
			write_byte(0)
			message_end()
	
			bfg_shooting[id] = SHOOTING
			set_task(0.8, "MakeMattery", id+MAKE_MATTERY)
			return FMRES_IGNORED
		}
		if(bfg_shooting[id] == SHOOTING && (Button & (IN_USE | IN_ATTACK2 | IN_BACK | IN_FORWARD | IN_CANCEL | IN_JUMP | IN_MOVELEFT | IN_MOVERIGHT | IN_RIGHT)))
		{
			remove_task(id+MAKE_MATTERY)
			message_begin(MSG_ONE, get_user_msgid("BarTime"), {0, 0, 0}, id)
			write_byte(0)
			write_byte(0)
			message_end()
			bfg_shooting[id] = NONE
			emit_sound(id, CHAN_ITEM, "weapons/bfg_fire.wav", 0.5, ATTN_NORM, (1<<5), PITCH_NORM)
			return FMRES_IGNORED
		}
		if(Button & IN_RELOAD)
		{
			Button &= ~IN_RELOAD;
			set_uc(uc_handle, UC_Buttons, Button);
			
			set_pev(id, pev_weaponanim, 0);
			set_pdata_float(id, 83, 0.5, 4);
			if(ent)
				set_pdata_float(ent, 48, 0.5+3.0, 4);
		}
		
		if(ent)
			cs_set_weapon_ammo(ent, -1);
		cs_set_user_bpammo(id, 30, bfg10k_ammo[id]);	
	}
	else if(weapon != 30 && ma_bron[id])
	{
		idle[id] = 0.0;
		if(task_exists(id+MAKE_MATTERY))
		{
			remove_task(id+MAKE_MATTERY)
			message_begin(MSG_ONE, get_user_msgid("BarTime"), {0, 0, 0}, id)
			write_byte(0)
			write_byte(0)
			message_end()
			bfg_shooting[id] = NONE
			emit_sound(id, CHAN_ITEM, "weapons/bfg_fire.wav", 0.5, ATTN_NORM, (1<<5), PITCH_NORM)
			return FMRES_IGNORED
		}
	}
	return FMRES_IGNORED
}
public MakeMattery(id)
{
	id-=MAKE_MATTERY
	
	bfg_shooting[id] = SHOOTED
	bfg10k_ammo[id]--
	
	new Float: Origin[3], Float: vAngle[3], Float: Velocity[3];
	entity_get_vector(id, EV_VEC_v_angle, vAngle);
	entity_get_vector(id, EV_VEC_origin , Origin);
	set_pev(id, pev_weaponanim, 2);
	
	new ent = create_entity("info_target");
		
	entity_set_string(ent, EV_SZ_classname, "bfg10000");
	entity_set_model(ent, "models/bfg_mattery.mdl");
	fm_set_user_rendering(ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 255)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),_, id);
	write_short(255<<14);
	write_short(2<<12);
	write_short(255<<14);
	message_end();
	
	vAngle[0] *= -1.0;
	
	entity_set_origin(ent, Origin);
	entity_set_vector(ent, EV_VEC_angles, vAngle);
	
	entity_set_int(ent, EV_INT_effects, 2);
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_edict(ent, EV_ENT_owner, id);
	
	VelocityByAim(id, 300 , Velocity);
	entity_set_vector(ent, EV_VEC_velocity ,Velocity);
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
}
public DotykWiazki(ent)
{
	if (!is_valid_ent(ent))
		return PLUGIN_CONTINUE;

	new attacker = entity_get_edict(ent, EV_ENT_owner);
	

	new Float:fOrigin[3];
	entity_get_vector(ent, EV_VEC_origin, fOrigin);	
	
	new iOrigin[3];
	for(new i=0;i<3;i++)
		iOrigin[i] = floatround(fOrigin[i]);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
	write_byte(TE_EXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(sprite_blast);
	write_byte(32); 
	write_byte(20); 
	write_byte(0);
	message_end();

	new entlist[33];
	new numfound = find_sphere_class(ent, "player", 120.0, entlist, 32);
	
	for (new i=0; i<=numfound; i++)
	{		
		new pid = entlist[i];
		
		if (!is_user_alive(pid) || get_user_team(attacker) == get_user_team(pid) || !(pev(ent, pev_flags) & FL_ONGROUND))
			continue;
		cod_inflict_damage(attacker, pid, 10.0, 0.2, ent, (1<<24));
	}
	remove_entity(ent);
	bfg_shooting[attacker] = NONE
	return PLUGIN_CONTINUE
}	
public ResetHUD(id)
{
	bfg10k_ammo[id] = 2;
	bfg_shooting[id] = NONE
}

public BFGThink(ent)
{
	if(entity_get_int(ent, EV_INT_iuser2))
		return PLUGIN_CONTINUE;
	
	
	entity_set_int(ent, EV_INT_iuser1, 1);
	
	new attacker = entity_get_edict(ent, EV_ENT_owner);
	
	new entlist[33];
	new numfound = find_sphere_class(ent, "player", 500.0 , entlist, 32);
		
	for (new i=0; i<numfound; i++)
	{		
		new pid = entlist[i];
		
		if (is_user_alive(pid) && get_user_team(attacker) != get_user_team(pid) && fm_is_ent_visible(ent, pid))
		{
			cod_inflict_damage(attacker, pid, 5.0, 0.1, ent, (1<<24));
			
			new Float:vec1[3]	
			entity_get_vector(ent, EV_VEC_origin, vec1);		
			
			new vec2[3]
			get_user_origin(pid, vec2)
			new iOrigin[3];
			for(new i=0;i<3;i++)
				iOrigin[i] = floatround(vec1[i]);

			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte (0)     //TE_BEAMENTPOINTS 0
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_coord(vec2[0])
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short(sprite_laser)
			write_byte(1) // framestart
			write_byte(5) // framerate
			write_byte(2) // life
			write_byte(10) // width
			write_byte(0) // noise
			write_byte(0)     // r, g, b
			write_byte(255)       // r, g, b
			write_byte(0)       // r, g, b
			write_byte(255) // brightness
			write_byte(150) // speed
			message_end()
		}
	}

	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1);
	
	return PLUGIN_CONTINUE;
}
public Weapon_Deploy(ent)
{
	new id = get_pdata_cbase(ent, 41, 4);
	if(ma_bron[id])
	{
		set_pev(id, pev_viewmodel2, "models/v_bfg10000.mdl");
		set_pev(id, pev_weaponmodel2, "models/p_bfg10000.mdl");
	}
	return PLUGIN_CONTINUE;
}
public Weapon_WeaponIdle(ent)
{
	new id = get_pdata_cbase(ent, 41, 4);
	if(get_user_weapon(id) == 30 && ma_bron[id])
	{
		if(!idle[id]) 
			idle[id] = get_gametime();
	}
}
public Nowa_Runda()
{
        new ent = find_ent_by_class(-1, "bfg10000");
        while(ent > 0)
        {
                remove_entity(ent);
                ent = find_ent_by_class(ent, "bfg10000");
        }       
}

public event_CurWeapon(id)
{
	if(!is_user_alive(id))
	return PLUGIN_CONTINUE
		
	g_iCurWpn[id] = read_data(2)
	
		
	if(!ma_klase[id] || g_iCurWpn[id] != CSW_WPN) 
		return PLUGIN_CONTINUE
		
	entity_set_string(id, EV_SZ_viewmodel, "models/plasma/v_plasma_16.mdl")
	entity_set_string(id, EV_SZ_weaponmodel, "models/plasma/p_plasma.mdl")
	return PLUGIN_CONTINUE
}

public fw_CmdStart(id, handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	if(!ma_klase[id])
		return FMRES_IGNORED
			
	if(g_iCurWpn[id] != CSW_WPN)
		return FMRES_IGNORED
		
	static iButton
	iButton = get_uc(handle, UC_Buttons)
	
	if(iButton & IN_ATTACK)
	{
		set_uc(handle, UC_Buttons, iButton & ~IN_ATTACK)
		
		static Float:flCurTime
		flCurTime = halflife_time()
		
		if(flCurTime - g_flLastFireTime[id] < FIRERATE)
			return FMRES_IGNORED
			
		static iWpnID, iClip
		iWpnID = get_pdata_cbase(id, m_pActiveItem, 5)
		iClip = cs_get_weapon_ammo(iWpnID)
		
		if(get_pdata_int(iWpnID, m_fInReload, 4))
			return FMRES_IGNORED
		
		set_pdata_float(iWpnID, m_flNextPrimaryAttack, FIRERATE, 4)
		set_pdata_float(iWpnID, m_flNextSecondaryAttack, FIRERATE, 4)
		set_pdata_float(iWpnID, m_flTimeWeaponIdle, FIRERATE, 4)
		g_flLastFireTime[id] = flCurTime
		if(iClip <= 0)
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iWpnID)
			return FMRES_IGNORED
		}
		primary_attack(id)
		make_punch(id, 50)
		cs_set_weapon_ammo(iWpnID, --iClip)
		
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED
}

public fw_UpdateClientData_Post1(id, sendweapons, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
		
	if(!ma_klase[id])
		return FMRES_IGNORED
	
	if(g_iCurWpn[id] != CSW_WPN)
		return FMRES_IGNORED
		
	set_cd(handle, CD_flNextAttack, halflife_time() + 0.001)
	return FMRES_HANDLED
}

public fw_Deploy_Post(wpn)
{
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)
	
	if(is_user_connected(id) && ma_klase[id])
	{
		set_wpnanim(id, ANIM_DRAW)
	}
	return HAM_IGNORED
}

public fw_PostFrame(wpn)
{
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)

	if(is_user_alive(id) && ma_klase[id])
	{
		static Float:flNextAttack, iBpAmmo, iClip, iInReload
		iInReload = get_pdata_int(wpn, m_fInReload, 4)
		flNextAttack = get_pdata_float(id, m_flNextAttack, 5)
		iBpAmmo = cs_get_user_bpammo(id, CSW_WPN)
		iClip = cs_get_weapon_ammo(wpn)
		
		if(iInReload && flNextAttack <= 0.0)
		{
			new iRemClip = min(WPN_MAXCLIP - iClip, iBpAmmo)
			cs_set_weapon_ammo(wpn, iClip + iRemClip)
			cs_set_user_bpammo(id, CSW_WPN, iBpAmmo-iRemClip)
			iInReload = 0
			set_pdata_int(wpn, m_fInReload, 0, 4)
		}
		static iButton
		iButton = get_user_button(id)

		if((iButton & IN_ATTACK2 && get_pdata_float(wpn, m_flNextSecondaryAttack, 4) <= 0.0) || (iButton & IN_ATTACK && get_pdata_float(wpn, m_flNextPrimaryAttack, 4) <= 0.0))
			return
		
		if(iButton & IN_RELOAD && !iInReload)
		{
			if(iClip >= WPN_MAXCLIP)
			{
				entity_set_int(id, EV_INT_button, iButton & ~IN_RELOAD)
				set_wpnanim(id, 0)
			}
			else if(iClip == WPN_MAXCLIP)
			{
				if(iBpAmmo)
				{
					reload(id, wpn, 1)
				}
			}
		}
	}
}

public fw_Reload_Post(wpn)
{
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)
	
	if(is_user_alive(id) && ma_klase[id] && get_pdata_int(wpn, m_fInReload, 4))
	{		
		reload(id, wpn)
	}
}

public primary_attack(id)
{
	set_wpnanim(id, ANIM_FIRE)
	entity_set_vector(id, EV_VEC_punchangle, Float:{ -1.5, 0.0, 0.0 })
	emit_sound(id, CHAN_WEAPON, snd_fire[random_num(0, sizeof snd_fire - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	static iTarget, iBody, iEndOrigin[3], iStartOrigin[3]
	get_user_origin(id, iStartOrigin, 1) 
	get_user_origin(id, iEndOrigin, 3)
	fire_effects(iStartOrigin, iEndOrigin)
	get_user_aiming(id, iTarget, iBody)
	
	new iEnt = create_entity("info_target")
	
	static Float:flOrigin[3]
	IVecFVec(iEndOrigin, flOrigin)
	entity_set_origin(iEnt, flOrigin)
	remove_entity(iEnt)
	new team = get_user_team(iTarget);
	
	if(is_user_alive(iTarget))
	{	
		if(HITSD > 0.0)
		{
			static Float:flVelocity[3]
			get_user_velocity(iTarget, flVelocity)
			xs_vec_mul_scalar(flVelocity, HITSD, flVelocity)
			set_user_velocity(iTarget, flVelocity)	
		}
		
		if(get_user_team(id) != team)
		{
			new iHp = pev(iTarget, pev_health)
			new Float:iDamage, iBloodScale
			if(iBody != HIT_HEAD)
			{
				iDamage = DAMAGE
				iBloodScale = 10
			}
			else
			{
				iDamage = DAMAGE*DAMAGE_MULTI
				iBloodScale = 25
			}
			if(iHp > iDamage) 
			{
				make_blood(iTarget, iBloodScale)
				set_pev(iTarget, pev_health, iHp-iDamage)
				damage_effects(iTarget)
			}
			else if(iHp <= iDamage)
			{
			ExecuteHamB(Ham_Killed, iTarget, id, 2)
			}
		}
	}
	else
	{
		emit_sound(id, CHAN_WEAPON, snd_hit[random_num(0, sizeof snd_hit - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}
stock fire_effects(iStartOrigin[3], iEndOrigin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(0)    
	write_coord(iStartOrigin[0])
	write_coord(iStartOrigin[1])
	write_coord(iStartOrigin[2])
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2])
	write_short(g_sprBeam)
	write_byte(1) 
	write_byte(5) 
	write_byte(10) 
	write_byte(25) 
	write_byte(0) 
	write_byte(0)     
	write_byte(255)      
	write_byte(0)      
	write_byte(100) 
	write_byte(0) 
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2])
	write_short(g_sprExp)
	write_byte(10)
	write_byte(15)
	write_byte(4)
	message_end()	
}
stock reload(id, wpn, force_reload = 0)
{
	set_pdata_float(id, m_flNextAttack, RELOADSPEED, 5)
	set_wpnanim(id, ANIM_RELOAD)
	emit_sound(id, CHAN_WEAPON, snd_reload[random_num(0, sizeof snd_reload - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(force_reload)
		set_pdata_int(wpn, m_fInReload, 1, 4)
}
stock damage_effects(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
	write_byte(0)
	write_byte(0)
	write_long(DMG_NERVEGAS)
	write_coord(0) 
	write_coord(0)
	write_coord(0)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, {0,0,0}, id)
	write_short(1<<13)
	write_short(1<<14)
	write_short(0x0000)
	write_byte(0)
	write_byte(255)
	write_byte(0)
	write_byte(100) 
	message_end()
		
	message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, id)
	write_short(0xFFFF)
	write_short(1<<13)
	write_short(0xFFFF) 
	message_end()
}
stock make_blood(id, scale)
{
	new Float:iVictimOrigin[3]
	pev(id, pev_origin, iVictimOrigin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(115)
	write_coord(floatround(iVictimOrigin[0]+random_num(-20,20))) 
	write_coord(floatround(iVictimOrigin[1]+random_num(-20,20))) 
	write_coord(floatround(iVictimOrigin[2]+random_num(-20,20))) 
	write_short(g_sprBlood)
	write_short(g_sprBlood) 
	write_byte(248) 
	write_byte(scale) 
	message_end()
}
stock set_wpnanim(id, anim)
{
	entity_set_int(id, EV_INT_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(entity_get_int(id, EV_INT_body))
	message_end()
}
stock make_punch(id, velamount) 
{
	static Float:flNewVelocity[3], Float:flCurrentVelocity[3]
	velocity_by_aim(id, -velamount, flNewVelocity)
	get_user_velocity(id, flCurrentVelocity)
	xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity)
	set_user_velocity(id, flNewVelocity)	
}

public Odrodzenie(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE;
		
	if(ma_klase[id])
	{
		g_has_gaussgun[id] = true
		give_gaussgun(id)
	}

	return PLUGIN_CONTINUE;
}

public plugin_natives ()
{
	register_native("give_weapon_gaussgun", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_gaussgun(id)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/mp5n.sc", name))
	{
		g_orig_event_gaussgun = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_gaussgun[id] = false
}

public client_disconnect(id)
{
	g_has_gaussgun[id] = false
		new ent = find_ent_by_class(0, "bfg10000");
	while(ent > 0)
	{
		if(entity_get_edict(id, EV_ENT_owner) == id)
			remove_entity(ent);
		ent = find_ent_by_class(ent, "bfg10000");
	}


	remove_task(id + TASK_FBURN )
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_mp5.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_m3", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_gaussgun[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, gaussgun_WEAPONKEY)
			
			g_has_gaussgun[iOwner] = false
			
			entity_set_model(entity, gaussgun_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public EV_DeathMsg( )
{
	static pevVictim;
	pevVictim = read_data( 2 )
	
	if( !is_user_connected( pevVictim ) )
		return
		
	remove_task( pevVictim + TASK_FBURN )
}

public PlayerSpawn_Post( Player )
{
	if( !is_user_alive( Player ) )
		return;
		
	g_burning_duration[ Player ] = 0
}

public give_gaussgun(id)
{
	new iWep2 = cod_give_weapon(id, CSW_M3)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_gaussgun))
		cs_set_user_bpammo (id, CSW_M3, get_pcvar_num(cvar_gaussgun_ammo))	
		UTIL_PlayWeaponAnimation(id, gaussgun_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_gaussgun[id] = true
}

public item_selected(id, itemid)
{
	if(itemid != g_itemid_gaussgun)
		return

	give_gaussgun(id)
}

public fw_gaussgun_AddToPlayer(gaussgun, id)
{
	if(!is_valid_ent(gaussgun) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(gaussgun, EV_INT_WEAPONKEY) == gaussgun_WEAPONKEY)
	{
		g_has_gaussgun[id] = true
		
		entity_set_int(gaussgun, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

public CurrentWeapon(id)
{
     replace_weapon_models(id, read_data(2))

     if(read_data(2) != CSW_M3 || !g_has_gaussgun[id])
          return
     
     static Float:iSpeed
     if(g_has_gaussgun[id])
          iSpeed = get_pcvar_float(cvar_spd_gaussgun)
     
     static weapon[32],Ent
     get_weaponname(read_data(2),weapon,31)
     Ent = find_ent_by_owner(-1,weapon,id)
     if(Ent)
     {
          static Float:Delay
          Delay = get_pdata_float( Ent, 46, 4) * iSpeed
          if (Delay > 0.0)
          {
               set_pdata_float(Ent, 46, Delay, 4)
          }
     }
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_M3:
		{
			if(g_has_gaussgun[id])
			{
				set_pev(id, pev_viewmodel2, gaussgun_V_MODEL)
				set_pev(id, pev_weaponmodel2, gaussgun_P_MODEL)
				if(oldweap[id] != CSW_M3) 
				{
					UTIL_PlayWeaponAnimation(id, gaussgun_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_M3 || !g_has_gaussgun[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_gaussgun_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_gaussgun[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_gaussgun) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_gaussgun_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_gaussgun[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_gaussgun),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(gaussgun_SHOOT1, gaussgun_SHOOT2))

		static Float:plrViewAngles[3], Float:VecEnd[3], Float:VecDir[3], Float:PlrOrigin[3]
		pev(Player, pev_v_angle, plrViewAngles)

		static Float:VecSrc[3], Float:VecDst[3]
	
		//VecSrc = pev->origin + pev->view_ofs
		pev(Player, pev_origin, PlrOrigin)
		pev(Player, pev_view_ofs, VecSrc)
		xs_vec_add(VecSrc, PlrOrigin, VecSrc)

		//VecDst = VecDir * 8192.0
		angle_vector(plrViewAngles, ANGLEVECTOR_FORWARD, VecDir);
		xs_vec_mul_scalar(VecDir, 8192.0, VecDst);
		xs_vec_add(VecDst, VecSrc, VecDst);
	
		new hTrace = create_tr2()
		engfunc(EngFunc_TraceLine, VecSrc, VecDst, 0, Player, hTrace)
		get_tr2(hTrace, TR_vecEndPos, VecEnd);

		create_tracer_gauss(Player, VecSrc, VecEnd)	
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(!is_user_alive(attacker))
		return;

	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_M3)
		{
			if(g_has_gaussgun[attacker])
			{
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_gaussgun))

				if( !task_exists( victim + TASK_FBURN ) )
				{
					g_burning_duration[ victim ] += FIRE_DURATION * 5
				
					set_task( 0.2, "CTask__BurningFlame", victim + TASK_FBURN, _, _, "b" )
				}
			}
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "m3") && get_user_weapon(iAttacker) == CSW_M3)
	{
		if(g_has_gaussgun[iAttacker])
			set_msg_arg_string(4, "m3")
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public gaussgun_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_gaussgun[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_gaussgun)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_M3);
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_M3, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public gaussgun_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_gaussgun[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_gaussgun[id])
          iClipExtra = get_pcvar_num(cvar_clip_gaussgun)

     g_gaussgun_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_M3)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_gaussgun_TmpClip[id] = iClip

     return HAM_IGNORED
}

public gaussgun_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_gaussgun[id])
		return HAM_IGNORED

	if (g_gaussgun_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_gaussgun_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, gaussgun_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, gaussgun_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, gaussgun_RELOAD)

	return HAM_IGNORED
}

stock create_tracer_gauss(id, Float:fVec1[3], Float:fVec2[3])
{
	static iVec1[3]
	FVecIVec(fVec1, iVec1)

	static Float:origin[3], Float:vSrc[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3]
	pev(id, pev_v_angle, angles)
	engfunc(EngFunc_MakeVectors, angles)
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_right, v_right)
	global_get(glb_v_up, v_up)

	//m_pPlayer->GetGunPosition( ) = pev->origin + pev->view_ofs
	pev(id, pev_origin, player_origin)
	pev(id, pev_view_ofs, player_view_offset)
	xs_vec_add(player_origin, player_view_offset, gun_position)

	xs_vec_mul_scalar(v_forward, 24.0, v_forward)
	xs_vec_mul_scalar(v_right, 3.0, v_right)

	if ((pev(id, pev_flags) & FL_DUCKING) == FL_DUCKING)
		xs_vec_mul_scalar(v_up, 6.0, v_up)
	else
		xs_vec_mul_scalar(v_up, -2.0, v_up)

	xs_vec_add(gun_position, v_forward, origin)
	xs_vec_add(origin, v_right, origin)
	xs_vec_add(origin, v_up, origin)

	vSrc[0] = origin[0]
	vSrc[1] = origin[1]
	vSrc[2] = origin[2]

	new Float:dist = get_distance_f(vSrc, fVec2)
	new CountDrops = floatround(dist / 50.0)
	
	if (CountDrops > 20)
		CountDrops = 20
	
	if (CountDrops < 2)
		CountDrops = 2

	message_begin(MSG_PAS, SVC_TEMPENTITY, iVec1)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord, vSrc[0])
	engfunc(EngFunc_WriteCoord, vSrc[1])
	engfunc(EngFunc_WriteCoord, vSrc[2])
	engfunc(EngFunc_WriteCoord, fVec2[0])
	engfunc(EngFunc_WriteCoord, fVec2[1])
	engfunc(EngFunc_WriteCoord, fVec2[2])
	write_short(gaussgun_sprite)
	write_byte(CountDrops)
	write_byte(0)
	write_byte(1)
	write_byte(60)
	write_byte(10)
	message_end()

	message_begin(MSG_PAS, SVC_TEMPENTITY, iVec1)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, fVec2[0])
	engfunc(EngFunc_WriteCoord, fVec2[1])
	engfunc(EngFunc_WriteCoord, fVec2[2])
	engfunc(EngFunc_WriteCoord, vSrc[0])
	engfunc(EngFunc_WriteCoord, vSrc[1])
	engfunc(EngFunc_WriteCoord, vSrc[2])
	write_short(gaussgun_sprite)
	write_byte(6)
	write_byte(200) 
	write_byte(1)
	write_byte(100)
	write_byte(0)
	write_byte(64); write_byte(64); write_byte(192);
	write_byte(192)
	write_byte(250) 
	message_end()
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}

public CTask__BurningFlame( taskid )
{
	// Get player origin and flags
	static origin[3], flags
	get_user_origin(ID_FBURN, origin)
	flags = pev(ID_FBURN, pev_flags)
	
	// Madness mode - burning stopped
	if ((flags & FL_INWATER) || g_burning_duration[ID_FBURN] < 1 || g_fRoundEnd || !is_user_alive(ID_FBURN))
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return
	}
	
	// Get player's health
	static health
	health = pev(ID_FBURN, pev_health)
	
	// Take damage from the fire
	if (health - FIRE_DAMAGE > 0)
		fm_set_user_health(ID_FBURN, health - FIRE_DAMAGE)
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()

	
	g_burning_duration[ID_FBURN]--
}