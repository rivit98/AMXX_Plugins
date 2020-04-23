/*
*		Jailbreak Klan System
*		H3avY Ra1n
*
*		Description
*		-----------
*		This plugin allows prisoners to create Klans and upgrade specific skills that apply to everybody in the Klan.
*
*
*		Klan Menu
*		---------
*		Create a Klan 		- Allows a user to create a Klan by paying money.
*		Invite to Klan 		- Only the leader of the Klan can invite people to the Klan.
*		Skills 				- Opens the skills menu, where any member of the Klan can pay money to upgrade their skills.
*		Top-10 				- Shows a MOTD with the top10 Klans, SORTED BY KILLS. (If you have a good way to sort it, please post it below)
*		Leave Klan 			- Allows a player to leave the Klan. The leader cannot leave the Klan until he transfers leadership to somebody else (explained later).
*		Klan Leader Menu 	- Shows a menu with options to disband the Klan, kick a player from the Klan, or transfer leadership to somebody else in the Klan.
*		Online Members 		- Shows a list of Klan members that are currently in the server.
*
*
*		Skills
*		------
*		HP - Increased health
*		Stealing - Increased money earnings.
*		Gravity - Lower Gravity
*		Damage - Increased damage
*		Stamina - Gives higher speed to players.
*		Weapon Drop - Chance of making the guard drop the weapon when you knife them. (%1 chance increase per level)
*
*
*		CVARS
*		-----
*		cod_Klan_cost 		- The cost to create a Klan.
*		cod_health_cost 		- The cost to upgrade Klan health.
*		cod_stealing_cost 	- The cost to upgrade Klan money earning.
*		cod_gravity_cost 	- The cost to upgrade Klan gravity.
*		cod_damage_cost 		- The cost to upgrade Klan damage.
*		cod_stamina_cost 	- The cost to upgrade Klan stamina (speed).
*		cod_weapondrop_cost 	- The cost to upgrade Klan weapon drop percentage.
*
*		Additionally there are CVars for the max level for each type of upgrade, so replace _cost above with _max.
*		Also there are CVars for the amount per level, so replace _cost above with _per.
*
*		Credits
*		-------
*		F0RCE 	- Original Plugin Idea - Beta testing
*		Exolent	- SQLVault Include
*
*
*		Changelog
*		---------
*		September 26, 2011	- v1.0 - 	Initial Release
*		September 27, 2011	- v1.01 - 	Added more cvars, fixed a few bugs.
*
*
*		http://forums.alliedmods.net/showthread.php?p=1563919
*/

#include < amxmodx >
#include < amxmisc >
#include < sqlvault_ex >
#include < cstrike >
#include < colorchat >
#include < hamsandwich >
#include < fun >

new const g_szVersion[ ] = "1.01";

enum _:KlanInfo
{
	Trie:KlanMembers,
	KlanName[ 60 ],
	KlanHP,
	KlanStealing,
	KlanGravity,
	KlanDamage,
	KlanStamina,
	KlanWeaponDrop,
	KlanKills
};
	
enum
{
	VALUE_HP,
	VALUE_STEALING,
	VALUE_GRAVITY,
	VALUE_DAMAGE,
	VALUE_STAMINA,
	VALUE_WEAPONDROP,
	VALUE_KILLS
}

new const g_szKlanValues[ ][ ] = 
{
	"HP",
	"Stealing",
	"Gravity",
	"Damage",
	"Stamina",
	"WeaponDrop",
	"Kills"
};

new const g_szPrefix[ ] = "^04[Klan System]^01";

new Trie:g_tKlanNames;
new Trie:g_tKlanValues;

new SQLVault:g_hVault;

new Array:g_aKlans;

new g_pCreateCost;

new g_pHealthCost;
new g_pStealingCost;
new g_pGravityCost;
new g_pDamageCost;
new g_pStaminaCost;
new g_pWeaponDropCost;

new g_pHealthMax;
new g_pStealingMax;
new g_pGravityMax;
new g_pDamageMax;
new g_pStaminaMax;
new g_pWeaponDropMax;

new g_pHealthPerLevel;
new g_pStealingPerLevel;
new g_pGravityPerLevel;
new g_pDamagePerLevel;
new g_pStaminaPerLevel;
new g_pWeaponDropPerLevel;

new g_iKlan[ 33 ];
new g_iLastMoney[ 33 ];

public plugin_init()
{
	register_plugin( "Jailbreak Klan System", g_szVersion, "H3avY Ra1n" );
	
	g_aKlans 				= ArrayCreate( KlanInfo );

	g_tKlanValues 			= TrieCreate();
	g_tKlanNames 			= TrieCreate();
	
	g_hVault 				= sqlv_open_local( "cod_Klans", false );
	sqlv_init_ex( g_hVault );

	g_pCreateCost			= register_cvar( "cod_Klan_cost", 		"12000" );
	g_pHealthCost			= register_cvar( "cod_health_cost", 		"9000" );
	g_pStealingCost 		= register_cvar( "cod_stealing_cost", 	"5000" );
	g_pGravityCost			= register_cvar( "cod_gravity_cost", 	"8000" );
	g_pDamageCost			= register_cvar( "cod_damage_cost", 		"3000" );
	g_pStaminaCost			= register_cvar( "cod_stamina_cost", 	"5000" );
	g_pWeaponDropCost		= register_cvar( "cod_weapondrop_cost", 	"10000" );

	g_pHealthMax			= register_cvar( "cod_health_max", 		"20" );
	g_pStealingMax			= register_cvar( "cod_stealing_max", 	"20" );
	g_pGravityMax			= register_cvar( "cod_gravity_max", 		"20" ); // Max * Gravity must be LESS than 800
	g_pDamageMax			= register_cvar( "cod_damage_max", 		"20" );
	g_pStaminaMax			= register_cvar( "cod_stamina_max", 		"20" );
	g_pWeaponDropMax		= register_cvar( "cod_weapondrop_max", 	"20" );

	g_pHealthPerLevel		= register_cvar( "cod_health_per", 	"20" );
	g_pStealingPerLevel		= register_cvar( "cod_stealing_per", 	"0.05" );
	g_pGravityPerLevel		= register_cvar( "cod_gravity_per", 		"50" );
	g_pDamagePerLevel		= register_cvar( "cod_damage_per", 		"3" );
	g_pStaminaPerLevel		= register_cvar( "cod_stamina_per", 		"3" );
	g_pWeaponDropPerLevel 	= register_cvar( "cod_weapondrop_per", 	"1" );

	register_cvar( "cod_Klan_version", g_szVersion, FCVAR_SPONLY | FCVAR_SERVER );
	
	register_menu( "Klan Menu", 1023, "KlanMenu_Handler" );
	register_menu( "Skills Menu", 1023, "SkillsMenu_Handler" );
	
	for( new i = 5; i < sizeof g_szKlanValues; i++ )
	{
		TrieSetCell( g_tKlanValues, g_szKlanValues[ i ], i );
	}

	RegisterHam( Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1 );
	RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Pre", 0 );
	RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Post", 1 );
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	register_event( "CurWeapon", "Event_CurWeapon", "be" );
	register_event( "Money", "Event_Money", "b" );
	
	register_clcmd( "say /Klan", "Cmd_Klan" );
	register_clcmd( "say /Klany", "Cmd_Klan" );
	register_clcmd( "Klan_name", "Cmd_CreateKlan" );
	
	LoadKlans();
}

public client_disconnect( id )
{
	g_iKlan[ id ] = -1;
}

public client_putinserver( id )
{
	g_iKlan[ id ] = get_user_Klan( id );
}

public plugin_end()
{
	SaveKlans();
	sqlv_close( g_hVault );
}

public Ham_PlayerSpawn_Post( id )
{
	if( !is_user_alive( id ) || cs_get_user_team( id ) != CS_TEAM_T )
		if( !is_user_alive( id ) || cs_get_user_team( id ) != CS_TEAM_CT )
		return HAM_IGNORED;
		
	if( g_iKlan[ id ] == -1 )
	{
		return HAM_IGNORED;
	}
		
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
	
	new iHealth = 100 + aData[ KlanHP ] * get_pcvar_num( g_pHealthPerLevel );
	set_user_health( id, iHealth );
	
	new iGravity = 800 - ( get_pcvar_num( g_pGravityPerLevel ) * aData[ KlanGravity ] );
	set_user_gravity( id, float( iGravity ) / 800.0 );
	
	if( aData[ KlanStamina ] > 0 )
		set_user_maxspeed( id, 250.0 + ( aData[ KlanStamina ] * get_pcvar_num( g_pStaminaPerLevel ) ) );
		
	return HAM_IGNORED;
}

public Ham_TakeDamage_Pre( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
{
	if( !is_user_alive( iAttacker ) || cs_get_user_team( iAttacker ) != CS_TEAM_T )
		if( !is_user_alive( iAttacker ) || cs_get_user_team( iAttacker ) != CS_TEAM_CT )
		return HAM_IGNORED;
		
	if( g_iKlan[ iAttacker ] == -1 )
		return HAM_IGNORED;
	
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, g_iKlan[ iAttacker ], aData );
	
	SetHamParamFloat( 4, flDamage + ( get_pcvar_num( g_pDamagePerLevel ) * ( aData[ KlanDamage ] ) ) );
	
	return HAM_IGNORED;
}

public Ham_TakeDamage_Post( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
{
	if( !is_user_alive( iAttacker ) || g_iKlan[ iAttacker ] == -1 || get_user_weapon( iAttacker ) != CSW_KNIFE || cs_get_user_team( iAttacker ) != CS_TEAM_T  )
	{
		return HAM_IGNORED;
	}
	
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, g_iKlan[ iAttacker ], aData );
	
	new iChance = aData[ KlanWeaponDrop ] * get_pcvar_num( g_pWeaponDropPerLevel );
	
	if( iChance == 0 )
		return HAM_IGNORED;
	
	new bool:bDrop = ( random_num( 1, 100 ) <= iChance );
	
	if( bDrop )
		client_cmd( iVictim, "drop" );
	
	return HAM_IGNORED;
}

public Event_CurWeapon( id )
{
	if( g_iKlan[ id ] == -1 || cs_get_user_team( id ) != CS_TEAM_T )
	if( g_iKlan[ id ] == -1 || cs_get_user_team( id ) != CS_TEAM_CT )
	{
		return PLUGIN_CONTINUE;
	}
	
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
	
	if( aData[ KlanStamina ] > 0 )
		set_user_maxspeed( id, 250.0 + ( aData[ KlanStamina ] * get_pcvar_num( g_pStaminaPerLevel ) ) );
		
	return PLUGIN_CONTINUE;
}

public Event_DeathMsg()
{
	new iKiller = read_data( 1 );
	new iVictim = read_data( 2 );
	
	if( !is_user_alive( iKiller ) || cs_get_user_team( iVictim ) != CS_TEAM_CT || g_iKlan[ iKiller ] == -1 || cs_get_user_team( iKiller ) != CS_TEAM_T )
		return PLUGIN_CONTINUE;
	
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, g_iKlan[ iKiller ], aData );
	aData[ KlanKills ]++;
	ArraySetArray( g_aKlans, g_iKlan[ iKiller ], aData );
	
	return PLUGIN_CONTINUE;
}

public Event_Money( id )
{
	new iAmount = read_data( 1 );
	
	new iDiff = iAmount - g_iLastMoney[ id ];
	
	g_iLastMoney[ id ] = iAmount;
	
	if( iAmount <= 0 )
		return;
	
	if( g_iKlan[ id ] > -1 )
	{
		static aData[ KlanInfo ];
		ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
		
		iDiff = floatround( iDiff * ( aData[ KlanStealing ] * get_pcvar_float( g_pStealingPerLevel ) ) );
		
		cs_set_user_money( id, iAmount + iDiff, 0 );
	}
}

public Cmd_Klan( id )
{	
	if( !is_user_connected( id ) || cs_get_user_team( id ) != CS_TEAM_T )
		if( !is_user_connected( id ) || cs_get_user_team( id ) != CS_TEAM_CT )
	{
		ColorChat( id, NORMAL, "%s Only ^03prisoners ^01can access this menu.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	static szMenu[ 512 ], iLen, aData[ KlanInfo ], iKeys, bool:bLeader;
	
	iKeys = MENU_KEY_0 | MENU_KEY_4;
	
	bLeader = isLeader( id, g_iKlan[ id ] );
	
	if( g_iKlan[ id ] > -1 )
	{
		ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
		iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "\yMenu Klanu^n\wAktualny Klan:\y %s^n^n", aData[ KlanName ] );
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r1. \dStworz Klan [$%i]^n", get_pcvar_num( g_pCreateCost ) );
	}
	
	else
	{
		iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "\yMenu Klanu^n\wAktualny Klan:\r None^n^n" );
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r1. \wStworz Klan [$%i]^n", get_pcvar_num( g_pCreateCost ) );
		
		iKeys |= MENU_KEY_1;
	}
	
	
	if( bLeader && g_iKlan[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r2. \wZapros gracza do Klanu^n" );
		iKeys |= MENU_KEY_2;
	}
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r2. \dZapros gracza do Klanu^n" );
	
	if( g_iKlan[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r3. \wUmiejetnosci^n" );
		iKeys |= MENU_KEY_3;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r3. \dUmiejetnosci^n" );
		
	iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r4. \wTop-10^n" );
	
	if( g_iKlan[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r5. \wOpusc Klan^n" );
		iKeys |= MENU_KEY_5;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r5. \dOpusc Klan^n" );
	
	
	if( bLeader )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r6. \wMenu Leadera Klanu^n" );
		iKeys |= MENU_KEY_6;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r6. \dMenu Leadera Klanu^n" );
	
	if( g_iKlan[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r7. \wCzlonkowie online^n" );
		iKeys |= MENU_KEY_7;
	}
		
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r7. \dCzlonkowie online^n" );
	
	iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "^n\r0. \wWyjscie" );
	
	show_menu( id, iKeys, szMenu, -1, "Klan Menu" );
	
	return PLUGIN_CONTINUE;
}

public KlanMenu_Handler( id, iKey )
{
	switch( ( iKey + 1 ) % 10 )
	{
		case 0: return PLUGIN_HANDLED;
		
		case 1: 
		{
			if( cs_get_user_money( id ) < get_pcvar_num( g_pCreateCost ) )
			{
				ColorChat( id, NORMAL, "%s Nie masz wystarczajaco pieniedzy aby utworzyc Klan!", g_szPrefix );
				return PLUGIN_HANDLED;
			}
			
			client_cmd( id, "messagemode Klan_name" );
		}
		
		case 2:
		{
			ShowInviteMenu( id );
		}
		
		case 3:
		{
			ShowSkillsMenu( id );
		}
		
		case 4:
		{
			Cmd_Top10( id );
		}
		
		case 5:
		{
			ShowLeaveConfirmMenu( id );
		}
		
		case 6:
		{
			ShowLeaderMenu( id );
		}
		
		case 7:
		{
			ShowMembersMenu( id );
		}
	}
	
	return PLUGIN_HANDLED;
}

public Cmd_CreateKlan( id )
{
	if( cs_get_user_money( id ) < get_pcvar_num( g_pCreateCost ) )
	{
		ColorChat( id, NORMAL, "%s Nie masz wystarczajaco pieniedzy aby utworzyc Klan.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else if( g_iKlan[ id ] > -1 )
	{
		ColorChat( id, NORMAL, "%s Nie mozesz stworzyc Klanu poniewaz jestes juz w Klanu!!", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	new szArgs[ 60 ];
	read_args( szArgs, charsmax( szArgs ) );
	
	remove_quotes( szArgs );
	
	if( TrieKeyExists( g_tKlanNames, szArgs ) )
	{
		ColorChat( id, NORMAL, "%s Klan z taka nazwa juz istnieje.", g_szPrefix );
		Cmd_Klan( id );
		return PLUGIN_HANDLED;
	}
	
	new aData[ KlanInfo ];
	
	aData[ KlanName ] 		= szArgs;
	aData[ KlanHP ] 		= 0;
	aData[ KlanStealing ] 	= 0;
	aData[ KlanGravity ] 	= 0;
	aData[ KlanStamina ] 	= 0;
	aData[ KlanWeaponDrop ] = 0;
	aData[ KlanDamage ] 	= 0;
	aData[ KlanMembers ] 	= _:TrieCreate();
	
	ArrayPushArray( g_aKlans, aData );
	
	cs_set_user_money( id, cs_get_user_money( id ) - get_pcvar_num( g_pCreateCost ) );
	
	set_user_Klan( id, ArraySize( g_aKlans ) - 1, true );
	
	ColorChat( id, NORMAL, "%s Stworzyles Klan '^03%s^01'.", g_szPrefix, szArgs );
	
	return PLUGIN_HANDLED;
}

public ShowInviteMenu( id )
{	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new szInfo[ 6 ], hMenu;
	hMenu = menu_create( "Wybierz gracza z listy:", "InviteMenu_Handler" );
	new szName[ 32 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		
		if( iPlayer == id || g_iKlan[ iPlayer ] == g_iKlan[ id ] || cs_get_user_team( iPlayer ) != CS_TEAM_T )
		if( iPlayer == id || g_iKlan[ iPlayer ] == g_iKlan[ id ] || cs_get_user_team( iPlayer ) != CS_TEAM_CT )
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		num_to_str( iPlayer, szInfo, charsmax( szInfo ) );
		
		menu_additem( hMenu, szName, szInfo );
	}
		
	menu_display( id, hMenu, 0 );
}

public InviteMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		Cmd_Klan( id );
		return PLUGIN_HANDLED;
	}
	
	new szData[ 6 ], iAccess, hCallback, szName[ 32 ];
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, 31, hCallback );
	
	new iPlayer = str_to_num( szData );

	if( !is_user_connected( iPlayer ) )
		return PLUGIN_HANDLED;
		
	ShowInviteConfirmMenu( id, iPlayer );

	ColorChat( id, NORMAL, "%s Zaprosiles %s do swojego Klanu.", g_szPrefix, szName );
	
	Cmd_Klan( id );
	return PLUGIN_HANDLED;
}

public ShowInviteConfirmMenu( id, iPlayer )
{
	new szName[ 32 ];
	get_user_name( id, szName, charsmax( szName ) );
	
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
	
	new szMenuTitle[ 128 ];
	formatex( szMenuTitle, charsmax( szMenuTitle ), "%s Zaprosil Cie abys dolaczyl do	%s", szName, aData[ KlanName ] );
	new hMenu = menu_create( szMenuTitle, "InviteConfirmMenu_Handler" );
	
	new szInfo[ 6 ];
	num_to_str( g_iKlan[ id ], szInfo, 5 );
	
	menu_additem( hMenu, "Zakceptuj", szInfo );
	menu_additem( hMenu, "Odrzuc", "-1" );
	
	menu_display( iPlayer, hMenu, 0 );	
}

public InviteConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	new iKlan = str_to_num( szData );
	
	if( iKlan == -1 )
		return PLUGIN_HANDLED;
	
	if( isLeader( id, g_iKlan[ id ] ) )
	{
		ColorChat( id, NORMAL, "%s Nie mozesz opuscic Klanu kiedy jestes leaderem.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	set_user_Klan( id, iKlan );
	
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, iKlan, aData );
	
	ColorChat( id, NORMAL, "%s Dolaczyles do Klanu ^03%s^01.", g_szPrefix, aData[ KlanName ] );
	
	return PLUGIN_HANDLED;
}
	

public ShowSkillsMenu( id )
{	
	static szMenu[ 512 ], iLen, iKeys, aData[ KlanInfo ];
	
	if( !iKeys )
	{
		iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_0;
	}
	
	ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
	
	iLen	=	formatex( szMenu, charsmax( szMenu ), "\yMenu Umiejetnosci^n^n" );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r1. \wSilownia [\rKoszt: \y$%i\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pHealthCost ), aData[ KlanHP ], get_pcvar_num( g_pHealthMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r2. \wKradziez [\rKoszt: \y$%i\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pStealingCost ), aData[ KlanStealing ], get_pcvar_num( g_pStealingMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r3. \wGrawitacja [\rKoszt: \y$%i\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pGravityCost ), aData[ KlanGravity ], get_pcvar_num( g_pGravityMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r4. \wObrazenia [\rKoszt: \y$%i\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pDamageCost ), aData[ KlanDamage ], get_pcvar_num( g_pDamageMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r5. \wObezwladnienie [\rKoszt: \y$%i\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pWeaponDropCost ), aData[ KlanWeaponDrop ], get_pcvar_num( g_pWeaponDropMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r6. \wSpeed [\rKoszt: \y$%i\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pStaminaCost ), aData[ KlanStamina ], get_pcvar_num( g_pStaminaMax ) );
	
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "^n\r0. \wExit" );
	
	show_menu( id, iKeys, szMenu, -1, "Skills Menu" );
}

public SkillsMenu_Handler( id, iKey )
{
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
	
	switch( ( iKey + 1 ) % 10 )
	{
		case 0: 
		{
			Cmd_Klan( id );
			return PLUGIN_HANDLED;
		}
		
		case 1:
		{
			if( aData[ KlanHP ] == get_pcvar_num( g_pHealthMax ) )
			{
				ColorChat( id, NORMAL, "%s Twoj Klan posiada maksymalny poziom tej umiejêtnosci.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = cs_get_user_money( id ) - get_pcvar_num( g_pHealthCost );
			
			if( iRemaining < 0 )
			{
				ColorChat( id, NORMAL, "%s Nie masz na to pieniedzy.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ KlanHP ]++;
			
			cs_set_user_money( id, iRemaining );
		}
		
		case 2:
		{
			if( aData[ KlanStealing ] == get_pcvar_num( g_pStealingMax ) )
			{
				ColorChat( id, NORMAL, "%s Twoj Klan posiada maksymalny poziom tej umiejêtnosci.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = cs_get_user_money( id ) - get_pcvar_num( g_pStealingCost );
			
			if( iRemaining < 0 )
			{
				ColorChat( id, NORMAL, "%s Nie masz na to pieniedzy.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ KlanStealing ]++;
			
			cs_set_user_money( id, iRemaining );
		}
		
		case 3:
		{
			if( aData[ KlanGravity ] == get_pcvar_num( g_pGravityMax ) )
			{
				ColorChat( id, NORMAL, "%s Twoj Klan posiada maksymalny poziom tej umiejêtnosci.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = cs_get_user_money( id ) - get_pcvar_num( g_pGravityCost );
			
			if( iRemaining < 0 )
			{
				ColorChat( id, NORMAL, "%s Nie masz na to pieniedzy.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ KlanGravity ]++;
			
			cs_set_user_money( id, iRemaining );
		}
		
		case 4:
		{
			if( aData[ KlanDamage ] == get_pcvar_num( g_pDamageMax ) )
			{
				ColorChat( id, NORMAL, "%s Twoj Klan posiada maksymalny poziom tej umiejêtnosci.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = cs_get_user_money( id ) - get_pcvar_num( g_pDamageCost );
			
			if( iRemaining < 0 )
			{
				ColorChat( id, NORMAL, "%s Nie masz na to pieniedzy.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ KlanDamage ]++;
			
			cs_set_user_money( id, iRemaining );
		}
		
		case 5:
		{
			if( aData[ KlanWeaponDrop ] == get_pcvar_num( g_pWeaponDropMax ) )
			{
				ColorChat( id, NORMAL, "%s Twoj Klan posiada maksymalny poziom tej umiejêtnosci.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = cs_get_user_money( id ) - get_pcvar_num( g_pWeaponDropCost );
			
			if( iRemaining < 0 )
			{
				ColorChat( id, NORMAL, "%s Nie masz na to pieniedzy.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ KlanWeaponDrop ]++;
			
			cs_set_user_money( id, iRemaining );
		}
		
		case 6:
		{
			if( aData[ KlanStamina ] == get_pcvar_num( g_pStaminaMax ) )
			{
				ColorChat( id, NORMAL, "%s Twoj Klan posiada maksymalny poziom tej umiejêtnosci.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = cs_get_user_money( id ) - get_pcvar_num( g_pStaminaCost );
			
			if( iRemaining < 0 )
			{
				ColorChat( id, NORMAL, "%s Nie masz na to pieniedzy.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ KlanStamina ]++;
			
			cs_set_user_money( id, iRemaining );
		}
	}
	
	ArraySetArray( g_aKlans, g_iKlan[ id ], aData );
	
	new szAuthID[ 35 ];
	new iPlayers[ 32 ], iNum, iPlayer;
	new szName[ 32 ];
	get_players( iPlayers, iNum, "e" );
	
	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( iPlayer == id )
			continue;
			
		get_user_authid( iPlayer, szAuthID, charsmax( szAuthID ) );
		
		if( TrieKeyExists( aData[ KlanMembers ], szAuthID ) )
		{
			ColorChat( iPlayer, NORMAL, "%s ^03%s ^01ulepszyl jedna z umiejetnosc Twojego Klanu.", g_szPrefix, szName );
		}
	}
	
	ColorChat( id, NORMAL, "%s Ulepszyles swoj Klan.", g_szPrefix );
	
	ShowSkillsMenu( id );
	
	return PLUGIN_HANDLED;
}
		
	
public Cmd_Top10( id )
{
	new iSize = ArraySize( g_aKlans );
	
	new iOrder[ 100 ][ 2 ];
	
	new aData[ KlanInfo ];
	
	for( new i = 0; i < iSize; i++ )
	{
		ArrayGetArray( g_aKlans, i, aData );
		
		iOrder[ i ][ 0 ] = i;
		iOrder[ i ][ 1 ] = aData[ KlanKills ];
	}
	
	SortCustom2D( iOrder, iSize, "Top10_Sort" );
	
	new szMessage[ 2048 ];
	formatex( szMessage, charsmax( szMessage ), "<body bgcolor=#000000><font color=#FFB000><pre>" );
	format( szMessage, charsmax( szMessage ), "%s%2s %-22.22s %7s %4s %10s %9s %9s %11s %8s^n", szMessage, "#", "Nazwa", "Zabojstwa", "Silownia", "Kradziez", 
		"Grawitacja", "Speed", "DropBroni", "Atak" );
		
	for( new i = 0; i < min( 10, iSize ); i++ )
	{
		ArrayGetArray( g_aKlans, iOrder[ i ][ 0 ], aData );
		
		format( szMessage, charsmax( szMessage ), "%s%-2d %22.22s %7d %4d %10d %9d %9d %11d %8d^n", szMessage, i + 1, aData[ KlanName ], 
		aData[ KlanKills ], aData[ KlanHP ], aData[ KlanStealing ], aData[ KlanGravity ], aData[ KlanStamina], aData[ KlanWeaponDrop ], aData[ KlanDamage ] );
	}
	
	show_motd( id, szMessage, "Klan Top 10" );
}

public Top10_Sort( const iElement1[ ], const iElement2[ ], const iArray[ ], szData[], iSize ) 
{
	if( iElement1[ 1 ] > iElement2[ 1 ] )
		return -1;
	
	else if( iElement1[ 1 ] < iElement2[ 1 ] )
		return 1;
	
	return 0;
}

public ShowLeaveConfirmMenu( id )
{
	new hMenu = menu_create( "Czy napewno chcesz opuscic Klan?", "LeaveConfirmMenu_Handler" );
	menu_additem( hMenu, "Tak, Opusc teraz", "0" );
	menu_additem( hMenu, "Nie, Pozostan", "1" );
	
	menu_display( id, hMenu, 0 );
}

public LeaveConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0: 
		{
			if( isLeader( id, g_iKlan[ id ] ) )
			{
				ColorChat( id, NORMAL, "%s Musisz przeniesc przywodztwo.", g_szPrefix );
				Cmd_Klan( id );
				
				return PLUGIN_HANDLED;
			}
			
			ColorChat( id, NORMAL, "%s Opusciles swoj Klan.", g_szPrefix );
			set_user_Klan( id, -1 );
			Cmd_Klan( id );
		}
		
		case 1: Cmd_Klan( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowLeaderMenu( id )
{
	new hMenu = menu_create( "Menu Leadera Klanu", "LeaderMenu_Handler" );
	menu_additem( hMenu, "Usun Klan", "0" );
	menu_additem( hMenu, "Przenies przywodztwo", "1" );
	menu_additem( hMenu, "Usun z Klanu", "2" );
	
	menu_display( id, hMenu, 0 );
}

public LeaderMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		Cmd_Klan( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ];
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0:
		{
			ShowDisbandConfirmMenu( id );
		}
		
		case 1:
		{
			ShowTransferMenu( id );
		}
		
		case 2:
		{
			ShowKickMenu( id );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ShowDisbandConfirmMenu( id )
{
	new hMenu = menu_create( "Jestes pewien ze chcesz usunac Klan?", "DisbandConfirmMenu_Handler" );
	menu_additem( hMenu, "Tak, Usun teraz", "0" );
	menu_additem( hMenu, "Nie, Nie usuwaj", "1" );
	
	menu_display( id, hMenu, 0 );
}

public DisbandConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0: 
		{
			
			ColorChat( id, NORMAL, "%s Usunales swoj Klan!", g_szPrefix );
			
			new iPlayers[ 32 ], iNum;
			
			get_players( iPlayers, iNum );
			
			new iPlayer;
			
			for( new i = 0; i < iNum; i++ )
			{
				iPlayer = iPlayers[ i ];
				
				if( iPlayer == id )
					continue;
				
				if( g_iKlan[ id ] != g_iKlan[ iPlayer ] )
					continue;

				ColorChat( iPlayer, NORMAL, "%s Twoj Klan zostal usuniety przez leadera!.", g_szPrefix );
				set_user_Klan( iPlayer, -1 );
			}
			
			new iKlan = g_iKlan[ id ];
			
			set_user_Klan( id, -1 );
			
			ArrayDeleteItem( g_aKlans, iKlan );

			Cmd_Klan( id );
		}
		
		case 1: Cmd_Klan( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowTransferMenu( id )
{
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "e", "TERRORIST" );
	
	new hMenu = menu_create( "Oddaj przywodztwo:", "TransferMenu_Handler" );
	new szName[ 32 ], szData[ 6 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iKlan[ iPlayer ] != g_iKlan[ id ] || id == iPlayer )
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public TransferMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
	
	new iPlayer = str_to_num( szData );
	
	if( !is_user_connected( iPlayer ) )
	{
		ColorChat( id, NORMAL, "%s Ten gracz nie jest juz polaczony.", g_szPrefix );
		ShowTransferMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_Klan( iPlayer, g_iKlan[ id ], true );
	set_user_Klan( id, g_iKlan[ id ], false );
	
	Cmd_Klan( id );
	
	new iPlayers[ 32 ], iNum, iTemp;
	get_players( iPlayers, iNum );

	for( new i = 0; i < iNum; i++ )
	{
		iTemp = iPlayers[ i ];
		
		if( iTemp == iPlayer )
		{
			ColorChat( iTemp, NORMAL, "%s Jestes nowym leaderem tego Klanu.", g_szPrefix );
			continue;
		}
		
		else if( g_iKlan[ iTemp ] != g_iKlan[ id ] )
			continue;
		
		ColorChat( iTemp, NORMAL, "%s ^03%s^01 zostal nowym leaderem Klanu.", g_szPrefix, szName );
	}
	
	return PLUGIN_HANDLED;
}


public ShowKickMenu( id )
{
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new hMenu = menu_create( "Usun gracza z Klanu:", "KickMenu_Handler" );
	new szName[ 32 ], szData[ 6 ];
	
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iKlan[ iPlayer ] != g_iKlan[ id ] || id == iPlayer )
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public KickMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
	
	new iPlayer = str_to_num( szData );
	
	if( !is_user_connected( iPlayer ) )
	{
		ColorChat( id, NORMAL, "%s Ten gracz nie jest juz polaczony.", g_szPrefix );
		ShowTransferMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_Klan( iPlayer, -1 );
	
	Cmd_Klan( id );
	
	new iPlayers[ 32 ], iNum, iTemp;
	get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ )
	{
		iTemp = iPlayers[ i ];
		
		if( iTemp == iPlayer || g_iKlan[ iTemp ] != g_iKlan[ id ] )
			continue;
		
		ColorChat( iTemp, NORMAL, "%s ^03%s^01 zostal usuniety z Klanu.", g_szPrefix, szName );
	}
	
	ColorChat( iPlayer, NORMAL, "%s zostales wyrzucony z Klanu.", g_szPrefix, szName );
	
	return PLUGIN_HANDLED;
}

public ShowMembersMenu( id )
{
	new szName[ 64 ], iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new hMenu = menu_create( "Online Members:", "MemberMenu_Handler" );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iKlan[ id ] != g_iKlan[ iPlayer ] )
			continue;
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		if( isLeader( iPlayer, g_iKlan[ id ] ) )
		{
			add( szName, charsmax( szName ), " \r[Leader]" );
		}
		
		menu_additem( hMenu, szName );
	}
	
	menu_display( id, hMenu, 0 );
}

public MemberMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		Cmd_Klan( id );
		return PLUGIN_HANDLED;
	}
	
	menu_destroy( hMenu );
	
	ShowMembersMenu( id )
	return PLUGIN_HANDLED;
}

// Credits to Tirant from zombie mod and xOR from xRedirect
public LoadKlans()
{
	new szConfigsDir[ 60 ];
	get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
	add( szConfigsDir, charsmax( szConfigsDir ), "/cod_Klans.ini" );
	
	new iFile = fopen( szConfigsDir, "rt" );
	
	new aData[ KlanInfo ];
	
	new szBuffer[ 512 ], szData[ 6 ], szValue[ 6 ], i, iCurKlan;
	
	while( !feof( iFile ) )
	{
		fgets( iFile, szBuffer, charsmax( szBuffer ) );
		
		trim( szBuffer );
		remove_quotes( szBuffer );
		
		if( !szBuffer[ 0 ] || szBuffer[ 0 ] == ';' ) 
		{
			continue;
		}
		
		if( szBuffer[ 0 ] == '[' && szBuffer[ strlen( szBuffer ) - 1 ] == ']' )
		{
			copy( aData[ KlanName ], strlen( szBuffer ) - 2, szBuffer[ 1 ] );
			aData[ KlanHP ] = 0;
			aData[ KlanStealing ] = 0;
			aData[ KlanGravity ] = 0;
			aData[ KlanStamina ] = 0;
			aData[ KlanWeaponDrop ] = 0;
			aData[ KlanDamage ] = 0;
			aData[ KlanKills ] = 0;
			aData[ KlanMembers ] = _:TrieCreate();
			
			if( TrieKeyExists( g_tKlanNames, aData[ KlanName ] ) )
			{
				new szError[ 256 ];
				formatex( szError, charsmax( szError ), "[cod Klans] Klan already exists: %s", aData[ KlanName ] );
				set_fail_state( szError );
			}
			
			ArrayPushArray( g_aKlans, aData );
			
			TrieSetCell( g_tKlanNames, aData[ KlanName ], iCurKlan );

			log_amx( "Klan Created: %s", aData[ KlanName ] );
			
			iCurKlan++;
			
			continue;
		}
		
		strtok( szBuffer, szData, 31, szValue, 511, '=' );
		trim( szData );
		trim( szValue );
		
		if( TrieGetCell( g_tKlanValues, szData, i ) )
		{
			ArrayGetArray( g_aKlans, iCurKlan - 1, aData );
			
			switch( i )
			{					
				case VALUE_HP:
					aData[ KlanHP ] = str_to_num( szValue );
				
				case VALUE_STEALING:
					aData[ KlanStealing ] = str_to_num( szValue );
				
				case VALUE_GRAVITY:
					aData[ KlanGravity ] = str_to_num( szValue );
				
				case VALUE_STAMINA:
					aData[ KlanStamina ] = str_to_num( szValue );
				
				case VALUE_WEAPONDROP:
					aData[ KlanWeaponDrop ] = str_to_num( szValue );
					
				case VALUE_DAMAGE:
					aData[ KlanDamage ] = str_to_num( szValue );
				
				case VALUE_KILLS:
					aData[ KlanKills ] = str_to_num( szValue );
			}
			
			ArraySetArray( g_aKlans, iCurKlan - 1, aData );
		}
	}
	
	new Array:aSQL;
	sqlv_read_all_ex( g_hVault, aSQL );
	
	new aVaultData[ SQLVaultEntryEx ];
	
	new iKlan;
	
	for( i = 0; i < ArraySize( aSQL ); i++ )
	{
		ArrayGetArray( aSQL, i, aVaultData );
		
		if( TrieGetCell( g_tKlanNames, aVaultData[ SQLVEx_Key2 ], iKlan ) )
		{
			ArrayGetArray( g_aKlans, iKlan, aData );
			
			TrieSetCell( aData[ KlanMembers ], aVaultData[ SQLVEx_Key1 ], str_to_num( aVaultData[ SQLVEx_Data ] ) );
			
			ArraySetArray( g_aKlans, iKlan, aData );
		}
	}
	
	fclose( iFile );
}

public SaveKlans()
{
	new szConfigsDir[ 64 ];
	get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
	
	add( szConfigsDir, charsmax( szConfigsDir ), "/cod_Klans.ini" );
	
	if( file_exists( szConfigsDir ) )
		delete_file( szConfigsDir );
		
	new iFile = fopen( szConfigsDir, "wt" );
		
	new aData[ KlanInfo ];
	
	new szBuffer[ 256 ];

	for( new i = 0; i < ArraySize( g_aKlans ); i++ )
	{
		ArrayGetArray( g_aKlans, i, aData );
		
		formatex( szBuffer, charsmax( szBuffer ), "[%s]^n", aData[ KlanName ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "HP=%i^n", aData[ KlanHP ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Stealing=%i^n", aData[ KlanStealing ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Gravity=%i^n", aData[ KlanGravity ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Stamina=%i^n", aData[ KlanStamina ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "WeaponDrop=%i^n", aData[ KlanWeaponDrop ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Damage=%i^n", aData[ KlanDamage ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Kills=%i^n^n", aData[ KlanKills ] );
		fputs( iFile, szBuffer );
	}
	
	fclose( iFile );
}
	
	

set_user_Klan( id, iKlan, bool:bLeader=false )
{
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );

	new aData[ KlanInfo ];
	
	if( g_iKlan[ id ] > -1 )
	{
		ArrayGetArray( g_aKlans, g_iKlan[ id ], aData );
		TrieDeleteKey( aData[ KlanMembers ], szAuthID );
		ArraySetArray( g_aKlans, g_iKlan[ id ], aData );
		
		sqlv_remove_ex( g_hVault, szAuthID, aData[ KlanName ] );
	}

	if( iKlan > -1 )
	{
		ArrayGetArray( g_aKlans, iKlan, aData );
		TrieSetCell( aData[ KlanMembers ], szAuthID, _:bLeader + 1 );
		ArraySetArray( g_aKlans, iKlan, aData );
		
		sqlv_set_num_ex( g_hVault, szAuthID, aData[ KlanName ], _:bLeader + 1 );		
	}

	g_iKlan[ id ] = iKlan;
	
	return 1;
}
	
get_user_Klan( id )
{
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	new aData[ KlanInfo ];
	
	for( new i = 0; i < ArraySize( g_aKlans ); i++ )
	{
		ArrayGetArray( g_aKlans, i, aData );
		
		if( TrieKeyExists( aData[ KlanMembers ], szAuthID ) )
			return i;
	}
	
	return -1;
}
			
bool:isLeader( id, iKlan )
{
	if( !is_user_connected( id ) || iKlan == -1 )
		return false;
		
	new aData[ KlanInfo ];
	ArrayGetArray( g_aKlans, iKlan, aData );
	
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	new iStatus;
	TrieGetCell( aData[ KlanMembers ], szAuthID, iStatus );
	
	return iStatus == 2;
}