/**
 * CBase Offsets for weapon/c4
 * >> http://wiki.amxmodx.org/CBaseEntity_%28CS%29
 *
 * Entity:
 *
 * |- Delay
 * |-- Animating
 * |--- PlayerItem
 * |---- PlayerWeapon
 * |----- C4
 */



/**
 * Delay offsets
 */

#if !defined _cbase_const_delay_included
#define _cbase_const_delay_included

//Linux offset difference for this class
#define CBASE_DELAY_LINUXDIFF 5

#define m_flDelay                        34 	//(float) 
#define m_iszKillTarget                  35 	//(int) 


#endif










/**
 * Animating offsets
 */

#if !defined _cbase_const_animating_included
#define _cbase_const_animating_included

//Linux offset difference for this class
#define CBASE_ANIMATING_LINUXDIFF 5

#define m_flFrameRate                    36 	//(float) Computed FPS for current sequence.
#define m_flGroundSpeed                  37 	//(float) Computed linear movement rate for current sequence.
#define m_flLastEventCheck               38 	//(float) Last time the event list was checked.
#define m_fSequenceFinished              39 	//(BOOL) Flag set when StudioAdvanceFrame moves across a frame boundry.
#define m_fSequenceLoops                 40 	//(BOOL) True if the sequence loops.


#endif










/**
 * PlayerItem offsets
 */

#if !defined _cbase_const_pitem_included
#define _cbase_const_pitem_included

//Linux offset difference for this class
#define CBASE_PLAYERITEM_LINUXDIFF 4

#define m_pPlayer                        41 	//(CBasePlayer*) ( get_pdata_cbase() )
#define m_pNext                          42 	//(CBasePlayerItem*) ( get_pdata_cbase() )
#define m_iId                            43 	//(int) CSW_*


#endif










/**
 * PlayerWeapon offsets
 */

#if !defined _cbase_const_pweapon_included
#define _cbase_const_pweapon_included

//Linux offset difference for this class
#define CBASE_PLAYERWEAPON_LINUXDIFF 4

#define m_iPlayEmptySound                44 	//(int) 
#define m_fFireOnEmpty                   45 	//(int) 

#define m_flNextPrimaryAttack            46 	//(float) Soonest time ItemPostFrame will call PrimaryAttack.
#define m_flNextSecondaryAttack          47 	//(float) Soonest time ItemPostFrame will call SecondaryAttack.
#define m_flTimeWeaponIdle               48 	//(float) Soonest time ItemPostFrame will call WeaponIdle.

#define m_iPrimaryAmmoType               49 	//(int) "primary" ammo index into players m_rgAmmo[].
#define m_iSecondaryAmmoType             50 	//(int) "secondary" ammo index into players m_rgAmmo[].
#define m_iClip                          51 	//(int) Number of shots left in the primary weapon clip, -1 it not used.
#define m_iClientClip                    52 	//(int) The last version of m_iClip sent to hud dll.
#define m_iClientWeaponState             53 	//(int) The last version of the weapon state sent to hud dll. (is current weapon, is on target).

#define m_fInReload                      54 	//(int) Are we in the middle of a reload ?
#define m_fInSpecialReload               55 	//(int) Are we in the middle of a reload for the shotguns.

#define m_iDefaultAmmo                   56 	//(int) How much ammo you get when you pick up this weapon as placed by a level designer.
#define m_iShell                         57 	//(int) Shell model index of awp, g3sg1, glock18, m3, scout, sg550, xm1014.

#define m_bDelayFire                     59 	//(BOOL) 
#define m_flAccuracy                     62 	//(float) 
#define m_iShotsFired                    64 	//(int) 
#define m_iViewModel                     68 	//(int) 
#define m_bSilencerOn                    74 	//(int) 
#define m_flDecreaseShotsFired           76 	//(float) 
#define m_iGunShell                      78 	//(int) Shell model index, gun only.
#define m_flPumpTime                     79 	//(float) 


#endif










/**
 * C4 offsets
 */

#if !defined _cbase_const_c4_included
#define _cbase_const_c4_included

//Linux offset difference for this class
#define CBASE_C4_LINUXDIFF 4

#define m_bStartedArming                 78 	//(BOOL) The bomb is currently in arming state.
#define m_bBombPlacedAnimation           79 	//(BOOL) Whether or not the bomb has places. It's used to control viewmodel animation.
#define m_fArmedTime                     80 	//(float) Time left to get c4 armed.


#endif