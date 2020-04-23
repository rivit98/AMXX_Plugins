#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include colorchat
#include engine

const m_LinuxDiff = 5;
const XO_CbasePlayerWeapon = 4;

const m_pPlayer = 41;
const m_flNextSecondaryAttack = 47; 
const m_flNextAttack  = 83;
const m_rgpPlayerItems = 269;
const m_fKnown = 44;
const m_iClip = 51;
const m_iClientClip = 52;
const m_iGlockAmmo = 386;

#define TASER_CSGO_DISTANCE_DEFAULT	300
new gBoltSprite;

#define TASER_COST			200 
new model[] = "models/zeus/v_zeus.mdl";
new const gBeamSprite[ ] = "sprites/bolt1.spr";
new const gZeusDrawSound[] = "/zeus/zeus_draw.wav"
new const pmodel[] = "models/zeus/p_zeus.mdl";
new const gZeusHit[ ] = "weapons/electro4.wav";
new const gZeusShoot[ ] = "roach/rch_smash.wav";

new bool:zeus[33];
new bool:bought[33];
new bool:moznakupowac = true;

public plugin_init()
{
	register_plugin("Zeus", "1.0", "RiviT");

	RegisterHam(Ham_Item_Deploy, "weapon_fiveseven", "fwHamItemDeployPost", 1)
	register_clcmd("say /zeus", "buyZeus")
	register_clcmd("say_team /zeus", "buyZeus")
	register_clcmd("ammo_57mm", "blockAmmo")
	register_clcmd( "drop", "block_ZeusDrop" );
	register_forward( FM_CmdStart, "forward_FM_CmdStart" );
	
	register_event("AmmoPickup", "AmmoPickup", "b")
	register_event("DeathMsg", "DeathMsg", "a")
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
}

public plugin_precache()
{
	gBoltSprite = precache_model( gBeamSprite );

	precache_model(model);
	precache_model(pmodel);
	precache_sound(gZeusDrawSound);
	precache_sound(gZeusHit);
	precache_sound(gZeusShoot);
}

public blockAmmo(id)
{
	if(zeus[id]) return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public NewRound()
{
	arrayset(bought, false, 33)
	moznakupowac = true
	remove_task(666)
	set_task(get_cvar_float("mp_buytime")*60, "koniecBuy", 666)
}

public koniecBuy()
	moznakupowac = false;

public forward_FM_CmdStart( id, uc_handle, seed )
{
	if ( get_user_weapon( id) != CSW_FIVESEVEN || !zeus[id] )
		return FMRES_IGNORED;

	new iButtons = get_uc( uc_handle, UC_Buttons );
	new iOldButtons = pev( id, pev_oldbuttons );
	
	new weapon_id = find_ent_by_owner(-1, "weapon_fiveseven", id)
	
	if( iButtons & IN_ATTACK && !( iOldButtons & IN_ATTACK ) && weapon_id && cs_get_weapon_ammo(weapon_id))
	{
		new iOrigin[ 3 ], iTargetOrigin[ 3 ];
		new iTarget, iBody;
		get_user_aiming( id, iTarget, iBody, TASER_CSGO_DISTANCE_DEFAULT );

		if( pev_valid( iTarget ) 
		&& get_user_team( id ) != get_user_team( iTarget ) 
		&& id != iTarget )
		{		
			get_user_origin( id, iOrigin, 0 );
			get_user_origin( iTarget, iTargetOrigin, 0 );

			emit_sound( id, CHAN_WEAPON, gZeusHit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			
			UTIL_CreateThunder( iOrigin, iTargetOrigin );
			ExecuteHam( Ham_TakeDamage, iTarget, 0, id, 200.0, DMG_SHOCK );
			
			cs_set_weapon_ammo(weapon_id, 0)

			return FMRES_IGNORED;
		}

		emit_sound( id, CHAN_WEAPON, gZeusShoot, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		cs_set_weapon_ammo(weapon_id, 0)
		
		iButtons &= ~IN_ATTACK;
		set_uc( uc_handle, UC_Buttons, iButtons );
	}

	
	return FMRES_IGNORED;
}

stock UTIL_CreateThunder( iStart[ 3 ], iEnd[ 3 ] )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
	write_byte( TE_BEAMPOINTS ); 
	write_coord( iStart[ 0 ] ); 
	write_coord( iStart[ 1 ] ); 
	write_coord( iStart[ 2 ] ); 
	write_coord( iEnd[ 0 ] ); 
	write_coord( iEnd[ 1 ] ); 
	write_coord( iEnd[ 2 ] ); 
	write_short( gBoltSprite ); 
	write_byte( 1 );
	write_byte( 5 );
	write_byte( 7 );
	write_byte( 20 );
	write_byte( 30 );
	write_byte( 135 ); 
	write_byte( 206 );
	write_byte( 250 );
	write_byte( 255 );
	write_byte( 145 );
	message_end( );
}

public buyZeus(id)
{
	if(!is_user_alive(id))
	{
		ColorChat(id, GREEN, "[ZEUS]^1 Musisz byc zywy!")
		return PLUGIN_HANDLED;
	}

	if( user_has_weapon( id, CSW_FIVESEVEN ) && zeus[id] )
	{
		new weapon_id = find_ent_by_owner(-1, "weapon_fiveseven", id)
		if(weapon_id && cs_get_weapon_ammo(weapon_id))
		{
			ColorChat(id, GREEN, "[ZEUS]^1 Masz juz kupionego zeusa!")
			return PLUGIN_HANDLED;
		}
	}
	
	if(!cs_get_user_buyzone(id))
	{
		ColorChat(id, GREEN, "[ZEUS]^1 Musisz byc w buyzone!")
		return PLUGIN_HANDLED;
	}
	
	if(!moznakupowac)
	{
		ColorChat(id, GREEN, "[ZEUS]^1 Minal czas kupowania!")
		return PLUGIN_HANDLED;
	}

	if(bought[id])
	{
		ColorChat(id, GREEN, "[ZEUS]^1 Kupiles juz zeusa w tej rundzie!")
		return PLUGIN_HANDLED;
	}

	if(cs_get_user_money(id) < TASER_COST)
	{
		ColorChat(id, GREEN, "[ZEUS]^1 Masz za malo hajsu!")
		return PLUGIN_HANDLED;
	}
	
	zeus[id] = true;
	if(!user_has_weapon( id, CSW_FIVESEVEN ))
		fm_give_item(id, "weapon_fiveseven")

	cs_set_user_money(id, cs_get_user_money(id)-TASER_COST)
	cs_set_user_bpammo(id, CSW_FIVESEVEN, 0)

	new weapon_id = find_ent_by_owner(-1, "weapon_fiveseven", id)
	if(weapon_id)
		cs_set_weapon_ammo(weapon_id, 1)
		
	bought[id] = true;
	ColorChat(id, GREEN, "[ZEUS]^1 Gratulacje. Kupiles zeusa!")

	return PLUGIN_HANDLED
}

public AmmoPickup(id)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	if(read_data(1) == 7 && zeus[id]) return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE;
}

public DeathMsg()
	zeus[read_data(2)] = false;

public client_connect(id)
{
	zeus[id] = false;
	bought[id] = false;
}

public fwHamItemDeployPost(ent)
{
	static id;
	id = get_pdata_cbase(ent, m_pPlayer, 4);
	
	if(!is_user_alive(id) || !zeus[id]) return;
	
	set_pev(id, pev_viewmodel2, model);
	set_pev( id, pev_weaponmodel2, pmodel );
	cs_set_user_bpammo(id, CSW_FIVESEVEN, 0)
	set_pdata_float( ent, m_flNextSecondaryAttack, 999999.9, XO_CbasePlayerWeapon );
	set_pdata_float( id, m_flNextAttack, 9999.0 );
	
	emit_sound( ent, CHAN_WEAPON, gZeusDrawSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}

public block_ZeusDrop( id )
{
	if( get_user_weapon( id) == CSW_FIVESEVEN && zeus[id] )
	{
		client_print( id, print_center, "You cannot drop the Zeus!" );

		return PLUGIN_HANDLED_MAIN;
	}
	
	return PLUGIN_CONTINUE;
}