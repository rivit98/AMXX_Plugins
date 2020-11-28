#include <amxmodx>
#include <engine>
#include cstrike

new user_controll

public plugin_init() {
		
	register_plugin("", "1.0", "RiviT");
	
	register_touch("predator", "*", "touchedpredator");
	
	register_clcmd("say /t", "CreatePredator")
	register_clcmd("say /tt", "h")
}

public h(id)
	cs_set_user_money(id, 16000)

public plugin_precache()
{
	precache_model("models/rpgrocket.mdl");
}

public NowaRunda()
{
	remove_entity_name("predator")
}

public client_PreThink(id)
{	
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;

	if(user_controll)
	{
		static Float:Velocity[3], Float:Angle[3]
		if(is_valid_ent(user_controll))
		{
			new owner = entity_get_edict(user_controll, EV_ENT_owner);
			if(owner != id) return 0;
			velocity_by_aim(id, 70, Velocity);
			entity_get_vector(id, EV_VEC_v_angle, Angle);
			
			entity_set_vector(user_controll, EV_VEC_velocity, Velocity);
			entity_set_vector(user_controll, EV_VEC_angles, Angle);
		}
		else
			attach_view(id, id);
	}
	return PLUGIN_CONTINUE;
}
//predator
public CreatePredator(id)
{
	new Float:Origin[3], Float:Angle[3], Float:Velocity[3], ent;
	
	velocity_by_aim(id, 100, Velocity);
	entity_get_vector(id, EV_VEC_origin, Origin);
	entity_get_vector(id, EV_VEC_v_angle, Angle);
	
	Angle[0] *= -1.0;
	
	ent = create_entity("info_target");
	create_ent(id, ent, "predator", "models/rpgrocket.mdl", 2, 5, Origin);
	
	entity_set_vector(ent, EV_VEC_velocity, Velocity);
	entity_set_vector(ent, EV_VEC_angles, Angle);
	
	attach_view(id, ent);
	user_controll = ent;
} 

public touchedpredator(ent, id)
{
	if(!is_valid_ent(ent))
		return PLUGIN_CONTINUE;

	new owner = entity_get_edict(ent, EV_ENT_owner);
	
	if(is_user_connected(owner))
		attach_view(owner, owner);
	
	user_controll = 0
	
	remove_entity(ent);
	
	return PLUGIN_CONTINUE;
}

stock create_ent(id, ent, szName[], szModel[], iSolid, iMovetype, Float:fOrigin[3])
{
	if(!is_valid_ent(ent)) 
		return;
	entity_set_string(ent, EV_SZ_classname, szName);
	entity_set_model(ent, szModel);
	entity_set_int(ent, EV_INT_solid, iSolid);
	entity_set_int(ent, EV_INT_movetype, iMovetype);
	entity_set_edict(ent, EV_ENT_owner, id);
	entity_set_origin(ent, fOrigin);
}