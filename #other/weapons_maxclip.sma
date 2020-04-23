/*	Copyright © 2008, ConnorMcLeod

	Weapons MaxClip is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Weapons MaxClip; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#define VERSION "0.3.0"

enum {
	idle,
	shoot1,
	shoot2,
	insert,
	after_reload,
	start_reload,
	draw
}

enum _:ShotGuns {
	m3,
	xm1014
}

const NOCLIP_WPN_BS	= ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
const SHOTGUNS_BS	= ((1<<CSW_M3)|(1<<CSW_XM1014))
const SILENT_BS	= ((1<<CSW_USP)|(1<<CSW_M4A1))

// weapons offsets
#define XTRA_OFS_WEAPON			4
#define m_pPlayer				41
#define m_iId					43
#define m_fKnown				44
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack	47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload				54
#define m_fInSpecialReload		55
#define m_fSilent				74

// players offsets
#define XTRA_OFS_PLAYER		5
#define m_flNextAttack		83
#define m_rgAmmo_player_Slot0	376

stock const g_iDftMaxClip[CSW_P90+1] = {
	-1,  13, -1, 10,  1,  7,    1, 30, 30,  1,  30, 
		20, 25, 30, 35, 25,   12, 20, 10, 30, 100, 
		8 , 30, 30, 20,  2,    7, 30, 30, -1,  50}

stock const Float:g_fDelay[CSW_P90+1] = {
	0.00, 2.70, 0.00, 2.00, 0.00, 0.55,   0.00, 3.15, 3.30, 0.00, 4.50, 
		 2.70, 3.50, 3.35, 2.45, 3.30,   2.70, 2.20, 2.50, 2.63, 4.70, 
		 0.55, 3.05, 2.12, 3.50, 0.00,   2.20, 3.00, 2.45, 0.00, 3.40
}

stock const g_iReloadAnims[CSW_P90+1] = {
	-1,  5, -1, 3, -1,  6,   -1, 1, 1, -1, 14, 
		4,  2, 3,  1,  1,   13, 7, 4,  1,  3, 
		6, 11, 1,  3, -1,    4, 1, 1, -1,  1}

new g_iMaxClip[CSW_P90+1]

new HamHook:g_iHhPostFrame[CSW_P90+1]
new HamHook:g_iHhAttachToPlayer[CSW_P90+1]
new HamHook:g_iHhWeapon_WeaponIdle[ShotGuns]

public plugin_init()
{
	register_plugin("Weapons MaxClip", VERSION, "ConnorMcLeod")

	register_concmd("weapon_maxclip", "ConsoleCommand_WeaponMaxClip", ADMIN_CFG, " <weapon name> <maxclip>")
}

public ConsoleCommand_WeaponMaxClip(id, lvl, cid)
{
	if( cmd_access(id, lvl, cid, 3) )
	{
		new szWeaponName[17] = "weapon_"
		read_argv(1, szWeaponName[7], charsmax(szWeaponName)-7)
		new iId = get_weaponid(szWeaponName)
		if( iId && ~NOCLIP_WPN_BS & 1<<iId )
		{
			new szMaxClip[4]
			read_argv(2, szMaxClip, charsmax(szMaxClip))
			new iMaxClip = str_to_num(szMaxClip)
			new bool:bIsShotGun = !!( SHOTGUNS_BS & (1<<iId) )
			if( iMaxClip && iMaxClip != g_iDftMaxClip[iId] )
			{
				g_iMaxClip[iId] = iMaxClip
				if( g_iHhPostFrame[iId] )
				{
					EnableHamForward( g_iHhPostFrame[iId] )
				}
				else
				{
					g_iHhPostFrame[iId] = RegisterHam(Ham_Item_PostFrame, szWeaponName, bIsShotGun ? "Shotgun_PostFrame" : "Item_PostFrame")
				}
				if( g_iHhAttachToPlayer[iId] )
				{
					EnableHamForward( g_iHhAttachToPlayer[iId] )
				}
				else
				{
					g_iHhAttachToPlayer[iId] = RegisterHam(Ham_Item_AttachToPlayer, szWeaponName, "Item_AttachToPlayer")
				}
				if( bIsShotGun )
				{
					new iShotGunType = iId == CSW_M3 ? m3 : xm1014
					if( g_iHhWeapon_WeaponIdle[iShotGunType] )
					{
						EnableHamForward( g_iHhWeapon_WeaponIdle[iShotGunType] )
					}
					else
					{
						g_iHhWeapon_WeaponIdle[iShotGunType] = RegisterHam(Ham_Weapon_WeaponIdle, szWeaponName, "Shotgun_WeaponIdle")
					}
				}
			}
			else
			{
				g_iMaxClip[iId] = 0
				if( g_iHhPostFrame[iId] )
				{
					DisableHamForward( g_iHhPostFrame[iId] )
				}
				if( g_iHhAttachToPlayer[iId] )
				{
					DisableHamForward( g_iHhAttachToPlayer[iId] )
				}
				if( bIsShotGun )
				{
					new iShotGunType = iId == CSW_M3 ? m3 : xm1014
					if( g_iHhWeapon_WeaponIdle[iShotGunType] )
					{
						DisableHamForward( g_iHhWeapon_WeaponIdle[iShotGunType] )
					}
				}
			}
		}
	}
	return PLUGIN_HANDLED
}

public Item_AttachToPlayer(iEnt, id)
{
	if(get_pdata_int(iEnt, m_fKnown, XTRA_OFS_WEAPON))
	{
		return
	}
	
	set_pdata_int(iEnt, m_iClip, g_iMaxClip[ get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON) ], XTRA_OFS_WEAPON)
}

public Item_PostFrame(iEnt)
{
	static iId ; iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)
	static iMaxClip ; iMaxClip = g_iMaxClip[iId]
	static fInReload ; fInReload = get_pdata_int(iEnt, m_fInReload, XTRA_OFS_WEAPON)
	static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
	static Float:flNextAttack ; flNextAttack = get_pdata_float(id, m_flNextAttack, XTRA_OFS_PLAYER)

	static iAmmoType ; iAmmoType = m_rgAmmo_player_Slot0 + get_pdata_int(iEnt, m_iPrimaryAmmoType, XTRA_OFS_WEAPON)
	static iBpAmmo ; iBpAmmo = get_pdata_int(id, iAmmoType, XTRA_OFS_PLAYER)
	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(iMaxClip - iClip, iBpAmmo)
		set_pdata_int(iEnt, m_iClip, iClip + j, XTRA_OFS_WEAPON)
		set_pdata_int(id, iAmmoType, iBpAmmo-j, XTRA_OFS_PLAYER)
		
		set_pdata_int(iEnt, m_fInReload, 0, XTRA_OFS_WEAPON)
		fInReload = 0
	}

	static iButton ; iButton = pev(id, pev_button)
	if(	(iButton & IN_ATTACK2 && get_pdata_float(iEnt, m_flNextSecondaryAttack, XTRA_OFS_WEAPON) <= 0.0)
	||	(iButton & IN_ATTACK && get_pdata_float(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) <= 0.0)	)
	{
		return
	}

	if( iButton & IN_RELOAD && !fInReload )
	{
		if( iClip >= iMaxClip )
		{
			set_pev(id, pev_button, iButton & ~IN_RELOAD)
			if( SILENT_BS & (1<<iId) && !get_pdata_int(iEnt, m_fSilent, XTRA_OFS_WEAPON) )
			{
				SendWeaponAnim( id, iId == CSW_USP ? 8 : 7 )
			}
			else
			{
				SendWeaponAnim(id, 0)
			}
		}
		else if( iClip == g_iDftMaxClip[iId] )
		{
			if( iBpAmmo )
			{
				set_pdata_float(id, m_flNextAttack, g_fDelay[iId], XTRA_OFS_PLAYER)

				if( SILENT_BS & (1<<iId) && get_pdata_int(iEnt, m_fSilent, XTRA_OFS_WEAPON) )
				{
					SendWeaponAnim( id, iId == CSW_USP ? 5 : 4 )
				}
				else
				{
					SendWeaponAnim(id, g_iReloadAnims[iId])
				}
				set_pdata_int(iEnt, m_fInReload, 1, XTRA_OFS_WEAPON)

				set_pdata_float(iEnt, m_flTimeWeaponIdle, g_fDelay[iId] + 0.5, XTRA_OFS_WEAPON)
			}
		}
	}
}

SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id,pev_body))
	message_end()
}

public Shotgun_WeaponIdle( iEnt )
{
	if( get_pdata_float(iEnt, m_flTimeWeaponIdle, XTRA_OFS_WEAPON) > 0.0 )
	{
		return
	}

	static iId ; iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)
	static iMaxClip ; iMaxClip = g_iMaxClip[iId]

	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)
	static fInSpecialReload ; fInSpecialReload = get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON)

	if( !iClip && !fInSpecialReload )
	{
		return
	}

	if( fInSpecialReload )
	{
		static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
		static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, XTRA_OFS_PLAYER)
		static iDftMaxClip ; iDftMaxClip = g_iDftMaxClip[iId]

		if( iClip < iMaxClip && iClip == iDftMaxClip && iBpAmmo )
		{
			Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
			return
		}
		else if( iClip == iMaxClip && iClip != iDftMaxClip )
		{
			SendWeaponAnim( id, after_reload )

			set_pdata_int(iEnt, m_fInSpecialReload, 0, XTRA_OFS_WEAPON)
			set_pdata_float(iEnt, m_flTimeWeaponIdle, 1.5, XTRA_OFS_WEAPON)
		}
	}
	return
}

public Shotgun_PostFrame( iEnt )
{
	static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)	

	static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, XTRA_OFS_PLAYER)
	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)
	static iId ; iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)
	static iMaxClip ; iMaxClip = g_iMaxClip[iId]

	// Support for instant reload (used for example in my plugin "Reloaded Weapons On New Round")
	// It's possible in default cs
	if( get_pdata_int(iEnt, m_fInReload, XTRA_OFS_WEAPON) && get_pdata_float(id, m_flNextAttack, 5) <= 0.0 )
	{
		new j = min(iMaxClip - iClip, iBpAmmo)
		set_pdata_int(iEnt, m_iClip, iClip + j, XTRA_OFS_WEAPON)
		set_pdata_int(id, 381, iBpAmmo-j, XTRA_OFS_PLAYER)
		
		set_pdata_int(iEnt, m_fInReload, 0, XTRA_OFS_WEAPON)
		return
	}

	static iButton ; iButton = pev(id, pev_button)
	if( iButton & IN_ATTACK && get_pdata_float(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) <= 0.0 )
	{
		return
	}

	if( iButton & IN_RELOAD  )
	{
		if( iClip >= iMaxClip )
		{
			set_pev(id, pev_button, iButton & ~IN_RELOAD) // still this fucking animation
			set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.5, XTRA_OFS_WEAPON)  // Tip ?
		}

		else if( iClip == g_iDftMaxClip[iId] )
		{
			if( iBpAmmo )
			{
				Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
			}
		}
	}
}

Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
{
	if(iBpAmmo <= 0 || iClip == iMaxClip)
		return

	if(get_pdata_int(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) > 0.0)
		return

	switch( get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON) )
	{
		case 0:
		{
			SendWeaponAnim( id , start_reload )
			set_pdata_int(iEnt, m_fInSpecialReload, 1, XTRA_OFS_WEAPON)
			set_pdata_float(id, m_flNextAttack, 0.55, 5)
			set_pdata_float(iEnt, m_flTimeWeaponIdle, 0.55, XTRA_OFS_WEAPON)
			set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.55, XTRA_OFS_WEAPON)
			set_pdata_float(iEnt, m_flNextSecondaryAttack, 0.55, XTRA_OFS_WEAPON)
			return
		}
		case 1:
		{
			if( get_pdata_float(iEnt, m_flTimeWeaponIdle, XTRA_OFS_WEAPON) > 0.0 )
			{
				return
			}
			set_pdata_int(iEnt, m_fInSpecialReload, 2, XTRA_OFS_WEAPON)
			emit_sound(id, CHAN_ITEM, random_num(0,1) ? "weapons/reload1.wav" : "weapons/reload3.wav", 1.0, ATTN_NORM, 0, 85 + random_num(0,0x1f))
			SendWeaponAnim( id, insert )

			set_pdata_float(iEnt, m_flTimeWeaponIdle, iId == CSW_XM1014 ? 0.30 : 0.45, XTRA_OFS_WEAPON)
		}
		default:
		{
			set_pdata_int(iEnt, m_iClip, iClip + 1, XTRA_OFS_WEAPON)
			set_pdata_int(id, 381, iBpAmmo-1, XTRA_OFS_PLAYER)
			set_pdata_int(iEnt, m_fInSpecialReload, 1, XTRA_OFS_WEAPON)
		}
	}
}