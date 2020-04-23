/**
 * CBase Offsets for player
 * >> http://wiki.amxmodx.org/CBaseEntity_%28CS%29
 *
 * Entity:
 *
 * |- Delay
 * |-- Animating
 * |--- Toggle
 * |---- Monster
 * |----- Player
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










/**
 * Player offsets
 */

#if !defined _cbase_const_player_included
#define _cbase_const_player_included

//Linux offset difference for this class
#define CBASE_PLAYER_LINUXDIFF 5

#define m_LastHitGroup                   75 	//(int) Hitgroup from last damage taken.
#define m_bitsDamageType                 76 	//(int) Damagebits from last damage taken.
#define m_flNextAttack                   83 	//(float) Gametime of nextattack

#define m_bloodColor                     89 	//(int) Color of blood

#define random_seed                      96 	//(int) See that is shared between client&server for shared weapons code.

#define m_pLastCamera                    122 	//(int) Last switched trigger_camera (cbase).
#define m_flNextCameraView               123 	//(float) fGametime of next trigger_camera view.

#define m_iMenuCode                      205 	//(int) 
#define m_afMissionStatus                209 	//(int) 
	//Mission flags
	#define CBASE_IsTerroristEscaped 	(1<<0)
	#define CBASE_IsVIPRescued 		(1<<0)
	#define CBASE_IsPlayerVIP 		(1<<8)
#define m_bIsPrimaryFireAllowed          219 	//(int) Disallow in prePlayerPostThink
#define m_bIsDefusingState               219 	//(int) 
	//Defusing flag
	#define CBASE_IsDefusing 	(1<<8)

#define m_iPlayerSound                   237 	//(int) The index of the sound list slot reserved for this player.
#define m_iTargetVolume                  238 	//(int) Ideal sound volume.
#define m_iWeaponVolume                  239 	//(int) How loud the player's weapon is right now.
#define m_iExtraSoundTypes               240 	//(int) Additional classification for this weapon's sound.
#define m_iWeaponFlash                   241 	//(int) Brightness of the weapon flash.
#define m_flStopExtraSoundTime           242 	//(float) 

#define m_flFlashLightTime               243 	//(float) Time until next battery draw/Recharge.
#define m_iFlashBattery                  244 	//(int) Flashlight Battery Draw.

#define m_afButtonLast                   245 	//(int) 
#define m_afButtonPressed                246 	//(int) 
#define m_afButtonReleased               247 	//(int) 

#define m_flSndRange                     250 	//(float) Dist from player to sound entity.

#define m_flFallVelocity                 251 	//(float) Player's fall speed.

#define m_rgItemsAntidote                254 	//(int) m_rgItems[item_antidote]
#define m_rgItemsSecurity                255 	//(int) m_rgItems[item_security]

#define m_afPhysicsFlags                 257 	//(unsigned int) Physics flags - set when 'normal' physics should be revisited or overriden.
	//Physics flags
	#define PFLAG_ONLADDER      ( 1<<0 )
	#define PFLAG_ONSWING       ( 1<<0 )
	#define PFLAG_ONTRAIN       ( 1<<1 )
	#define PFLAG_ONBARNACLE    ( 1<<2 )
	#define PFLAG_DUCKING       ( 1<<3 )        // In the process of ducking, but totally squatted yet
	#define PFLAG_USING         ( 1<<4 )        // Using a continuous entity
	#define PFLAG_OBSERVER      ( 1<<5 )        // player is locked in station

#define m_fNextSuicideTime               258 	//(float) The time after which the player can next use the suicide command.
#define m_flTimeStepSound                259 	//(float) When the last stepping sound was made.
#define m_flTimeWeaponIdleCl             260 	//(float) When to play another weapon idle animation.
#define m_flSwimTime                     261 	//(float) How long player has been underwater.
#define m_flDuckTime                     262 	//(float) How long we've been ducking.
#define m_flWallJumpTime                 263 	//(float) How long until next walljump.

#define m_flSuitUpdate                   264 	//(float) When to play next suit update.
#define m_rgSuitPlayList                 265 	//(int[CSUITPLAYLIST]) Next sentencenum to play for suit update.
	//#define CSUITPLAYLIST	4  // max of 4 suit sentences queued up at any time
#define m_iSuitPlayNext                  269 	//(int) Next sentence slot for queue storage.
#define m_rgiSuitNoRepeat                270 	//(int[CSUITNOREPEAT]) Suit sentence no repeat list.
#define m_rgflSuitNoRepeatTime           302 	//(int[CSUITNOREPEAT]) How long to wait before allowing repeat.
	//#define CSUITNOREPEAT  32

#define m_lastDamageAmount               334 	//(int) Last damage taken.
#define m_tbdPrev                        335 	//(float) Time-based damage timer.

#define m_flgeigerRange                  336 	//(float) Range to nearest radiation source.
#define m_flgeigerDelay                  337 	//(float) Delay per update of range msg to client.
#define m_igeigerRangePrev               338 	//(int) 

#define m_iStepLeft                      339 	//(int) Alternate left/right foot stepping sound.

#define m_idrowndmg                      345 	//(int) Track drowning damage taken.
#define m_idrownrestored                 346 	//(int) Track drowning damage restored.

#define m_bitsHUDDamage                  347 	//(int) Damage bits (DMG_*) for the current fame. These get sent to the hud via the Damage message.
#define m_fInitHUD                       348 	//(BOOL) True when deferred HUD restart msg needs to be sent.
#define m_fInitializedHUD                349 	//(BOOL) 

#define m_iTrain                         350 	//(int) Train control position.
#define m_fWeapon                        351 	//(BOOL) Set this to FALSE to force a reset of the current weapon HUD info.
#define m_fDeadTime                      354 	//(float) the time at which the player died  (used in PlayerDeathThink()).
#define m_fNoPlayerSound                 355 	//(BOOL) A debugging feature. Player makes no sound if this is true.
#define m_fLongJump                      356 	//(BOOL) Does this player have the longjump module?
#define m_tSneaking                      357 	//(float) 

#define m_iUpdateTime                    358 	//(int) Stores the number of frame ticks before sending HUD update messages.
#define m_iClientHealth                  359 	//(int) The health currently known by the client.  If this changes, send a new.
#define m_iClientBattery                 360 	//(int) The Battery currently known by the client.  If this changes, send a new.
#define m_iHideHUD                       361 	//(int) The players hud weapon info is to be hidden
#define m_iClientHideHUD                 362 	//(int) 
#define m_iFOV                           363 	//(int) Field of view.
#define m_iClientFOV                     364 	//(int) Client's known FOV.

#define m_rgpPlayerItems                 365 	//(CBasePlayerItem*[MAX_ITEM_TYPES]) (get_pdata_cbase)
	//#define MAX_ITEM_TYPES 4
#define m_pLastPrimaryItem               368 	//(CBasePlayerItem*) (get_pdata_cbase)
#define m_pLastSecondaryItem             369 	//(CBasePlayerItem*) (get_pdata_cbase)
#define m_pLastKnifeItem                 370 	//(CBasePlayerItem*) (get_pdata_cbase)
#define m_pLastGrenadeItem               371 	//(CBasePlayerItem*) (get_pdata_cbase)
#define m_pLastC4Item                    372 	//(CBasePlayerItem*) (get_pdata_cbase)
#define m_pActiveItem                    373 	//(CBasePlayerItem*) (get_pdata_cbase)
#define m_pClientActiveItem              374 	//(CBasePlayerItem*) Client version of the active item. (get_pdata_cbase)
#define m_pLastItem                      375 	//(CBasePlayerItem*) (get_pdata_cbase)
#define m_rgAmmo                         376 	//(int[MAX_AMMO_SLOTS]) Shared ammo slots.
	//#define MAX_AMMO_SLOTS  32  // not really slots
#define m_rgAmmoLast                     408 	//(int[MAX_AMMO_SLOTS]) Shared ammo slots.

#define m_vecAutoAim                     440 	//(Vector) Shared ammo slots.
#define m_fOnTarget                      441 	//(BOOL) Shared ammo slots.

#define m_iDeaths                        442 	//(int) Shared ammo slots.
#define m_iRespawnFrames                 443 	//(float) Used in PlayerDeathThink() to make sure players can always respawn.
#define m_izSBarState                    446 	//(int[SBAR_END]) 
	/**
	 * enum sbar_data
	 * {
	 * 	SBAR_ID_TARGETNAME = 1,
	 * 	SBAR_ID_TARGETHEALTH,
	 * 	SBAR_ID_TARGETARMOR,
	 * 	SBAR_END,
	 * };
	 */
#define m_flNextSBarUpdateTime           449 	//(float) 
#define m_flStatusBarDisappearDelay      450 	//(float) 
#define m_lastx                          483 	//(int) These are the previous update's crosshair angles.
#define m_lasty                          484 	//(int) These are the previous update's crosshair angles.
#define m_nCustomSprayFrames             485 	//(int) Custom clan logo frames for this player.
#define m_flNextDecalTime                486 	//(float) Next time this player can spray a decal.

#define m_szTeamName                     487 	//(char[TEAM_NAME_LENGTH]) 
	//#define TEAM_NAME_LENGTH  16
#define m_szAnimExtention                492 	//(char[32]) 

#define m_iActivityRelated               500 	//(int) kill 0, default 1, walk/duck 3, run 4, longjump 5, jump 6

#define m_bAutoWepSwitch                 509 	//(BOOL) 
#define m_afAdditionalClientInfo         510 	//(int) 
	#define CBASE_VGUI_MENU 	(1<<0)
	#define CBASE_AUTOHELP 		(1<<8)
	#define CBASE_USES_SHIELD 	(1<<16)
	#define CBASE_HAS_SHIELD 	(1<<24)

#define m_flFlashedUntil                 514 	//(float) fGametime flashed until
#define m_flFlashedAt                    515 	//(float) fGametime flashed at
#define m_flHoldTimeInSeconds            516 	//(float) 
#define m_flDurationInSeconds            517 	//(float) 
#define m_iScreenFadeAlpha               518 	//(int) 

#define m_flStartStatusBar               605 	//(float) fGametime of StatusBar 0%
#define m_flEndStatusBar                 606 	//(float) fGametime of StatusBar 100%


#endif