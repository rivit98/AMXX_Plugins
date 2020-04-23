
#include <amxmodx>
#include <amxmisc>

#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>

#include <xs>

#define PLUGIN	"New Plugin"
#define AUTHOR	"Unknown"
#define VERSION	"1.0"

enum WeaponPosition
{
	Position1,
	Position2,
	Position3,
	Position4
}

new WeaponEntities[WeaponPosition]

new WeaponModels[WeaponPosition][] = 
{
	"models/w_awp.mdl",
	"models/w_ak47.mdl",
	"models/w_deagle.mdl",
	"models/w_m4a1.mdl"
}

new WeaponPosition:PositionsOrdered[WeaponPosition]  =
{
	_:Position1,
	_:Position2,
	_:Position3,
	_:Position4
}

new bool:CantUse[33]

public plugin_precache()
{
	for(new WeaponPosition:i=WeaponPosition:Position1;i<WeaponPosition;i++)
	{	
		precache_model(WeaponModels[i])		
		WeaponEntities[i] = createEntity(WeaponModels[i])	
	}
}
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_AddToFullPack,"addToFullPack",1)
	
	RegisterHam(Ham_ObjectCaps,"player","playerUse")
}

public playerUse(id)
{
	if(~get_user_button(id) & IN_USE)
	{
		CantUse[id] = false
	}
	else if(!CantUse[id])
	{
		CantUse[id] = true
		
		for(new WeaponPosition:i=WeaponPosition:0;i<WeaponPosition;i++)
		{
			if(!PositionsOrdered[i]--)
			{
				PositionsOrdered[i] = WeaponPosition - WeaponPosition:1
			}
		}
	}
}

createEntity(model[])
{
	new ent = create_entity("info_target")
	
	assert ent;
	
	set_pev(ent,pev_takedamage,0.0)
	set_pev(ent,pev_solid,SOLID_NOT);
	set_pev(ent,pev_movetype,MOVETYPE_NONE)

	fm_set_rendering(ent,.render=kRenderTransAlpha,.amount=0)
	
	entity_set_model(ent,model)
	
	return ent
}

public addToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if(is_user_alive(host) && (host == 1))
	{
		for(new WeaponPosition:i=WeaponPosition:0;i<WeaponPosition;i++)
		{
			if(ent == WeaponEntities[i])
			{
				static Float:origin[3],Float:angles[3]
				
				getPositionData(host,origin,angles,PositionsOrdered[i])
				
				// This is a "fix". When you don't have the entity in your "view zone" set_es do not do their job
				// Connor told me about two other ways of fixing it but I haven't tested them yet
				entity_set_origin(WeaponEntities[i],origin)
				
				set_es(es,ES_Origin,origin)
				set_es(es,ES_Angles,angles)
				set_es(es,ES_RenderMode,kRenderNormal)
				set_es(es,ES_RenderAmt,200)
			}
		}
	}
}

stock fm_get_aim_originx(index, Float:origin[3]) 
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 50.0, dest);
	xs_vec_add(start, dest, origin);

	return 1;
}

getPositionData(id,Float:origin[3],Float:angles[3],WeaponPosition:weaponPosition)
{
	pev(id,pev_origin,origin)
	pev(id,pev_v_angle,angles)
	
	static Float:viewOfs[3]
	pev(id,pev_view_ofs,viewOfs);
	xs_vec_add(origin,viewOfs,origin);
	
	static Float:pathForward[3]
	angle_vector(angles,ANGLEVECTOR_FORWARD,pathForward)
	xs_vec_normalize(pathForward,pathForward)
	
	static Float:pathRight[3]
	angle_vector(angles,ANGLEVECTOR_RIGHT,pathRight)
	xs_vec_normalize(pathRight,pathRight)
	
	static Float:pathUp[3]
	angle_vector(angles,ANGLEVECTOR_UP,pathUp)
	xs_vec_normalize(pathUp,pathUp)
	
	angles[0] = angles[0] - 30.0
	angles[1] = angles[1] - 180.0
	
	switch(weaponPosition)
	{
		case Position1:
		{
			xs_vec_mul_scalar(pathForward,60.0,pathForward)
			xs_vec_add(pathForward,origin,origin)
	
			xs_vec_mul_scalar(pathUp,-10.0,pathUp)
			xs_vec_add(pathUp,origin,origin)
		}
		case Position2:
		{
			xs_vec_mul_scalar(pathForward,80.0,pathForward)
			xs_vec_add(pathForward,origin,origin)
		
			xs_vec_mul_scalar(pathRight,50.0,pathRight)
			xs_vec_add(pathRight,origin,origin)
		}
		case Position3:
		{
			xs_vec_mul_scalar(pathForward,120.0,pathForward)
			xs_vec_add(pathForward,origin,origin)
	
			xs_vec_mul_scalar(pathUp,10.0,pathUp)
			xs_vec_add(pathUp,origin,origin)
		}
		case Position4:
		{
			xs_vec_mul_scalar(pathForward,80.0,pathForward)
			xs_vec_add(pathForward,origin,origin)
	
			xs_vec_mul_scalar(pathRight,-50.0,pathRight)
			xs_vec_add(pathRight,origin,origin)
		}
	}
}