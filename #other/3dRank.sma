#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < csx >

#define PLUGIN "3D Rank"
#define VERSION "0.4"
#define AUTHOR "TibacK"

#define FLAG ADMIN_KICK

new const gsz_RankModel [ ] = "models/3dranks.mdl"

new gp_AdminRank
new gp_BotRank

new gi_PlayerRank [ 33 ]

public plugin_init ( )
{
	register_plugin ( PLUGIN, VERSION, AUTHOR )
	
	RegisterHam ( Ham_Killed, "player", "player_killed", 1 )
	RegisterHam ( Ham_Spawn, "player", "player_spawned", 1 )
	
	gp_AdminRank = register_cvar ( "3drank_admin", "0" )
	gp_BotRank = register_cvar ( "3drank_bot", "0" )
}

public plugin_precache ( )
{
	precache_model ( gsz_RankModel )
}

public client_putinserver ( index )
{
	create_rank_entity ( index )
}

public client_disconnect ( index )
{
	if ( gi_PlayerRank [ index ] > 0 )
		engfunc ( EngFunc_RemoveEntity, gi_PlayerRank [ index ] )
	
	gi_PlayerRank [ index ] = 0
}

public create_rank_entity ( index )
{
	gi_PlayerRank [ index ] = engfunc ( EngFunc_CreateNamedEntity, engfunc ( EngFunc_AllocString, "info_target" ) )
	
	set_pev ( gi_PlayerRank [ index ], pev_movetype, MOVETYPE_FOLLOW )
	set_pev ( gi_PlayerRank [ index ], pev_aiment, index )
	set_pev ( gi_PlayerRank [ index ], pev_rendermode, kRenderNormal )
	set_pev ( gi_PlayerRank [ index ], pev_renderfx, kRenderFxGlowShell )
	set_pev ( gi_PlayerRank [ index ], pev_renderamt, 5.0 )
	
	engfunc ( EngFunc_SetModel, gi_PlayerRank [ index ], gsz_RankModel )
}

public player_killed ( victim, attacker, gid )
{
	if ( is_valid_player ( attacker ) )
	{
		check_rank ( attacker )
	}
}

public player_spawned ( spawned )
{
	if ( is_valid_player ( spawned ) )
	{
		check_rank ( spawned )
	}
}

public check_rank ( index )
{
	new PlayerRank = get_player_rank ( index )
	
	set_pev ( gi_PlayerRank [ index ], pev_body, PlayerRank )
	
	switch ( PlayerRank )
	{
		case 1, 2, 3:
		{
			set_pev ( gi_PlayerRank [ index ], pev_rendercolor, { 255.0, 255.0, 255.0 } )
		}
		
		case 12:
		{
			set_pev ( gi_PlayerRank [ index ], pev_rendercolor, { 255.0, 0.0, 0.0 } )
		}
		
		default:
		{
			set_pev ( gi_PlayerRank [ index ], pev_rendercolor, { 255.0, 255.0, 0.0 } )
		}
	}
}

stock get_player_rank ( index )
{
	if ( get_pcvar_num ( gp_AdminRank ) && get_user_flags ( index ) & FLAG )
	{
		return 11
	}
	
	if ( get_pcvar_num ( gp_BotRank ) && is_user_bot ( index ) )
	{
		return 12
	}

	static stats[8], body[8];
	get_user_stats(index, stats, body);

	new PlayerFrags = stats[0];
	
	switch ( PlayerFrags )
	{
		case 0..5:
		{
			return 1
		}
		
		case 6..11:
		{
			return 2
		}
		
		case 12..18:
		{
			return 3
		}
		
		case 19..26:
		{
			return 4
		}
		
		case 27..35:
		{
			return 5
		}
		
		case 36..45:
		{
			return 6
		}
		
		case 46..56:
		{
			return 7
		}
		
		case 57..68:
		{
			return 8
		}
		
		case 69..81:
		{
			return 9
		}
		
		default:
		{
			return 10
		}
	}
	
	return 0
}

stock is_valid_player ( index )
{
	if ( is_user_connected ( index ) && 1 <= index <= 32 )
	{
		return true
	}
	
	return false
}
