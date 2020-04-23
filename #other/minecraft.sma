/*
MINECRAFT MOD
by diablix & DarkGL (C)

PLATFORM: Linux
*/

#define AUTHORS "diablix & DarkGL"

#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>

#include <hamsandwich>

#include <xs>

#define VERSION "0.1"

#define SLOTS 24

#define SZYBKOSC_STAWIANIA_KLOCKOW 	0.2 //im mniej tym szybciej
#define DYSTANS_KILOFU			150.0 //im wiecej tym wiekszy zasieg ma kilof
#define UDERZENIE_KILOFU		0x32 //ile zabiera uderzenie kilofu
#define SZYBKOSC_ATAKU			0.1 // im mniej tym szybciej
#define IsPlayer(%1) 			(1 <= %1 <= g_iMaxPlayers)
#define DMG_MINECRAFT 			(0x1<<0x37)
#define SPEED_LITTLE			50.0 //szybkosc przyciaganie do gracza
#define RADIUS_LITTLE			30.0 // z jakiej odleglosci lapie

#define MinecraftSetBlockOwner(%1,%2) 	(set_pev(%2,pev_iuser2,%1))
#define MinecraftGetBlockOwner(%1)	pev(%1,pev_iuser2)
#define MineCraftPushAngles(%1) 	set_pev(%1, pev_nextthink, get_gametime() + 0.01)

enum SIZES{
	BIG,
	LIL
};

enum _:iModele{
	VIEW,
	WORLD,
	LITTLE
};

enum _:iRozmiary{
	MINS,
	MAXS,
	MINS_LIL,
	MAXS_LIL
};

new const g_sSoundsToBlock[][] = {
	"weapons/knife_hitwall1.wav",
	"weapons/knife_slash1.wav",
	"weapons/knife_slash2.wav",
	"weapons/knife_deploy1.wav",
	"debris/glass1.wav",
	"debris/glass2.wav",
	"debris/glass3.wav",
	"debris/bustglass1.wav",
	"debris/bustglass2.wav",
	"debris/bustglass3.wav",
	"debris/metal1.wav",
	"debris/metal2.wav",
	"debris/metal3.wav",
	"debris/bustmetal1.wav",
	"debris/bustmetal2.wav",
	"debris/bustmetal3.wav",
	"debris/bustceiling1.wav",
	"debris/bustceiling2.wav",
	"debris/bustceiling3.wav",
	"debris/bustconcrete1.wav",
	"debris/bustconcrete2.wav",
	"debris/bustconcrete3.wav",
	"debris/concrete1.wav",
	"debris/concrete2.wav",
	"debris/concrete3.wav",
	"debris/bustflesh1.wav",
	"debris/bustflesh2.wav",
	"debris/bustflesh3.wav",
	"debris/flesh1.wav",
	"debris/flesh2.wav",
	"debris/flesh3.wav",
	"debris/bustcrate1.wav",
	"debris/bustcrate2.wav",
	"debris/bustcrate3.wav",
	"debris/wood1.wav",
	"debris/wood2.wav",
	"debris/wood3.wav"
};

enum{
	ZIEMIA,
	KAMIEN
};

new const g_iZyciaKlockow[] = {
	255,
	384
};

new const g_sMinecraftModelsZiemia[][] = {
	"models/minecraft/v_ziemia.mdl",
	"models/minecraft/world_ziemia.mdl",
	"models/minecraft/w_lziemia.mdl"
};

new const g_sMinecraftSoundsZiemia[][] = {
	"minecraft/smash.wav"
};

new const Float:g_fBlockSizes[4][3] = {
	{-14.0, -14.0, -14.0}, 
	{14.0, 14.0, 14.0},
	{-2.0, -2.0, -2.0},
	{2.0, 2.0, 2.0}
}

new const g_sMinecraftModelsKilof[][] = {
	"models/minecraft/kilof_v.mdl"
};

new const g_sMinecraftWeapon[] 		= "weapon_knife";
new const g_sMinecraftWeaponKilof[] 	= "weapon_glock18";
new const g_sMinecraftClass[]		= "cl_minecraft";
new const g_sMinecraftClassLittle[]	= "cl_minecraft_little"

const g_iMaxKlockow 			= 100;

new g_iKlockiLeft[SLOTS + 1];
new Float:g_fSmashAlowed[SLOTS + 1];
new g_iMaxPlayers;
new g_msgTextMsg;
new g_BreakModel;

public plugin_init() {
	register_plugin("Minecraft Mod", VERSION, AUTHORS)
	
	g_iMaxPlayers = get_maxplayers();
	g_msgTextMsg = get_user_msgid("TextMsg");
	
	register_message(g_msgTextMsg, "msgTextMsg");
	
	RegisterHam(Ham_Item_Deploy, g_sMinecraftWeapon, "fwItemDeployMineWeapon",1);
	RegisterHam(Ham_Item_Deploy, g_sMinecraftWeaponKilof, "fwItemDeployMineKilof",1);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, g_sMinecraftWeapon, "fwMinecraftPut");
	RegisterHam(Ham_Weapon_PrimaryAttack, g_sMinecraftWeapon, "fwMinecraftPutPost", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack,  g_sMinecraftWeaponKilof, "fwMinecraftSmashPost", 1);
	
	RegisterHam(Ham_Spawn, "player", "eventPlayerSpawn", 1);
	
	register_logevent("Koniec_Rundy", 2, "1=Round_End") 
	
	register_forward(FM_EmitSound, "fwEmitSound");
	register_forward(FM_AddToFullPack, "fwMinecraftEffects", 1);
	
	register_think(g_sMinecraftClassLittle, "MinecraftThink");
	
	register_touch(g_sMinecraftClassLittle, "player", "MinecraftTouchLittle");
}

public plugin_precache(){
	for(new i ; i < iModele ; i ++)
		engfunc(EngFunc_PrecacheModel, g_sMinecraftModelsZiemia[i]);
	
	engfunc(EngFunc_PrecacheModel, g_sMinecraftModelsKilof[0]);	
	engfunc(EngFunc_PrecacheSound, g_sMinecraftSoundsZiemia[0]);
	
	g_BreakModel = engfunc(EngFunc_PrecacheModel, "models/rockgibs.mdl");
}

public Koniec_Rundy(){
	remove_entity_name(g_sMinecraftClass);
	remove_entity_name(g_sMinecraftClassLittle);
}


public eventPlayerSpawn(id){
	g_iKlockiLeft[id] = g_iMaxKlockow;
	
	if(!is_user_alive(id))
		return HAM_IGNORED;
	
	g_fSmashAlowed[id] = 0.0;
	strip_user_weapons(id);
	
	give_item(id,g_sMinecraftWeapon);
	give_item(id,g_sMinecraftWeaponKilof);
	
	return HAM_IGNORED;
}

public msgTextMsg(iMsgid, iDest, id){
	new sArg[32];
	get_msg_arg_string(2, sArg, sizeof sArg - 1)
	
	if(equal(sArg, "#Sw", 3))
		return 1;
	
	return 0;
}

public fwItemDeployMineWeapon(wpn){
	static iOwner;
	iOwner = pev(wpn,pev_owner);
	
	set_pev(iOwner, pev_viewmodel2, g_sMinecraftModelsZiemia[VIEW]);
	
	set_pdata_float(wpn, 46, 99999.0, 4);
}

public fwItemDeployMineKilof(wpn){
	static iOwner;
	iOwner = pev(wpn, pev_owner);
	
	if(IsPlayer(iOwner)){
		set_pev(iOwner, pev_viewmodel2, g_sMinecraftModelsKilof[VIEW]);
		MinecraftAnimate(iOwner, 3);
	}
	
	set_pdata_float(wpn, 46, 99999.0, 4);
}

public fwMinecraftSmashPost(iEnt){
	new id = pev(iEnt, pev_owner);
	
	if(g_fSmashAlowed[id] >= 0.1) return HAM_IGNORED;
	
	MinecraftSmashEntity(id);
	MinecraftAnimate(id, 7);
	g_fSmashAlowed[id] = SZYBKOSC_ATAKU;
	set_task(0.1, "MinecraftSmashCooldown", id, _, _, "a", floatround(SZYBKOSC_ATAKU * 10));
	
	return HAM_IGNORED;
}

public fwMinecraftPut(iEnt){
	new id = pev(iEnt, pev_owner);
	
	if(!g_iKlockiLeft[id]){ 
		client_print(id, print_center, "Nie masz juz klockow !");
		return HAM_IGNORED; 
	}
	
	new Float:fOrigin[3];
	createTrace(id, fOrigin);
	
	static iTrace;
	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, 0, 0, iTrace);
	
	if(!get_tr2(iTrace, TR_StartSolid) && !get_tr2(iTrace, TR_AllSolid) && get_tr2(iTrace, TR_InOpen)){ //start nie solidny, obszar otwarty
		g_iKlockiLeft[id]--;
		
		client_print(id, print_center, "Klocki : %d / %d", g_iKlockiLeft[id], g_iMaxKlockow);
		MinecraftCreateBlock(id, fOrigin, ZIEMIA);
	}
	
	return HAM_IGNORED;
}

public fwMinecraftPutPost(iEnt){
	new Float:Delay = get_pdata_float(iEnt, 46, 4) * SZYBKOSC_STAWIANIA_KLOCKOW;
	set_pdata_float(iEnt, 46, Delay, 4);
	set_pdata_float(iEnt, 47, Delay, 4);
	set_pdata_float(iEnt, 48, Delay, 4);
}

public fwEmitSound(iEntity, iChannel, const sSound[]){
	static i;
	
	for(i = 0 ; i < sizeof g_sSoundsToBlock ; i++){
		if(equal(sSound, g_sSoundsToBlock[i])){	
			return FMRES_SUPERCEDE; // narazie zablokujemy, potem podmianke zalatwie:)
		}
	}
	return FMRES_IGNORED;
}

public fwMinecraftEffects(iHandle, e, iEntity, id, iFlags, iPlayer, pSet){	
	if(pev_valid(iEntity) && IsPlayer(id) && MinecraftHasClassname(iEntity, BIG)){
		set_es(iHandle, ES_RenderMode, kRenderTransAlpha);
		set_es(iHandle, ES_RenderAmt, entity_get_int(iEntity, EV_INT_iuser1));
	}
}

public MinecraftSmashCooldown(id)
	g_fSmashAlowed[id] -= 0.1;

public MinecraftCreateBlock(id, const Float:fOrigin[3], const Typ){
	if(entity_count() >= global_get(glb_maxEntities)){
		log_amx("[MINECRAFT] Zabraklo miejsca na enty ! Serwer zostal powstrzymany przed crashem !");
		return 0;
	}
	
	new iEnt = create_entity("func_breakable");
	
	if(pev_valid(iEnt)){
		MinecraftSetBlockOwner(id, iEnt);
		new Float:vSizeMin[3], Float:vSizeMax[3];	
		
		for(new i = 0 ; i < 3 ; i ++){
			vSizeMin[i] = g_fBlockSizes[MINS][i];
			vSizeMax[i] = g_fBlockSizes[MAXS][i];
		}
		
		entity_set_string(iEnt, EV_SZ_classname, g_sMinecraftClass);
		entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
		entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_model(iEnt, g_sMinecraftModelsZiemia[WORLD]);
		entity_set_size(iEnt, vSizeMin, vSizeMax);
		
		entity_set_origin(iEnt, fOrigin);
		
		entity_set_int(iEnt, EV_INT_iuser1, g_iZyciaKlockow[Typ]);
		
	}
	return iEnt; //dla dalszych operacji ;)
}

public MinecraftSmashEntity(id){
	new iEnt, iBody;
	get_user_aiming(id, iEnt, iBody);
	
	if(pev_valid(iEnt)){
		if(MinecraftHasClassname(iEnt, BIG)){
			if(MinecraftGetBlockOwner(iEnt) == id){
				new Float:fOrigin[2][3];
				pev(id, pev_origin, fOrigin[0]);
				pev(iEnt, pev_origin, fOrigin[1]);
				
				if(get_distance_f(fOrigin[0], fOrigin[1]) <= DYSTANS_KILOFU){
					if(task_exists(iEnt)) remove_task(iEnt);
					
					MinecraftExplode(iEnt);
					
					new iHp = entity_get_int(iEnt, EV_INT_iuser1);
					
					((iHp - UDERZENIE_KILOFU) > 0) ? entity_set_int(iEnt,EV_INT_iuser1, iHp-UDERZENIE_KILOFU) : MinecraftRestoreBlock(iEnt);
					
					emit_sound(iEnt, CHAN_STREAM, g_sMinecraftSoundsZiemia[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
					
					set_task(0.5, "MinecraftRestoreBig", iEnt);
				}
			}
			else{
				client_print(id, print_center, "To nie Twoj klocek!");
			}
		}
	}
}

public MinecraftRestoreBig(iEnt){
	if(pev_valid(iEnt)){
		entity_set_int(iEnt, EV_INT_iuser1, 255);
	}
}

public MinecraftRestoreBlock(iOldEnt){	
	new Float:fOrigin[3], Float:fVelocity[3];
	entity_get_vector(iOldEnt, EV_VEC_origin, fOrigin);
	entity_get_vector(iOldEnt, EV_VEC_velocity, fVelocity);
	new iOldOwner = MinecraftGetBlockOwner(iOldEnt);
	
	remove_entity(iOldEnt);
	
	new iEnt = create_entity("info_target");
	
	if(pev_valid(iEnt)){
		new Float:vSizeMin[3], Float:vSizeMax[3];	
		
		for(new i = 0 ; i < 3 ; i ++){
			vSizeMin[i] = g_fBlockSizes[MINS_LIL][i];
			vSizeMax[i] = g_fBlockSizes[MAXS_LIL][i];
		}
		
		entity_set_string(iEnt, EV_SZ_classname, g_sMinecraftClassLittle);
		entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
		entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_TOSS);
		entity_set_model(iEnt, g_sMinecraftModelsZiemia[LITTLE]);
		entity_set_size(iEnt, vSizeMin, vSizeMax);
		
		entity_set_origin(iEnt, fOrigin);
		
		fVelocity[2] += 105.0;
		
		entity_set_vector(iEnt, EV_VEC_velocity, fVelocity);
		
		new any:iData[2];
		iData[0] = iEnt, iData[1] = 0;
		set_task(0.08, "MinecraftResetVelo", _, iData, sizeof iData);
		iData[1]++;
		set_task(0.6, "MinecraftResetVelo", _, iData, sizeof iData);
		
		MinecraftSetBlockOwner(iOldOwner, iEnt);
		
		MineCraftPushAngles(iEnt);
		
	}
	return iEnt;
}

public bool:MinecraftTouchLittle(touched, toucher){
	if(IsPlayer(toucher) && is_user_alive(toucher) && MinecraftGetBlockOwner(touched) == toucher){
		if(g_iKlockiLeft[toucher] + 1 <= g_iMaxKlockow){
			g_iKlockiLeft[toucher]++;
			client_print(toucher, print_center, "Klocki : %d / %d", g_iKlockiLeft[toucher], g_iMaxKlockow);
			remove_entity(touched);
			return true;
		}
	}
	return false;
}

public MinecraftResetVelo(any:iData[]){
	if(!pev_valid(iData[0])) return;
	assert iData[0];
	
	new Float:fVelo[3];
	fVelo[2] = iData[1] ? 0.0 : -95.0;
	
	set_pev(iData[0], pev_velocity, fVelo);
}

public MinecraftHasClassname(iEnt, SIZES:Typ){
	new sClass[32]; 
	pev(iEnt, pev_classname, sClass, sizeof sClass - 1);
	
	return Typ == BIG ? equal(sClass, g_sMinecraftClass) : equal(sClass, g_sMinecraftClassLittle);
}

public createTrace(id,Float:fRet[3]){
	new Float:fOrigin[3], Float:fViev[3];
	
	pev(id, pev_origin,fOrigin);
	pev(id, pev_view_ofs,fViev);
	
	xs_vec_add(fOrigin, fViev, fOrigin);
	
	new Float:fAngles[3]
	
	pev(id,pev_v_angle, fAngles);
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fAngles);
	
	xs_vec_mul_scalar(fAngles, 999.0, fAngles);
	
	xs_vec_add(fOrigin, fAngles, fAngles);
	
	new ptr = create_tr2();
	
	engfunc(EngFunc_TraceLine, fOrigin, fAngles, 0, id, ptr);
	
	new Float:vfNormal[3], Float:fEnd[3], pHit;
	
	get_tr2(ptr, TR_vecPlaneNormal, vfNormal);
	get_tr2(ptr, TR_vecEndPos, fEnd);
	pHit = get_tr2(ptr, TR_pHit);
	
	free_tr2(ptr);
	
	new Float:fInvNormal[3];
	xs_vec_neg(vfNormal, fInvNormal);
	
	if(pev_valid(pHit)){
		new szClass[64];
		pev(pHit,pev_classname,szClass,charsmax(szClass));
		
		if(equal(szClass,g_sMinecraftClass)){
			pev(pHit, pev_origin, fEnd);
			xs_vec_mul_scalar(fInvNormal, 28.0, fInvNormal);
		}
		else{
			xs_vec_mul_scalar(fInvNormal, 14.0, fInvNormal);
		}
	}
	else
	{	
		xs_vec_mul_scalar(fInvNormal,14.0,fInvNormal);
	}
	
	xs_vec_sub(fEnd, fInvNormal, fRet);
	
	parseOrigins(fRet);
}

public parseOrigins(Float:fOrigins[3]){
	new iOrigins[3];
	FVecIVec(fOrigins, iOrigins);
	
	for(new i = 0;i<3;i++){
		if(iOrigins[i] % 28 != 0){
			new iIle = iOrigins[i]/28;
			new iTmp = iOrigins[i] - (iIle * 28);
			iOrigins[i] = (iTmp < 14) ? iOrigins[i] - iTmp : (iIle+1)*28
		}
	}
	new Float:fOriginsTmp[3];
	
	IVecFVec(iOrigins, fOriginsTmp);
	
	xs_vec_copy(fOriginsTmp, fOrigins);
}

public MinecraftThink(iEnt){
	if(pev_valid(iEnt) && MinecraftHasClassname(iEnt, LIL)){
		new Float:fAngles[3];
		pev(iEnt, pev_angles, fAngles);
		
		fAngles[1] += 0.8;
		
		set_pev(iEnt, pev_angles, fAngles);
	}
	MineCraftPushAngles(iEnt);
	
	new iPlayer = -1,Float:fOrigin[3];
	
	pev(iEnt,pev_origin,fOrigin);
	
	while((iPlayer = find_ent_in_sphere(iPlayer,fOrigin,RADIUS_LITTLE)) != 0){
		if(pev_valid(iPlayer) && is_user_alive(iPlayer)){
			if(MinecraftGetBlockOwner(iEnt) == iPlayer){
				if(g_iKlockiLeft[iPlayer] + 1 <= g_iMaxKlockow){
					MinecraftToPlayer(iEnt,iPlayer);
				}
			}
		}
	}
	
	entity_set_float(iEnt,EV_FL_nextthink,get_gametime()+0.01)
}

public MinecraftToPlayer(iEnt,iPlayer){
	set_pev(iEnt,pev_movetype,MOVETYPE_FLY);
	
	new Float:fEntOrigin[3],Float:fPlayerOrigin[3];
	
	pev(iEnt,pev_origin,fEntOrigin)
	pev(iPlayer,pev_origin,fPlayerOrigin);
	
	fPlayerOrigin[2] -= 10.0;
	
	xs_vec_sub(fPlayerOrigin,fEntOrigin,fEntOrigin)
	xs_vec_neg(fEntOrigin,fEntOrigin);
	xs_vec_mul_scalar(fEntOrigin,SPEED_LITTLE,fEntOrigin)
	
	set_pev(iEnt,pev_velocity,fEntOrigin);
}

public MinecraftAnimate(id, numer){
	set_pev(id, pev_weaponanim, numer);
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(numer);
	write_byte(pev(id, pev_body));
	message_end();
}

public MinecraftExplode(iEnt){
	if(pev_valid(iEnt)){
		new Float:fOrigin[3];
		pev(iEnt, pev_origin, fOrigin);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(0x6C);
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		engfunc(EngFunc_WriteCoord, 0.1);
		engfunc(EngFunc_WriteCoord, 0.1);
		engfunc(EngFunc_WriteCoord, 0.1);
		engfunc(EngFunc_WriteCoord, random_float(-15.0, 15.0));
		engfunc(EngFunc_WriteCoord, random_float(-15.0, 15.0));
		write_coord(10);
		write_byte(3);
		write_short(g_BreakModel);
		write_byte(random_num(1, 2));
		write_byte(3);
		write_byte(0x02);
		message_end();  
	}
}
