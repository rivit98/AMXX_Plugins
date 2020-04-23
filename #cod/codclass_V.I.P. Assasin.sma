#include <amxmodx>
#include <amxmisc>
#include <codmod>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <cstrike>
        
new const nazwa[]   = " [V.I.P.] Assasin";
new const opis[]    = "widocznoœæ na nozu 20, nieskoñczonoœæ skokow, mniejsza grawitacja,  modul odrzutowy, nie s³ychaæ twoich krokow, 1/1 z noza, BH (+ 1 rakieta lub  rozblysk)";
new const bronie    = (1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M4A1)|(1<<CSW_FLASHBANG)|(1<<CSW_DEAGLE);
new const zdrowie   = 44;
new const kondycja  = 200;
new const inteligencja = 10;
new const wytrzymalosc = 10;
    
new skoki[33];

new ma_klase[33];

public plugin_init()
{
	register_plugin(nazwa, "1.0", "amxx.pl");

	cod_register_class(nazwa, opis, bronie, zdrowie, kondycja, inteligencja, wytrzymalosc);

	register_event("CurWeapon", "eventKnife_Niewidzialnosc", "be", "1=1");
   
	RegisterHam(Ham_Spawn, "player", "fwSpawn_Grawitacja", 1);

   
	register_forward(FM_CmdStart, "fwCmdStart_MultiJump");
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");



	register_forward(FM_PlayerPreThink, "fwPrethink_AutoBH");

}

public cod_class_enabled(id)
{
	if(!(get_user_flags(id) & ADMIN_LEVEL_A))
	{
		client_print(id, print_chat, "[ [V.I.P.] Assasin] Nie masz uprawnien, aby uzywac tej klasy.")
		return COD_STOP;
	}

 	entity_set_float(id, EV_FL_gravity, 650.0/800.0);
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	cs_set_user_nvg(id, 1);
	cs_set_user_defuse(id, 1);
	set_user_footsteps(id, 1)
	ma_klase[id] = true;
   
	return COD_CONTINUE;
}

public cod_class_disabled(id)
{
	set_rendering(id,kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
    
 	entity_set_float(id, EV_FL_gravity, 1.0);
 	set_user_footsteps(id, 0)
	ma_klase[id] = false;

}
new Float:ostatni_skok[33];

public cod_class_skill_used(id)
{
	if(pev(id, pev_flags) & FL_ONGROUND && get_gametime() > ostatni_skok[id]+4.0)
	{
		ostatni_skok[id] = get_gametime();
		new Float:velocity[3];
		velocity_by_aim(id, 666+cod_get_user_intelligence(id), velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(id, pev_velocity, velocity);
	}
}


public eventKnife_Niewidzialnosc(id)
{
	if(!ma_klase[id])
		return;

	if( read_data(2) == CSW_KNIFE )
	{
		set_rendering(id,kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 20);
	}
	else
	{
		set_rendering(id,kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
	}
}

public fwSpawn_Grawitacja(id)
{
	if(ma_klase[id])
		entity_set_float(id, EV_FL_gravity, 650.0/800.0);
}


public fwCmdStart_MultiJump(id, uc_handle)
{
	if(!is_user_alive(id) || !ma_klase[id])
		return FMRES_IGNORED;

	new flags = pev(id, pev_flags);

	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(flags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && skoki[id])
	{
		skoki[id]--;
		new Float:velocity[3];
		pev(id, pev_velocity,velocity);
		velocity[2] = random_float(265.0,285.0);
		set_pev(id, pev_velocity,velocity);
	}
	else if(flags & FL_ONGROUND)
		skoki[id] = 999;

	return FMRES_IGNORED;
}

public fwPrethink_AutoBH(id)
{
	if(!ma_klase[id])
		return PLUGIN_CONTINUE

	if (pev(id, pev_button) & IN_JUMP) {
		new flags = pev(id, pev_flags)

		if (flags & FL_WATERJUMP)
			return FMRES_IGNORED;
		if ( pev(id, pev_waterlevel) >= 2 )
			return FMRES_IGNORED;
		if ( !(flags & FL_ONGROUND) )
			return FMRES_IGNORED;

		new Float:velocity[3];
		pev(id, pev_velocity, velocity);
		velocity[2] += 250.0;
		set_pev(id, pev_velocity, velocity);

		set_pev(id, pev_gaitsequence, 6);

	}
	return FMRES_IGNORED;
}

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker) || get_user_team(this) == get_user_team(idattacker))
		return HAM_IGNORED;
		
	if(ma_klase[idattacker] && get_user_weapon(idattacker) == CSW_KNIFE && damagebits & DMG_BULLET && get_pdata_float(get_pdata_cbase(idattacker, 373, 5), 47, 4) > 1.0)
		KillPlayer(this, idinflictor, idattacker, (1<<1))

	return HAM_IGNORED;
}

KillPlayer(id, inflictor, attacker, damagebits)
{
	static DeathMsgId
	
	new msgblock, effect
	if (!DeathMsgId)	DeathMsgId = get_user_msgid("DeathMsg")
	
	msgblock = get_msg_block(DeathMsgId)
	set_msg_block(DeathMsgId, BLOCK_ONCE)
	
	set_pdata_int(id, 75, HIT_CHEST , 5)
	set_pdata_int(id, 76, damagebits, 5)
	
	ExecuteHamB(Ham_Killed, id, attacker, 1)
	
	set_pev(id, pev_dmg_inflictor, inflictor)
	
	effect = pev(id, pev_effects)
	if(effect & 128)	set_pev(id, pev_effects, effect-128)
	
	set_msg_block(DeathMsgId, msgblock)

	message_begin(MSG_ALL, DeathMsgId)
	write_byte(attacker)
	write_byte(id)
	write_byte(0)
      write_string("knife")
	message_end()

}
