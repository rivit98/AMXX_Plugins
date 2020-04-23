// vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

//
// Ham Sandwich Constants
//

#if defined _ham_const_included
	#endinput
#endif
#define _ham_const_included

/**
 * Ham return types.
 *
 * @note Return these from hooks to disable calling the target function.
 *       Numbers match up with fakemeta's FMRES_* for clarity. They are
 *       interchangable. 0 (or no return) is also interpretted as HAM_IGNORED.
 */
#define HAM_IGNORED		1	/**< Calls target function, returns normal value */
#define HAM_HANDLED		2	/**< Tells the module you did something, still calls target function and returns normal value */
#define HAM_OVERRIDE	3	/**< Still calls the target function, but returns whatever is set with SetHamReturn*() */
#define HAM_SUPERCEDE	4	/**< Block the target call, and use your return value (if applicable) (Set with SetHamReturn*()) */

/**
 * List of virtual functions made available through the hamsandwich module.
 *
 * @note Not all functions will do as you expect on all mods. If a function does
 *       not do what you would believe it should DO NOT file a bug report, you
 *       will be ignored.
 * @note Passing invalid parameters has potential to crash the server, so be
 *       careful, and test carefully and adequately!
 * @note All functions take (and pass) a "this" index as the first param.
 *       This is the entity from which the function is being executed on.
 * @note All functions and forwards (eg: {Register,Execute}Ham[B]) require
 *       the mod to have the pev and base keys in addition to the function
 *       keys for the corresponding mod/operating system in hamdata.ini
 * @note Some functions that return booleans may need to be logically ANDed
 *       to get the desired results because the mod will return the full integer
 *       value. E.g.: (ExecuteHam(Ham_TS_IsObjective, this) & 0x0000FFFF) != 0
 */

enum Ham
{
	/**
	 * Description:		This is typically called whenever an entity is created.
	 *					It is the virtual equivilent of spawn from the engine.
	 *					Some mods call this on player spawns too.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Spawn, this);
	 */
	Ham_Spawn = 0,

	/**
	 * Description:		This is typically called on map change.
	 *					This will typically precache all assets required by the entity.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Precache, this);
	 */
	Ham_Precache,

	/**
	 * Description:		Typically this is similar to an engine keyvalue call.
	 *					Use the kvd natives from fakemeta to handle the kvd_handle passed.
	 *					NOTE: Do not pass handle 0 to this! Use create_kvd() from fakemeta instead!
	 * Forward params:	function(this, kvd_handle);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Keyvalue, this, kvd_handle);
	 */
	Ham_Keyvalue,

	/**
	 * Description:		Returns flags for how an entity can be used.
	 * Forward params:	function(this)
	 * Return type:		Integer (FCAP_* constants, see hlsdk_const.inc).
	 * Execute params:	ExecuteHam(Ham_ObjectCaps, this);
	 */
	Ham_ObjectCaps,

	/**
	 * Description:		Usually called to activate some objects.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Activate, this);
	 */
	Ham_Activate,

	/**
	 * Description:		Usually called after the engine call with the same name.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_SetObjectCollisionBox, this);
	 */
	Ham_SetObjectCollisionBox,

	/**
	 * Description:		Returns an integer number that corresponds with what type of entity this is.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_Classify, this);
	 */
	Ham_Classify,

	/**
	 * Description:		Typically called when an entity dies to notify any children entities about the death.
	 * Forward params:	function(this, idchild)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_DeathNotice, this, idchild)
	 */
	Ham_DeathNotice,

	/**
	 * Description:		Usually called whenever an entity gets attacked by a hitscan (such as a gun) weapon.
	 *					Use the get/set tr2 natives in fakemeta to handle the traceresult data.
	 *					Do not use a handle of 0 as a traceresult in execution, use create_tr2() from Fakemeta
	 *					to pass a custom handle instead.  (Don't forget to free the handle when you're done.)
	 * Forward params:	function(this, idattacker, Float:damage, Float:direction[3], traceresult, damagebits)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_TraceAttack, this, idattacker, Float:damage, Float:direction[3], tracehandle, damagebits);
	 */
	Ham_TraceAttack,

	/**
	 * Description:		Usually called whenever an entity takes any kind of damage.
	 *					Inflictor is the entity that caused the damage (such as a gun).
	 *					Attacker is the entity that tirggered the damage (such as the gun's owner).
	 * Forward params:	function(this, idinflictor, idattacker, Float:damage, damagebits);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_TakeDamage, this, idinflictor, idattacker, Float:damage, damagebits);
	 */
	Ham_TakeDamage,

	/**
	 * Description:		Usually called whenever an entity gets a form of a heal.
	 * Forward params:	function(this, Float:health, damagebits);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_TakeHealth, this, Float:health, damagebits);
	 */
	Ham_TakeHealth,

	/**
	 * Description:		Normally called whenever an entity dies.
	 *					For Team Fortress Classic mod, see Ham_TFC_Killed.
	 * Forward params:	function(this, idattacker, shouldgib)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Killed, this, idattacker, shouldgib);
	 */
	Ham_Killed,

	/**
	 * Description:		Normally returns the blood color of the entity.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_BloodColor, this)
	 */
	Ham_BloodColor,

	/**
	 * Description:		Traces where blood should appear.
	 * Forward params:	function(this, Float:Damage, Float:Direction[3], trace_handle, damagebits);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_TraceBleed, this, Float:damage, Float:direction[3], trace_handle, damagebits);
	 */
	Ham_TraceBleed,

	/**
	 * Description:		Returns whether an entity is activated.
	 *					This function is not supported by Day Of Defeat.
	 *					This function has different version for Team Fortress Classic, see Ham_TFC_IsTriggered instead.
	 * Forward params:	function(this, idActivator);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_IsTriggered, this, idActivator);
	 */
	Ham_IsTriggered,

	/**
	 * Description:		Returns the id of the entity if its class is derived off of CBaseMonster, -1 otherwise.
	 * Forward params:	function(this)
	 * Return type:		Entity.
	 * Execute params:	ExecuteHam(Ham_MyMonsterPointer, this);
	 */
	Ham_MyMonsterPointer,

	/**
	 * Description:		Returns the id of the entity if its class is derived off of CBaseSquadMonster, -1 otherwise.
	 * Forward params:	function(this)
	 * Return type:		Entity.
	 * Execute params:	ExecuteHam(Ham_MySquadMonsterPointer, this);
	 */
	Ham_MySquadMonsterPointer,

	/**
	 * Description:		Returns the toggle state of the entity.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_GetToggleState, this);
	 */
	Ham_GetToggleState,

	/**
	 * Description:		Typically adds points to the entity.
	 *					This function is not supported by Team Fortress Classic mod.
	 * Forward params:	function(this, points, bool:cangonegative);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_AddPoints, this, points, bool:cangonegative);
	 */
	Ham_AddPoints,

	/**
	 * Description:		Typically adds points to everybody on the entity's team.
	 *					This function is not supported by Team Fortress Classic mod.
	 * Forward params:	function(this, points, bool:cangonegative);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_AddPointsToTeam, this, points, bool:cangonegative);
	 */
	Ham_AddPointsToTeam,

	/**
	 * Description:		Adds an item to the player's inventory.
	 * Forward params:	function(this, idother);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_AddPlayerItem, this, idother);
	 */
	Ham_AddPlayerItem,

	/**
	 * Description:		Removes an item to the player's inventory.
	 * Forward params:	function(this, idother);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_RemovePlayerItem, this, idother);
	 */
	Ham_RemovePlayerItem,

	/**
	 * Description:		Gives ammo to the entity.
	 *					This function is not supported for the following mods:
	 *						Earth's Special Forces.
	 *						Sven-Coop 4.8+, see Ham_SC_GiveAmmo instead.
	 *						Team Fortress Classic, see Ham_TFC_GiveAmmo instead.
	 * Forward params:	function(this, Amount, const Name[], Max)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_GiveAmmo, this, amount, "type", max);
	 */
	Ham_GiveAmmo,

	/**
	 * Description:		Unsure, I believe this is the delay between activation for an entity.
	 * Forward params:	function(this)
	 * Return type:		Float.
	 * Execute params:	ExecuteHam(Ham_GetDelay, this, Float:output)
	 */
	Ham_GetDelay,

	/**
	 * Description:		Whether or not the entity is moving.
	 * Forward params:	function(this);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_IsMoving, this);
	 */
	Ham_IsMoving,

	/**
	 * Description:		Unsure.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_OverrideReset, this)
	 */
	Ham_OverrideReset,

	/**
	 * Description:		Returns the damage decal of the entity for the damage type.
	 * Forward params:	function(this, damagebits)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_DamageDecal, this);
	 */
	Ham_DamageDecal,

	/**
	 * Description:		Sets the toggle state of the entity.
	 * Forward params:	function(this, state)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_SetToggleState, this, state);
	 */
	Ham_SetToggleState,

	/**
	 * Description:		Not entirely sure what this does.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_StartSneaking, this);
	 */
	Ham_StartSneaking,

	/**
	 * Description:		Not entirely sure what this does.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_StopSneaking, this);
	 */
	Ham_StopSneaking,

	/**
	 * Description:		Not entirely sure.
	 * Forward params:	function(this, idOn)
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_OnControls, this, idOn);
	 */
	Ham_OnControls,

	/**
	 * Description:		Whether or not the entity is sneaking.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_IsSneaking, this);
	 */
	Ham_IsSneaking,

	/**
	 * Description:		Whether or not the entity is alive.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_IsAlive, this);
	 */
	Ham_IsAlive,

	/**
	 * Description:		Whether or not the entity uses a BSP model.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_IsBSPModel, this);
	 */
	Ham_IsBSPModel,

	/**
	 * Description:		Whether or not the entity can reflect gauss shots..
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_ReflectGauss, this);
	 */
	Ham_ReflectGauss,

	/**
	 * Description:		Whether or not the target is the same as the one passed.
	 *					Note the strindex parameter is a string passed that has been allocated by the engine.
	 *					Use fakemeta's EngFunc_SzFromIndex to convert to a normal string, or fakemeta's
	 *					EngFunc_AllocString to create a new string.
	 * Forward params:	function(this, strindex).
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_HasTarget, this, strindex);
	 */
	Ham_HasTarget,

	/**
	 * Description:		Whether or not the entity is in the world.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_IsInWorld, this);
	 */
	Ham_IsInWorld,

	/**
	 * Description:		Whether or not the entity is a player.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_IsPlayer, this);
	 */
	Ham_IsPlayer,

	/**
	 * Description:		Whether or not the entity is a net client.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_IsNetClient, this);
	 */
	Ham_IsNetClient,

	/**
	 * Description:		Get the entity's team id.
	 *					This function is not supported by Team Fortress Classic mod.
	 * Forward params:	function(this);
	 * Return type:		String (string length returned and string byref'd in ExecuteHam).
	 * Execute params:	ExecuteHam(Ham_TeamId, this, buffer[], size);
	 */
	Ham_TeamId,

	/**
	 * Description:		Returns the next target of this.
	 * Forward params:	function(this);
	 * Return type:		Entity.
	 * Execute params:	ExecuteHam(Ham_GetNextTarget, this);
	 */
	Ham_GetNextTarget,

	/**
	 * Description:		Called whenever an entity thinks.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Think, this);
	 */
	Ham_Think,

	/**
	 * Description:		Called whenever two entities touch.
	 * Forward params:	function(this, idother);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Touch, this, idother);
	 */
	Ham_Touch,

	/**
	 * Description:		Called whenver one entity uses another.
	 * Forward params:	function(this, idcaller, idactivator, use_type, Float:value)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Use, this, idcaller, idactivator, use_type, Float:value);
	 */
	Ham_Use,

	/**
	 * Description:		Normally called whenever one entity blocks another from moving.
	 * Forward params:	function(this, idother);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Blocked, this, idother);
	 */
	Ham_Blocked,

	/**
	 * Description:		Normally called when a map-based item respawns, such as a health kit or something.
	 * Forward params:	function(this);
	 * Return type:		Entity.
	 * Execute params:	ExecuteHam(Ham_Respawn, this);
	 */
	Ham_Respawn,

	/**
	 * Description:		Used in Half-Life to update a monster's owner.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_UpdateOwner, this);
	 */
	Ham_UpdateOwner,

	/**
	 * Description:		Normally called whenever a barnacle grabs the entity.
	 * Forward params:	function(this);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_FBecomeProne, this);
	 */
	Ham_FBecomeProne,

	/**
	 * Description:		Returns the center of the entity.
	 * Forward params:	function(this);
	 * Return type:		Vector (byref'd in ExecuteHam).
	 * Execute params:	ExecuteHam(Ham_Center, this, Float:output[3]);
	 */
	Ham_Center,

	/**
	 * Description:		Returns the eye position of the entity.
	 * Forward params:	function(this);
	 * Return type:		Vector (byref'd in ExecuteHam).
	 * Execute params:	ExecuteHam(Ham_EyePosition, this, Float:output[3]);
	 */
	Ham_EyePosition,

	/**
	 * Description:		Returns the ear position of the entity.
	 * Forward params:	function(this);
	 * Return type:		Vector (byref'd in ExecuteHam).
	 * Execute params:	ExecuteHam(Ham_EarPosition, this, Float:output[3]);
	 */
	Ham_EarPosition,

	/**
	 * Description:		Position to shoot at.
	 * Forward params:	function(this, Float:srcvector[3]);
	 * Return type:		Vector (byref'd in ExecuteHam).
	 * Execute params:	ExecuteHam(Ham_BodyTarget, Float:srcvector[3], Float:returnvector[3])
	 */
	Ham_BodyTarget,

	/**
	 * Description:		Returns the illumination of the entity.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_Illumination, this);
	 */
	Ham_Illumination,

	/**
	 * Description:		Returns true if a line can be traced from the caller's eyes to the target.
	 * Forward params:	function(this, idOther);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_FVisible, this, idOther);
	 */
	Ham_FVisible,

	/**
	 * Description:		Returns true if a line can be traced from the caller's eyes to given vector.
	 * Forward params:	function(this, const Float:origin[3]);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_FVecVisible, this, const Float:origin[3]);
	 */
	Ham_FVecVisible,


	/**
	 * Players have all the attributes of normal entities, in addition to these.
	 */

	/**
	 * Description:		Typically called every frame when a player has jump held.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Player_Jump, this);
	 */
	Ham_Player_Jump,

	/**
	 * Description:		Typically called every frame when a player has duck held.
	 *					This function is not supported in Earth's Special Forces mod.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Player_Duck, this);
	 */
	Ham_Player_Duck,

	/**
	 * Description:		Typically called every frame during PlayerPreThink engine call.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Player_PreThink, this);
	 */
	Ham_Player_PreThink,

	/**
	 * Description:		Typically called every frame during PlayerPostThink engine call.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Player_PostThink, this);
	 */
	Ham_Player_PostThink,

	/**
	 * Description:		Returns a vector that tells the gun position.
	 *					This function is not supported by Team Fortress Classic.
	 * Forward params:	function(this)
	 * Return type:		Vector (byreffed in ExecuteHam);.
	 * Execute params:	ExecuteHam(Ham_Player_GetGunPosition, this, Float:output[3]);
	 */
	Ham_Player_GetGunPosition,

	/**
	 * Description:		Whether or not the player should fade on death.
	 * Forward param:	function(this)
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Player_ShouldFadeOnDeath, this);
	 */
	Ham_Player_ShouldFadeOnDeath,

	/**
	 * Description:		Called whenever an impulse command is executed.
	 * Forward param:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Player_ImpulseComands, this);
	 */
	Ham_Player_ImpulseCommands,

	/**
	 * Description:		Updates the client's data for hud changes (such as ammo).  Usually called every frame.
	 *					This function is not supported by Team Fortress Classic mod.
	 * Forward param:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Player_UpdateClientData, this);
	 */
	Ham_Player_UpdateClientData,


	/**
	 * Items have all the attributes of normal entities in addition to these.
	 */

	/**
	 * Description:		Adds the item to the player.
	 * Forward params:	function(this, idPlayer);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Item_AddToPlayer, this, idPlayer);
	 */
	Ham_Item_AddToPlayer,

	/**
	 * Description:		Unsure.
	 * Forward params:	function(this, idOriginal);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Item_AddDuplicate, this, idOriginal);
	 */
	Ham_Item_AddDuplicate,

	/**
	 * Description:		Whether or not this entity can be deployed.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Item_CanDeploy, this);
	 */
	Ham_Item_CanDeploy,

	/**
	 * Description:		Deploys the entity (usually a weapon).
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Item_Deploy, this);
	 */
	Ham_Item_Deploy,

	/**
	 * Description:		Whether or not the entity can be holstered.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Item_CanHolster, this);
	 */
	Ham_Item_CanHolster,

	/**
	 * Description:		Whether or not the entity (usually weapon) can be holstered.
	 * Forward params:	function(this)
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Item_Holster, this);
	 */
	Ham_Item_Holster,

	/**
	 * Description:		Updates the HUD info about this item.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_UpdateItemInfo, this);
	 */
	Ham_Item_UpdateItemInfo,

	/**
	 * Description:		Called each frame for an item, normally only on active items.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Item_PreFrame, this);
	 */
	Ham_Item_PreFrame,

	/**
	 * Description:		Called each frame for an item, normally only on active items.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Item_PostFrame, this);
	 */
	Ham_Item_PostFrame,

	/**
	 * Description:		Called when an item gets dropped, normally on death only.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Item_Drop, this);
	 */
	Ham_Item_Drop,

	/**
	 * Description:		Normally called when an item gets deleted.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Item_Kill, this);
	 */
	Ham_Item_Kill,

	/**
	 * Description:		Called when an entity starts being attached to (normally invisible and "following") a player.
	 * Forward params:	function(this, idPlayer)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Item_AttachToPlayer, this, idPlayer)
	 */
	Ham_Item_AttachToPlayer,

	/**
	 * Description:		Returns the ammo index of the item.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_Item_PrimaryAmmoIndex, this);
	 */
	Ham_Item_PrimaryAmmoIndex,

	/**
	 * Description:		Returns the secondary ammo index of the item.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_Item_SecondaryAmmoIndex, this);
	 */
	Ham_Item_SecondaryAmmoIndex,

	/**
	 * Description:		Updates item data for the client.
	 * Forward params:	function(this, idPlayer)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_Item_UpdateClientData, this, idPlayer);
	 */
	Ham_Item_UpdateClientData,

	/**
	 * Description:		Returns the entity index if the item is a weapon, -1 otherwise.
	 * Forward params:	function(this)
	 * Return type:		Entity.
	 * Execute Params:	ExecuteHam(Ham_Item_GetWeaponPtr, this)
	 */
	Ham_Item_GetWeaponPtr,

	/**
	 * Description:		Returns the item slot for the item.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute Params:	ExecuteHam(Ham_Item_ItemSlot, this)
	 */
	Ham_Item_ItemSlot,


	/**
	 * Weapons have all the attributes to Ham_Item_*, in addition to these.
	 */

	/**
	 * Description:		Gets ammo from the target weapon.
	 *					This function is not supported in Earth's Special Forces mod.
	 * Forward params:	function(this, idTarget)
	 * Return type:		Integer.
	 * Execute Params:	ExecuteHam(Ham_Weapon_ExtractAmmo, this, idTarget)
	 */
	Ham_Weapon_ExtractAmmo,

	/**
	 * Description:		Gets clip ammo from the target weapon.
	 *					This function is not supported in Earth's Special Forces mod.
	 * Forward params:	function(this, idTarget)
	 * Return type:		Integer.
	 * Execute Params:	ExecuteHam(Ham_Weapon_ExtractAmmo, this, idTarget)
	 */
	Ham_Weapon_ExtractClipAmmo,

	/**
	 * Description:		Unsure.
	 *					This function is not supported in Earth's Special Forces mod.
	 * Forward params:	function(this)
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Weapon_AddWeapon, this);
	 */
	Ham_Weapon_AddWeapon,

	/**
	 * Description:		Plays the weapon's empty sound.
	 * Forward params:	function(this)
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Weapon_PlayEmptySound, this);
	 */
	Ham_Weapon_PlayEmptySound,

	/**
	 * Description:		Sets the weapon so that it can play empty sound again.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Weapon_ResetEmptySound, this);
	 */
	Ham_Weapon_ResetEmptySound,

	/**
	 * Description:		Sends an animation event for the weapon.
	 *					This function has different versions for the following mods:
	 *						Counter-Strike: see Ham_CS_Weapon_SendWeaponAnim.
	 *						Team Fortress Classic: see Ham_TFC_Weapon_SendWeaponAnim.
	 *						Day Of Defeat: see Ham_DOD_Weapon_SendWeaponAnim.
	 * Forward params:	function(this, iAnim, skiplocal, body);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Weapon_SendWeaponAnim, this, iAnim, skiplocal, body);
	 */
	Ham_Weapon_SendWeaponAnim,

	/**
	 * Description:		Whether or not the weapon is usable (has ammo, etc.)
	 *					This function is not supported in Earth's Special Forces mod.
	 * Forward params:	function(this)
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Weapon_IsUsable, this)
	 */
	Ham_Weapon_IsUsable,

	/**
	 * Description:		Called when the main attack of a weapon is triggered.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Weapon_PrimaryAttack, this);
	 */
	Ham_Weapon_PrimaryAttack,

	/**
	 * Description:		Called when the secondary attack of a weapon is triggered.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Weapon_SecondaryAttack, this);
	 */
	Ham_Weapon_SecondaryAttack,

	/**
	 * Description:		Called when the weapon is reloaded.
	 *					This function is not supported in Earth's Special Forces mod.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Weapon_Reload, this);
	 */
	Ham_Weapon_Reload,

	/**
	 * Description:		Displays the idle animation for the weapon.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Weapon_WeaponIdle, this);
	 */
	Ham_Weapon_WeaponIdle,

	/**
	 * Description:		There is no more ammo for this gun, so switch to the next best one.
	 * Forward params:	function(this)
	 * Return type:		None.
	 * ExecuteParams:	ExecuteHam(Ham_Weapon_RetireWeapon, this)
	 */
	Ham_Weapon_RetireWeapon,

	/**
	 * Description:		Whether or not the weapon should idle.
	 * Forward params:	function(this)
	 * Return type:		Integer (boolean).
	 * Execute Params:	ExecuteHam(Ham_Weapon_ShouldWeaponIdle, this)
	 */
	Ham_Weapon_ShouldWeaponIdle,

	/**
	 * Description:		Unsure.
	 *					This function is not supported by Team Fortress Classic.
	 * Forward params:	function(this)
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_Weapon_UseDecrement, this);
	 */
	Ham_Weapon_UseDecrement,


	/**
	 * The following functions are specific to Counter-Strike.
	 */

	/**
	 * Description:		This is called on a map reset for most map based entities.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_CS_Restart, this);
	 */
	Ham_CS_Restart = 97,

	/**
	 * Description:		Respawn function for players/bots only! Do not use this on non player/bot entities!
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_CS_RoundRespawn, this);
	 */
	Ham_CS_RoundRespawn,

	/**
	 * Description:		Whether or not the player can drop the specified item.
	 * Forward params:	function(this)
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_CS_Item_CanDrop, this);
	 */
	Ham_CS_Item_CanDrop,

	/**
	 * Description:		Gets the maximum speed for whenever a player has the item deployed.
	 * Forward params:	function(this);
	 * Return type:		Float (byref'd in ExecuteHam).
	 * Execute params:	ExecuteHam(Ham_CS_Item_GetMaxSpeed, this, Float:output);
	 */
	Ham_CS_Item_GetMaxSpeed,


	/**
	 * LATE ADDITIONS (2011)
	 */

	/**
	 * Description:		Turns a monster towards its ideal_yaw.
	 * Forward params:	function(this, speed);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_ChangeYaw, this, speed);
	 */
	Ham_ChangeYaw,

	/**
	 * Description:		Returns if monster has human gibs.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_HasHumanGibs, this);
	 */
	Ham_HasHumanGibs,

	/**
	 * Description:		Returns if monster has alien gibs.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_HasAlienGibs, this);
	 */
	Ham_HasAlienGibs,

	/**
	 * Description:		Slowly fades a entity out, then removes it.
	 *					Using this on player will crash your server.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_FadeMonster, this);
	 */
	Ham_FadeMonster,

	/**
	 * Description:		Create some gore and get rid of a monster's model.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_GibMonster, this);
	 */
	Ham_GibMonster,

	/**
	 * Description:		Called when monster dies and prepares its entity to become a corpse.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_BecomeDead, this);
	 */
	Ham_BecomeDead,

	/**
	 * Description:		Checks relation ship between two monsters.
	 * Forward params:	function(this, idother);
	 * Return type:		Integer (R_* constants, see HLDSK).
	 * Execute params:	ExecuteHam(Ham_IRelationship, this, idother);
	 */
	Ham_IRelationship,

	/**
	 * Description:		Called when monster is about to emit pain sound.
	 *					Not guaranteed to actually emit sound. (random, time, etc..)
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_PainSound, this);
	 */
	Ham_PainSound,

	/**
	 * Description:		Prints debug information about monster to console. (state, activity, and other)
	 *					This function is called by impulse 103.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_ReportAIState, this);
	 */
	Ham_ReportAIState,

	/**
	 * Description:		Called when monster has died.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_MonsterInitDead, this);
	 */
	Ham_MonsterInitDead,

	/**
	 * Description:		Function to find enemies or food by sight.
	 *					distance is maximum distance (in units) monster can see.
	 * Forward params:	function(this, distance);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_Look, this, distance);
	 */
	Ham_Look,

	/**
	 * Description:		This functions searches the link list whose head is the caller's m_pLink field.
	 * Forward params:	function(this);
	 * Return type:		Integer (entity).
	 * Execute params:	ExecuteHam(Ham_BestVisibleEnemy, this);
	 */
	Ham_BestVisibleEnemy,

	/**
	 * Description:		Returns true if the passed ent is in the caller's forward view cone.
	 *					The dot product is performed in 2d, making the view cone infinitely tall.
	 * Forward params:	function(this, idOther);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_FInViewCone, this, idOther);
	 */
	Ham_FInViewCone,

	/**
	 * Description:		Returns true if the passed ent is in the caller's forward view cone.
	 *					The dot product is performed in 2d, making the view cone infinitely tall.
	 * Forward params:	function(this, const Float:origin[3]);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_FVecInViewCone, this, const Float:origin[3]);
	 */
	Ham_FVecInViewCone,

	/**
	 * Description:		Determines the best type of death animation to play.
	 * Forward params:	function(this);
	 * Return type:		Integer (ACT_* constants, see HLDSK. It might different depending the mod).
	 * Execute params:	ExecuteHam(Ham_GetDeathActivity, this);
	 */
	Ham_GetDeathActivity,


	/**
	 * The following functions are specific to Counter-Strike.
	 */

	/**
	 * Description:		Sends an animation event for the weapon. skiplocal is 1 if client is predicting weapon animations.
	 * Forward params:	function(this, anim, skiplocal);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_CS_Weapon_SendWeaponAnim, this, anim, skiplocal);
	 */
	Ham_CS_Weapon_SendWeaponAnim,

	/**
	 * Description:		Resets the player's max speed.
	 * Forward params:	function(this);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_CS_Player_ResetMaxSpeed, this);
	 */
	Ham_CS_Player_ResetMaxSpeed,

	/**
	 * Description:		Whether or not the player is a bot.
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_CS_Player_IsBot, this);
	 */
	Ham_CS_Player_IsBot,

	/**
	 * Description:		Returns a vector that tells the autoaim direction.
	 *					Set crosshair position to point to enemey if sv_aim is 1.
	 * Forward params:	function(this, Float:delta)
	 * Return type:		Vector, byreffed in execute.
	 * Execute params:	ExecuteHam(Ham_CS_Player_GetAutoaimVector, this, Float:delta, Float:output[3]);
	 */
	Ham_CS_Player_GetAutoaimVector,

	/**
	 * Description:		Whether or not the player is being flashing. (flashbang grenade explosion)
	 *					blindTime is the time you are considered as being blind. (holdTime * 0.33).
	 * Forward params:	function(this, Float:blindTime, Float:duration, Float:holdTime, alpha);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_CS_Player_Blind, this, Float:blindTime, Float:duration, Float:holdTime, alpha);
	 */
	Ham_CS_Player_Blind,

	/**
	 * Description:		Whether or not the player is touching a weapon on the ground.
	 * Forward params:	function(this, entityid);
	 * Return type:		None.
	 * Execute params:	ExecuteHam(Ham_CS_Player_OnTouchingWeapon, this, entityid);
	 */
	Ham_CS_Player_OnTouchingWeapon,

	/**
	 * Description:		-
	 * Forward params:	function(this);
	 * Return type:		Integer (boolean).
	 * Execute params:	ExecuteHam(Ham_CS_Item_IsWeapon, this);
	 */
	Ham_CS_Item_IsWeapon,


	/**
	 * Description:		Gets item infos.
	 * Forward params:	function(this, iteminfo_handle);
	 * Return type:		Integer.
	 * Execute params:	ExecuteHam(Ham_Item_GetItemInfo, this, iteminfo_handle);
	 *					Use CreateHamItemInfo() to pass a new ItemInfo handle.
	 */
	Ham_Item_GetItemInfo,


	/**
	 * DONT USE ME LOL
	 */
	HAM_LAST_ENTRY_DONT_USE_ME_LOL
};

/**
 * Ham error types.
 */
enum HamError
{
	HAM_OK = 0,

	HAM_INVALID_FUNC,			// The function is not valid
	HAM_FUNC_NOT_CONFIGURED,	// This function is not configured in hamdata.ini

	HAM_ERR_END
};

/**
 * Constants for usage with [Get|Set]HamItemInfo
 */
enum HamItemInfo
{
	Ham_ItemInfo_iSlot,
	Ham_ItemInfo_iPosition,
	Ham_ItemInfo_pszAmmo1,
	Ham_ItemInfo_iMaxAmmo1,
	Ham_ItemInfo_pszAmmo2,
	Ham_ItemInfo_iMaxAmmo2,
	Ham_ItemInfo_pszName,
	Ham_ItemInfo_iMaxClip,
	Ham_ItemInfo_iId,
	Ham_ItemInfo_iFlags,
	Ham_ItemInfo_iWeight
};

