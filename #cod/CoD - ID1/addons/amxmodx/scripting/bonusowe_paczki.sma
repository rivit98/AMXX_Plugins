#include <amxmodx>
#include <cstrike>
#include <codmod>
#include fakemeta_util
#include engine

#define WYTRZYMALOSC_PERKU                // jesli chcesz wylaczyc wytrzymalosc perku to przed ta linijka daj // (WAZNE!! jezeli wylaczysz wytrzymalosc perku to zajrzyj takze do QTM_CodMod.sma i aukcje_cod.sma !!)

new const modelitem[] = "models/QTM_CodMod/cod_paczka.mdl";
new const prefix[] = "^4[BONUS]^1"

new const max_clip[31] = { -1, 13, -1, 10,  1,  7,  1,  30, 30,  1,  30,  20,  25, 30, 35, 25,  12,  20, 10,  30, 100,  8, 30,  30, 20,  2,  7, 30, 30, -1,  50 };

public plugin_init()
{
	register_plugin("Bonusowe paczki", "1.2", "RiviT")
	
	register_touch("paczka", "player", "fwd_touch")

	register_event("DeathMsg", "DeathMsg", "a")
}

public plugin_precache()
	precache_model(modelitem)

public DeathMsg()
{
	static entit, Float:origins[3]

	entit = create_entity("info_target");

	entity_set_string(entit, EV_SZ_classname, "paczka");
	entity_set_model(entit, modelitem);

	pev(read_data(2), pev_origin, origins);
	origins[0] += 10.0;
	set_pev(entit, pev_origin, origins)
	set_pev(entit, pev_solid, SOLID_TRIGGER); 
	set_pev(entit, pev_movetype, MOVETYPE_TOSS);
	engfunc(EngFunc_SetSize,entit, {-1.1, -1.1, -1.1}, {1.1, 1.1, 1.1} );
}

UzyjPaczki(id)
{
	switch(random(9))
	{
		case 0:
		{
			if(!cod_get_user_perk(id))
			{
				UzyjPaczki(id)
				return;
			}
		
			cod_set_user_perk(id, 0, -1, 1);
			client_print_color(id, print_team_red, "%s Straciles perk!", prefix)
		}
		case 1:
		{
			new losowehp = random_num(1, 30);
			fm_set_user_health(id, get_user_health(id)-losowehp)
			client_print_color(id, print_team_red, "%s Znalazles trucizne. Tracisz^3 %i HP", prefix, losowehp)
		}
		case 2:
		{
			new losowehp = random_num(1, 40);
			fm_set_user_health(id, get_user_health(id)+losowehp)
			client_print_color(id, print_team_red, "%s Znalazles apteczke. Dostales^3 %i HP", prefix, losowehp)
		}
		case 3:
		{
			new losowakasa = random_num(100, 2000);
			cs_set_user_money(id, min(cs_get_user_money(id)+losowakasa, 16000))
			client_print_color(id, print_team_red, "%s Znalazles sakiewke. Dostales^3 %i$", prefix, losowakasa)
		}
		case 4:
		{
			if(cod_get_user_perk(id))
			{
				UzyjPaczki(id)
				return;
			}
			
			new perk[64]
			cod_set_user_perk(id, -1, -1, 0);
			cod_get_perk_name(cod_get_user_perk(id), perk, 63)
			client_print_color(id, print_team_red, "%s Znalazles perk:^3 %s", prefix, perk)
		}
		case 5:
		{
			new losowyexp = random_num(1, 250);
			cod_add_user_xp(id, losowyexp);
			client_print_color(id, print_team_red, "%s Dostales^3 %i EXP'a", prefix, losowyexp)
		}
		case 6:
		{
			#if defined WYTRZYMALOSC_PERKU
			if(!cod_get_user_perk(id))
			{
				UzyjPaczki(id)
				return;
			}
			
			cod_set_perk_durability(id, 100)
			client_print_color(id, print_team_red, "%s Dostales^3 max wytrzymalosci perku!", prefix)
			#else
			UzyjPaczki(id)
			#endif
		}
		case 7:
		{
			new index = get_user_weapon(id)
			if(index == CSW_KNIFE)
			{
				UzyjPaczki(id)
				return;
			}
			
			cs_set_user_bpammo(id, index, cs_get_user_bpammo(id, index)+max_clip[index])
			client_print_color(id, print_team_red, "%s Dostales^3 %i ammo^1 do obecnej broni!", prefix, max_clip[index]);
		}
		case 8:
		{
			if(!cod_get_user_clan(id))
			{
				UzyjPaczki(id)
				return;
			}
			
			new ile = random_num(1, 3)
			cod_add_user_clan_gold(id, ile)
			client_print_color(id, print_team_red, "%s Znalazles^3 %i zlota^1 dla klanu!", prefix, ile)
		}
	}
}

public fwd_touch(ent, id)
{
	if(!is_user_alive(id)) return;
	
	remove_entity(ent)
	UzyjPaczki(id)
}