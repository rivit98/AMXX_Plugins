/**
 * CBase Offsets for monster
 * >> http://wiki.amxmodx.org/CBaseEntity_%28CS%29
 *
 * Entity:
 *
 * |- Delay
 * |-- Animating
 * |--- Toggle
 * |---- Monster
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
 * Toggle offsets
 */

#if !defined _cbase_const_toggle_included
#define _cbase_const_toggle_included

//Linux offset difference for this class
#define CBASE_TOGGLE_LINUXDIFF 5

#define m_toggle_state                   41 	//(TOGGLE_STATE) 
#define m_flActivateFinished             42 	//(float) Like attack_finished, but for doors.
#define m_flMoveDistance                 43 	//(float) How far a door should slide or rotate.
#define m_flWait                         44 	//(float) 
#define m_flLip                          45 	//(float) 

#define m_flTWidth                       46 	//(float) For plats.
#define m_flTLength                      47 	//(float) For plats.

#define m_vecPosition1                   48 	//(Vector) 
#define m_vecPosition2                   51 	//(Vector) 
#define m_vecAngle1                      54 	//(Vector) 
#define m_vecAngle2                      57 	//(Vector) 

#define m_cTriggersLeft                  60 	//(int) trigger_counter only, # of activations remaining.

#define m_flHeight                       61 	//(float) 
#define m_hActivator                     62 	//(EHANDLE) 
#define m_pfnCallWhenMoveDone            64 	//(void (CBaseToggle::*)(void)) 

#define m_vecFinalDest                   65 	//(Vector) 
#define m_vecFinalAngle                  68 	//(Vector) 
#define m_bitsDamageInflict              71 	//(int) DMG_ damage type that the door or tigger does.

#define m_sMaster                        72 	//(string_t) Master
//If this button has a master switch, this is the targetname. 
//A master switch must be of the multisource type.
//If all of the switches in the multisource have been triggered, 
//then the button will be allowed to operate. Otherwise, it will be deactivated.


#endif










/**
 * Monster offsets
 */

#if !defined _cbase_const_monster_included
#define _cbase_const_monster_included

//Linux offset difference for this class
#define CBASE_MONSTER_LINUXDIFF 5

#define m_Activity                       73 	//(Activity) What the monster/player is doing (animation). (See activity.h)
#define m_IdealActivity                  74 	//(Activity) Monster/player should switch to this activity. (See activity.h)
#define m_LastHitGroup                   75 	//(int) Hitgroup from last damage taken.
#define m_bitsDamageType                 76 	//(int) Damagebits from last damage taken.
#define m_rgbTimeBasedDamage             77 	//(BYTE[CDMG_TIMEBASED]) 
	#define	itbd_Paralyze		0 
	#define	itbd_NerveGas		1 
	#define	itbd_Poison		2
	#define	itbd_Radiation		3 
	#define	itbd_DrownRecover	4
	#define	itbd_Acid		5
	#define	itbd_SlowBurn		6
	#define	itbd_SlowFreeze		7 
	#define CDMG_TIMEBASED		8

#define m_MonsterState                   79 	//(MONSTERSTATE) Monster's current state.
#define m_IdealMonsterState              80 	//(MONSTERSTATE) Monster should change to this state.

#define m_afConditions                   81 	//(int) 
#define m_afMemory                       82 	//(int) 

#define m_flNextAttack                   83 	//(float) Gametime of nextattack

#define m_hEnemy                         84 	//(EHANDLE) The entity that the monster is fighting.
#define m_hTargetEnt                     86 	//(EHANDLE) The entity that the monster is trying to reach.

#define m_flFieldOfView                  88 	//(float) Width of monster's field of view. ( dot product )
#define m_bloodColor                     89 	//(int) Color of blood
#define m_HackedGunPos                   90 	//(Vector) Hack until we can query end of gun.
#define m_vecEnemyLKP                    93 	//(Vector) Last known position of enemy. (enemy's origin)


#endif