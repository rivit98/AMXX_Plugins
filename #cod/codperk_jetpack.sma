#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <codmod>


#pragma tabsize 0

#define PREDKOSC 450

new smoke;
new bool:has_jp[33];
new bool:has_started;
new frame[33];

new ilosc_rakiet_gracza[33],
poprzednia_rakieta_gracza[33],
sprite_blast;


new bool:ma_perk[33];

new const nazwa[] = "Jetpack";
new const opis[] = "Ma Jetpack (plecak odrzutowy) [C]";

public plugin_init() 
{
	register_plugin(nazwa , "" , "RiviT - GG 44207778");
	
	cod_register_perk(nazwa, opis)
	
	register_event("DeathMsg" , "Event_DeathMsg" , "a");
	register_event("HLTV" , "did_not_start" , "a" , "1=0" , "2=0");
	
	register_logevent("did_start" , 2 , "1=Round_Start");
	
	register_event("CurWeapon","CurWeapon","be", "1=1")
	register_forward(FM_PlayerPreThink, "PlayerPreThink")
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1)
	register_forward(FM_CmdStart,"fwd_CmdStart")
	
		
	register_event("ResetHUD", "ResetHUD", "abe");
	register_touch("rocket", "*" , "DotykRakiety");

}

public plugin_precache() 
{
	smoke = precache_model("sprites/lightsmoke.spr");
	precache_model("models/p_egon.mdl")
	precache_model("models/v_egon.mdl")
	precache_sound("QTM_CodMod/jetpack.wav");
      sprite_blast = precache_model("sprites/dexplo.spr");
	precache_model("models/rpgrocket.mdl");

}


public DotykRakiety(ent)
{
	if (!is_valid_ent(ent))
		return;

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
	new numfound = find_sphere_class(ent, "player", 190.0, entlist, 32);
	
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i];
		
		if (!is_user_alive(pid) || get_user_team(attacker) == get_user_team(pid))
			continue;
		cod_inflict_damage(attacker, pid, 50.0, 0.0, ent, (1<<24));
	}
	remove_entity(ent);
}	

public ResetHUD(id)
	ilosc_rakiet_gracza[id] = 2;

public cod_perk_enabled(id)
{
	ma_perk[id] = true;
		ilosc_rakiet_gracza[id] = 2;

}

public cod_perk_disabled(id)
{
	ma_perk[id] = false;
	has_jp[id] = false;
}

public cod_perk_used(id)
{
	if(has_jp[id])
		JetPackOff(id)
	else
		JetPackOn(id)
}

public Uzyj(id)
{	
	if (!ilosc_rakiet_gracza[id])
	{
		client_print(id, print_center, "Wykorzystales juz wszystkie rakiety!");
		return PLUGIN_CONTINUE;
	}
	
	if(poprzednia_rakieta_gracza[id] + 2.0 > get_gametime())
	{
		return PLUGIN_CONTINUE;
	}

		poprzednia_rakieta_gracza[id] = floatround(get_gametime());
		ilosc_rakiet_gracza[id]--;

		new Float: Origin[3], Float: vAngle[3], Float: Velocity[3];
		
		entity_get_vector(id, EV_VEC_v_angle, vAngle);
		entity_get_vector(id, EV_VEC_origin , Origin);
	
		new Ent = create_entity("info_target");
	
		entity_set_string(Ent, EV_SZ_classname, "rocket");
		entity_set_model(Ent, "models/rpgrocket.mdl");
	
		vAngle[0] *= -1.0;
	
		entity_set_origin(Ent, Origin);
		entity_set_vector(Ent, EV_VEC_angles, vAngle);
	
		entity_set_int(Ent, EV_INT_effects, 2);
		entity_set_int(Ent, EV_INT_solid, SOLID_BBOX);
		entity_set_int(Ent, EV_INT_movetype, MOVETYPE_FLY);
		entity_set_edict(Ent, EV_ENT_owner, id);
	
		VelocityByAim(id, 1000 , Velocity);
		entity_set_vector(Ent, EV_VEC_velocity ,Velocity);
		
	return PLUGIN_CONTINUE;
}


public PlayerPreThink(id)
{
	if(!is_user_alive(id)) 
	{
		return FMRES_IGNORED;
	}
	if(!ma_perk[id])
	{
		return FMRES_IGNORED;
	}
	if(!has_jp[id])
	{
		return FMRES_IGNORED;
	}	
	if(!has_started)
	{
		return FMRES_IGNORED;
	}
	new bt = pev(id, pev_button)
	if(get_user_weapon(id) != CSW_C4)
	{
            if(bt & IN_ATTACK) Uzyj(id)
            set_pev(id, pev_button, bt & ~IN_ATTACK);
            set_pev(id, pev_button, bt & ~IN_ATTACK2);
	}
	
	if(bt & IN_JUMP) 
	{
            new Float:fAim[3] , Float:fVelocity[3];
            VelocityByAim(id , PREDKOSC, fAim);
			
            fVelocity[0] = fAim[0];
            fVelocity[1] = fAim[1];
            fVelocity[2] = fAim[2]+10;
			
            set_user_velocity(id , fVelocity);
			
            entity_set_int(id , EV_INT_gaitsequence , 6);
			
            if(frame[id] >= 40) 
            {
                  frame[id] = 0;
                  smoke_effect(id);
                  entity_set_string(id , EV_SZ_weaponmodel , "models/p_egon.mdl");
                  emit_sound(id , CHAN_VOICE , "QTM_CodMod/jetpack.wav" , 1.0 , ATTN_NORM , 0 , PITCH_NORM);
            }
            frame[id]++;
	}

	return FMRES_IGNORED;
}

public UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
	{
		return FMRES_IGNORED;
	}
	if(!ma_perk[id])
	{
		return FMRES_IGNORED;
	}
	if(has_jp[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001 ); 
	}
	
	return FMRES_HANDLED;
}

public fwd_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
	{
		return FMRES_IGNORED;
	}
	if(!ma_perk[id])
	{
		return FMRES_IGNORED;
	}
	
	new buttons = get_uc(uc_handle, UC_Buttons)
	new oldbuttons = get_user_oldbutton(id);
	
	if((buttons & IN_ATTACK) || !(oldbuttons & IN_ATTACK))
	{
		return FMRES_IGNORED;
	}

	if(has_jp[id])         
	{
		set_uc(uc_handle, UC_Buttons, buttons & ~IN_ATTACK);
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public CurWeapon(id)
{
	if(ma_perk[id] && has_jp[id])
	{
            new w = read_data(2)
            if(w == CSW_C4) return;
		if(w == CSW_KNIFE)
		{
			set_pev(id, pev_viewmodel2, "models/v_egon.mdl")
			set_pev(id, pev_weaponmodel2, "models/p_egon.mdl")
		}
		else
		{
                  engclient_cmd(id, "weapon_knife")
                  set_pev(id, pev_viewmodel2, "models/v_egon.mdl")
			set_pev(id, pev_weaponmodel2, "models/p_egon.mdl")
            }
	}
}

public smoke_effect(id) 
{
	new origin[3];
	get_user_origin(id, origin, 0);
	origin[2] = origin[2] - 10;
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(17);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(smoke);
	write_byte(10);
	write_byte(115);
	message_end();
}

public JetPackOn(id) 
{	
	if(!ma_perk[id])
	{
		return PLUGIN_HANDLED;
	}
	if(!is_user_alive(id)) 
	{
		client_print(id , print_center , "Nie mozesz zalozyc plecaka gdy nie zyjesz!");
		return PLUGIN_HANDLED;
	}
	
	if(has_jp[id]) 
	{
		client_print(id , print_center , "Masz juz ubrany Jetpack!");
		return PLUGIN_HANDLED;
	}
	
	has_jp[id] = true;
	engclient_cmd(id, "weapon_knife")
      set_pev(id, pev_viewmodel2, "models/v_egon.mdl")
      set_pev(id, pev_weaponmodel2, "models/p_egon.mdl")
	
	client_print(id , print_center , "Ubrales Jetpack! By go uzyc trzymaj klawisz skoku i kieruj myszka");
	
	emit_sound(id , CHAN_VOICE , "items/gunpickup2.wav" , 1.0 , ATTN_NORM , 0 , PITCH_NORM);
	
	return PLUGIN_HANDLED;
}

public JetPackOff(id)
{
	if(!ma_perk[id])
	{
		return PLUGIN_HANDLED;
	}
	
	if(!has_jp[id]) 
	{
		client_print(id , print_center , "Nie masz ubranego Jetpacka!");
		return PLUGIN_HANDLED;
	}
	
	client_print(id , print_center , "Zdjeles Jetpack!");
	
      set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
      set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")

	
	has_jp[id] = false;
	
	return PLUGIN_HANDLED;
}

public Event_DeathMsg() 
{
	new victim = read_data(2)
	
	if(!ma_perk[victim])
	{
		return PLUGIN_CONTINUE;
	}
	
	has_jp[victim] = false;
	
	return PLUGIN_CONTINUE;
}

public did_not_start() 
{
	has_started = false;
	
	new aPlayers[32] , iNum , i;
	get_players(aPlayers, iNum);
	for(i = 1; i <= iNum; i++) 
	{
		has_jp[aPlayers[i]] = false;
	}
	new ent = -1;
	while((ent = find_ent_by_class(ent , "jetpack")) != 0) 
	{
		remove_entity(ent);
	}
}

public did_start() 
{
	has_started = true;
}

public client_connect(id) 
{
	has_jp[id] = false;
}

public client_disconnect(id)
{
	has_jp[id] = false;
}