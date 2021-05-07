/*
*================================
* Название: statsx_shell
* Версия : 2.0.0 (BETA)
* Код: AMX Dev Team
* Доработка: MastaMan
* ----------------------
* Доступные языки: RU, UA, EN
* 
* Источник: http://amx-server.blogspot.com
* ================================
*/
/* AMX Mod X
*  StatsX Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
* This file is part of AMX Mod X.
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation, 
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve, 
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

//--------------------------------
#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <cstrike>
#include <nvault>

#define STATSX_SHELL_VER "2.0.0 (BETA)"
//--------------------------------

/*Color Chat*/
#define MAXSLOTS 32

enum ChatColor
{
	CHATCOLOR_NORMAL = 1,
	CHATCOLOR_GREEN,
	CHATCOLOR_TEAM_COLOR,
	CHATCOLOR_GREY, 	
	CHATCOLOR_RED, 		
	CHATCOLOR_BLUE, 	
}

new g_TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

new g_msgSayText
new g_msgTeamInfo

// Uncomment to activate log debug messages.
//#define STATSX_DEBUG

// HUD statistics duration in seconds (minimum 1.0 seconds).
#define HUD_DURATION_CVAR   "amx_statsx_duration"
#define HUD_DURATION        "12.0"

// HUD statistics stop relative freeze end in seconds.
// To stop before freeze end use a negative value.
#define HUD_FREEZE_LIMIT_CVAR   "amx_statsx_freeze"
#define HUD_FREEZE_LIMIT        "-2.0"

// HUD statistics minimum duration, in seconds, to trigger the display logic.
#define HUD_MIN_DURATION    0.2

// Config plugin constants.
#define MODE_HUD_DELAY      0   // Make a 0.01 sec delay on HUD reset process.

// You can also manualy enable or disable these options by setting them to 1
// For example:
// public ShowAttackers = 1
// However amx_statscfg command is recommended

public KillerChat           = 0 // displays killer hp&ap to victim console 
                                // and screen

public ShowAttackers        = 0 // shows attackers
public ShowVictims          = 0 // shows victims
public ShowKiller           = 0 // shows killer
public ShowTeamScore        = 0 // shows team score at round end
public ShowTotalStats       = 0 // shows round total stats
public ShowBestScore        = 0 // shows rounds best scored player
public ShowMostDisruptive   = 0 // shows rounds most disruptive player

public EndPlayer            = 0 // displays player stats at the end of map
public EndTop15             = 0 // displays top15 at the end of map

public SayHP                = 0 // displays information about user killer
public SayStatsMe           = 0 // displays user's stats and rank
public SayRankStats         = 0 // displays user's rank stats
public SayMe                = 0 // displays user's stats
public SayRank              = 0 // displays user's rank
public SayReport            = 0 // report user's weapon status to team
public SayScore             = 0 // displays team's map score
public SayTop15             = 0 // displays first 15 players
public SayStatsAll          = 0 // displays all players stats and rank

public ShowStats            = 1 // set client HUD-stats switched off by default
public ShowDistHS           = 0 // show distance and HS in attackers and
                                //  victims HUD lists
public ShowFullStats        = 0 // show full HUD stats (more than 78 chars)

public SpecRankInfo         = 0 // displays rank info when spectating

// Standard Contstants.
#define MAX_TEAMS               2
#define MAX_PLAYERS             32 + 1

#define MAX_NAME_LENGTH         128
#define MAX_WEAPON_LENGTH       31
#define MAX_TEXT_LENGTH         255
#define MAX_BUFFER_LENGTH       2047

// User stats parms id
#define STATS_KILLS             0
#define STATS_DEATHS            1
#define STATS_HS                2
#define STATS_TKS               3
#define STATS_SHOTS             4
#define STATS_HITS              5
#define STATS_DAMAGE            6

// Global player flags.
new BODY_PART[8][] =
{
	"WHOLEBODY", 
	"HEAD", 
	"CHEST", 
	"STOMACH", 
	"LEFTARM", 
	"RIGHTARM", 
	"LEFTLEG", 
	"RIGHTLEG"
}

new MM_BODY_PART[8][] =
{
	"WHOLEBODY", 
	"HEAD", 
	"CHEST", 
	"STOMACH", 
	"MM_LEFTARM", 
	"MM_RIGHTARM", 
	"MM_LEFTLEG", 
	"MM_RIGHTLEG"
}

// Killer information, save killer info at the time when player is killed.
#define KILLED_KILLER_ID        0   // Killer userindex/user-ID
#define KILLED_KILLER_HEALTH    1   // Killer's health
#define KILLED_KILLER_ARMOUR    2   // Killer's armour
#define KILLED_TEAM             3   // Killer's team
#define KILLED_KILLER_STATSFIX  4   // Fix to register the last hit/kill

new g_izKilled[MAX_PLAYERS][5]

// Menu variables and configuration
#define MAX_PPL_MENU_ACTIONS    2   // Number of player menu actions
#define PPL_MENU_OPTIONS        7   // Number of player options per displayed menu

new g_iPluginMode                                   = 0

new g_izUserMenuPosition[MAX_PLAYERS]               = {0, ...}
new g_izUserMenuAction[MAX_PLAYERS]                 = {0, ...}
new g_izUserMenuPlayers[MAX_PLAYERS][32]

new g_izSpecMode[MAX_PLAYERS]                       = {0, ...}

new g_izShowStatsFlags[MAX_PLAYERS]                 = {0, ...}
new g_izStatsSwitch[MAX_PLAYERS]                    = {0, ...}
new Float:g_fzShowUserStatsTime[MAX_PLAYERS]        = {0.0, ...}
new Float:g_fShowStatsTime                          = 0.0
new Float:g_fFreezeTime                             = 0.0
new Float:g_fFreezeLimitTime                        = 0.0
new Float:g_fHUDDuration                            = 0.0

new g_iRoundEndTriggered                            = 0
new g_iRoundEndProcessed                            = 0

new Float:g_fStartGame                              = 0.0
new g_izTeamScore[MAX_TEAMS]                        = {0, ...}
new g_izTeamEventScore[MAX_TEAMS]                   = {0, ...}
new g_izTeamRndStats[MAX_TEAMS][8]
new g_izTeamGameStats[MAX_TEAMS][8]
new g_izUserUserID[MAX_PLAYERS]                     = {0, ...}
new g_izUserAttackerDistance[MAX_PLAYERS]           = {0, ...}
new g_izUserVictimDistance[MAX_PLAYERS][MAX_PLAYERS]
new g_izUserRndName[MAX_PLAYERS][MAX_NAME_LENGTH + 1]
new g_izUserRndStats[MAX_PLAYERS][8]
new g_izUserGameStats[MAX_PLAYERS][8]

// Common buffer to improve performance, as Small always zero-initializes all vars
new g_sBuffer[MAX_BUFFER_LENGTH + 1]                = ""
new g_sScore[MAX_TEXT_LENGTH + 1]                   = ""
new g_sAwardAndScore[MAX_BUFFER_LENGTH + 1]         = ""

new t_sText[MAX_TEXT_LENGTH + 1]                    = ""
new t_sName[MAX_NAME_LENGTH + 1]                    = ""
new t_sWpn[MAX_WEAPON_LENGTH + 1]                   = ""

new g_HudSync_EndRound
new g_HudSync_SpecInfo

// MastaMan Edition

#define MAX_SORT_COUNT		100

#define MM_MINUTE 60
#define MM_HOUR 3600
#define MM_DAY 86400
#define MM_WEEK 604800
#define MM_MONTH 2592000
#define MM_YEAR 31536000

new bool:szTrigger = true

new iTopX, iTopEnd, iAwardID, iDesign, g_Vault, g_Vault2

new pcvar_statsmarquee, pcvar_statsmarquee_effect, pcvar_statsmarquee_color, pcvar_statsmarquee_position
new pcvar_award,  pcvar_award_anonce_chat, pcvar_award_chance, pcvar_award_cash, pcvar_dmg, pcvar_hs, pcvar_bot, pcvar_topx
new pcvar_style, pcvar_design, pcvar_day, pcvar_connect_message, pcvar_hostname, pcvar_connect_message_effect, pcvar_connect_message_color
new pcvar_pt, pcvar_pt_bonus, pcvar_pt_bonus_1h, pcvar_pt_bonus_2h, pcvar_pt_bonus_3h, pcvar_pt_bonus_4h, pcvar_pt_bonus_5h
new pcvar_pt_bonus_anonce, pcvar_connect_message_visit

new marquee_iID

new m_sName[MAX_NAME_LENGTH + 1]                  	= ""
new marquee_place[40]				= ""

new g_Statsx_Shell_Cvars[31][] =
{
	"csstats_rank",
	"csstats_maxsize",
	"amx_statsx_duration",
	"amx_statsx_freeze",
	"amx_statsx_shell_mode",
	"amx_statsx_design",
	"amx_statsx_marquee_enabled",
	"amx_statsx_marquee_effect",
	"amx_statsx_marquee_color",
	"amx_statsx_marquee_position",
	"amx_statsx_top_dmg_enabled",
	"amx_statsx_top_hs_enabled",
	"amx_statsx_top_bot_enabled",
	"amx_statsx_top_topx_enabled",
	"amx_statsx_award_enabled",
	"amx_statsx_award_cash",
	"amx_statsx_award_chance",
	"amx_statsx_award_anonce",
	"amx_statsx_day_stat",
	"amx_statsx_pt_enabled",
	"amx_statsx_pt_bonus",
	"amx_statsx_pt_bonus_anonce",
	"amx_statsx_pt_bonus_1h",
	"amx_statsx_pt_bonus_2h",
	"amx_statsx_pt_bonus_3h",
	"amx_statsx_pt_bonus_4h",
	"amx_statsx_pt_bonus_5h",
	"amx_statsx_conn_msg_enabled",
	"amx_statsx_conn_msg_effect",
	"amx_statsx_conn_msg_color",
	"amx_statsx_conn_msg_visit"
}

// Themes

#define STATSX_SHELL_DESIGN_MAX 13

#define STATSX_SHELL_DESIGN1_STYLE "<meta charset=UTF-8><style>body{background:#112233;font-family:Arial}th{background:#558866;color:#FFF;padding:10px 2px;text-align:left}td{padding:4px 3px}table{background:#EEEECC;font-size:12px;font-family:Arial}h2,h3{color:#FFF;font-family:Verdana}#c{background:#E2E2BC}img{height:10px;background:#09F;margin:0 3px}#r{height:10px;background:#B6423C}#clr{background:none;color:#FFF;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN2_STYLE "<meta charset=UTF-8><style>body{font-family:Arial}th{background:#575757;color:#FFF;padding:5px;border-bottom:2px #BCE27F solid;text-align:left}td{padding:3px;border-bottom:1px #E7F0D0 solid}table{color:#3C9B4A;background:#FFF;font-size:12px}h2,h3{color:#333;font-family:Verdana}#c{background:#F0F7E2}img{height:10px;background:#62B054;margin:0 3px}#r{height:10px;background:#717171}#clr{background:none;color:#575757;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN3_STYLE "<meta charset=UTF-8><style>body{background:#E6E6E6;font-family:Verdana}th{background:#F5F5F5;color:#A70000;padding:6px;text-align:left}td{padding:2px 6px}table{color:#333;background:#E6E6E6;font-size:10px;font-family:Georgia;border:2px solid #D9D9D9}h2,h3{color:#333;}#c{background:#FFF}img{height:10px;background:#14CC00;margin:0 3px}#r{height:10px;background:#CC8A00}#clr{background:none;color:#A70000;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN4_STYLE "<meta charset=UTF-8><style>body{background:#E8EEF7;margin:2px;font-family:Tahoma}th{color:#0000CC;padding:3px}tr{text-align:left;background:#E8EEF7}td{padding:3px}table{background:#CCC;font-size:11px}h2,h3{font-family:Verdana}img{height:10px;background:#09F;margin:0 3px}#r{height:10px;background:#B6423C}#clr{background:none;color:#000;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN5_STYLE "<meta charset=UTF-8><style>body{background:#555;font-family:Arial}th{border-left:1px solid #ADADAD;border-top:1px solid #ADADAD}table{background:#3C3C3C;font-size:11px;color:#FFF;border-right:1px solid #ADADAD;border-bottom:1px solid #ADADAD;padding:3px}h2,h3{color:#FFF}#c{background:#FF9B00;color:#000}img{height:10px;background:#00E930;margin:0 3px}#r{height:10px;background:#B6423C}#clr{background:none;color:#FFF;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN6_STYLE "<meta charset=UTF-8><style>body{background:#FFF;font-family:Tahoma}th{background:#303B4A;color:#FFF}table{padding:6px 2px;background:#EFF1F3;font-size:12px;color:#222;border:1px solid #CCC}h2,h3{color:#222}#c{background:#E9EBEE}img{height:7px;background:#F8931F;margin:0 3px}#r{height:7px;background:#D2232A}#clr{background:none;color:#303B4A;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN7_STYLE "<meta charset=UTF-8><style>body{background:#FFF;font-family:Verdana}th{background:#2E2E2E;color:#FFF;text-align:left}table{padding:6px 2px;background:#FFF;font-size:11px;color:#333;border:1px solid #CCC}h2,h3{color:#333}#c{background:#F0F0F0}img{height:7px;background:#444;margin:0 3px}#r{height:7px;background:#999}#clr{background:none;color:#2E2E2E;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN8_STYLE "<meta charset=UTF-8><style>body{background:#242424;margin:20px;font-family:Tahoma}th{background:#2F3034;color:#BDB670;text-align:left} table{padding:4px;background:#4A4945;font-size:10px;color:#FFF}h2,h3{color:#D2D1CF}#c{background:#3B3C37}img{height:12px;background:#99CC00;margin:0 3px}#r{height:12px;background:#999900}#clr{background:none;color:#FFF;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN9_STYLE "<meta charset=UTF-8><style>body{background:#FFF;font-family:Tahoma}th{background:#056B9E;color:#FFF;padding:3px;text-align:left;border-top:4px solid #3986AC}td{padding:2px 6px}table{color:#006699;background:#FFF;font-size:12px;border:2px solid #006699}h2,h3{color:#F69F1C;}#c{background:#EFEFEF}img{height:5px;background:#1578D3;margin:0 3px}#r{height:5px;background:#F49F1E}#clr{background:none;color:#056B9E;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN10_STYLE "<meta charset=UTF-8><style>body{background:#4C5844;font-family:Tahoma}th{background:#1E1E1E;color:#C0C0C0;padding:2px;text-align:left;}td{padding:2px 10px}table{color:#AAC0AA;background:#424242;font-size:13px}h2,h3{color:#C2C2C2;font-family:Tahoma}#c{background:#323232}img{height:3px;background:#B4DA45;margin:0 3px}#r{height:3px;background:#6F9FC8}#clr{background:none;color:#FFF;font-size:20px}</style>"
#define STATSX_SHELL_DESIGN11_STYLE "<meta charset=UTF-8><style>body{background:#F2F2F2;font-family:Arial}th{background:#175D8B;color:#FFF;padding:7px;text-align:left}td{padding:3px;border-bottom:1px #BFBDBD solid}table{color:#153B7C;background:#F4F4F4;font-size:11px;border:1px solid #BFBDBD}h2,h3{color:#153B7C}#c{background:#ECECEC}img{height:8px;background:#54D143;margin:0 3px}#r{height:8px;background:#C80B0F}#clr{background:none;color:#175D8B;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN12_STYLE "<meta charset=UTF-8><style>body{background:#283136;font-family:Arial}th{background:#323B40;color:#6ED5FF;padding:10px 2px;text-align:left}td{padding:4px 3px;border-bottom:1px solid #DCDCDC}table{background:#EDF1F2;font-size:10px;border:2px solid #505A62}h2,h3{color:#FFF}img{height:10px;background:#A7CC00;margin:0 3px}#r{height:10px;background:#CC3D00}#clr{background:none;color:#6ED5FF;font-size:20px;border:0}</style>"
#define STATSX_SHELL_DESIGN13_STYLE "<meta charset=UTF-8><style>body{background:#220000;font-family:Tahoma}th{background:#3E0909;color:#FFF;padding:5px 2px;text-align:left;border-bottom:1px solid #DEDEDE}td{padding:2px 2px;}table{background:#FFF;font-size:11px;border:1px solid #791616}h2,h3{color:#FFF}#c{background:#F4F4F4;color:#7B0000}img{height:7px;background:#a00000;margin:0 3px}#r{height:7px;background:#181818}#clr{background:none;color:#CFCFCF;font-size:20px;border:0}</style>"

#define STATSX_SHELL_DEFAULT_STYLE "<meta charset=UTF-8><style>body{background:#000}tr{text-align:left}table{font-size:13px;color:#FFB000;padding:2px}h2,h3{color:#FFF;font-family:Verdana}img{height:5px;background:#0000FF;margin:0 3px}#r{height:5px;background:#FF0000}</style>"


//--------------------------------
// Initialize
//--------------------------------
public plugin_init()
{
	// Register plugin.
	register_plugin("StatsX (MastaMan Edition)", AMXX_VERSION_STR, "AMXX Dev Team")
	register_dictionary("statsx_shell.txt")
	
	register_cvar("statsx_shell_ver", STATSX_SHELL_VER, FCVAR_SPONLY | FCVAR_SERVER)
		
	//Stats Marquee
	set_task(15.0, "StatsMarquee", 0, _, 0)
		
	// Random award ID
	//iAwardID = random_num(0,9)
	
	// Random design
	iDesign = random_num(1, STATSX_SHELL_DESIGN_MAX)
	
	pcvar_hostname = get_cvar_pointer("hostname")
	
	pcvar_style = register_cvar("amx_statsx_shell_mode", "1")
	pcvar_design = register_cvar("amx_statsx_design", "1")
	
	pcvar_statsmarquee = register_cvar("amx_statsx_marquee_enabled", "1")
	pcvar_statsmarquee_effect = register_cvar("amx_statsx_marquee_effect", "0")
	pcvar_statsmarquee_color = register_cvar("amx_statsx_marquee_color", "0")
	pcvar_statsmarquee_position = register_cvar("amx_statsx_marquee_position", "0")
	
	pcvar_dmg = register_cvar("amx_statsx_top_dmg_enabled", "1")
	
	pcvar_hs = register_cvar("amx_statsx_top_hs_enabled", "1")
	
	pcvar_bot = register_cvar("amx_statsx_top_bot_enabled", "1")
	
	pcvar_topx = register_cvar("amx_statsx_top_topx_enabled", "1")
	
	pcvar_award = register_cvar("amx_statsx_award_enabled", "1")
	pcvar_award_cash = register_cvar("amx_statsx_award_cash", "1000")
	pcvar_award_chance = register_cvar("amx_statsx_award_chance", "0.1")
	pcvar_award_anonce_chat = register_cvar("amx_statsx_award_anonce", "1")
	
	pcvar_day = register_cvar("amx_statsx_day_stat", "1")
	
	pcvar_pt = register_cvar("amx_statsx_pt_enabled", "1")
	pcvar_pt_bonus = register_cvar("amx_statsx_pt_bonus", "1")
	pcvar_pt_bonus_anonce = register_cvar("amx_statsx_pt_bonus_anonce", "1")
	pcvar_pt_bonus_1h = register_cvar("amx_statsx_pt_bonus_1h", "250")
	pcvar_pt_bonus_2h = register_cvar("amx_statsx_pt_bonus_2h", "500")
	pcvar_pt_bonus_3h = register_cvar("amx_statsx_pt_bonus_3h", "1000")
	pcvar_pt_bonus_4h = register_cvar("amx_statsx_pt_bonus_4h", "2000")
	pcvar_pt_bonus_5h = register_cvar("amx_statsx_pt_bonus_5h", "5000")
	
	pcvar_connect_message = register_cvar("amx_statsx_conn_msg_enabled", "1")
	pcvar_connect_message_effect = register_cvar("amx_statsx_conn_msg_effect", "0")
	pcvar_connect_message_color = register_cvar("amx_statsx_conn_msg_color", "0")
	pcvar_connect_message_visit = register_cvar("amx_statsx_conn_msg_visit", "1")
	
	
	// Register events.
	register_event("TextMsg", "eventStartGame", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	register_event("ResetHUD", "eventResetHud", "be")
	register_event("RoundTime", "eventStartRound", "bc")
	register_event("SendAudio", "eventEndRound", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")
	register_event("TeamScore", "eventTeamScore", "a")
	register_event("30", "eventIntermission", "a")
	register_event("TextMsg", "eventSpecMode", "bd", "2&ec_Mod")
	register_event("StatusValue", "eventShowRank", "bd", "1=2")

	// Register commands.
	register_clcmd("say /hp", "cmdHp", 0, "- display info. about your killer (chat)")
	register_clcmd("say /statsme", "cmdStatsMe", 0, "- display your stats (MOTD)")
	register_clcmd("say /rankstats", "cmdRankStats", 0, "- display your server stats (MOTD)")
	register_clcmd("say /me", "cmdMe", 0, "- display current round stats (chat)")
	register_clcmd("say /score", "cmdScore", 0, "- display last score (chat)")
	register_clcmd("say /rank", "cmdRank", 0, "- display your rank (chat)")
	register_clcmd("say /report", "cmdReport", 0, "- display weapon status (say_team)")
	register_clcmd("say /stats", "cmdStats", 0, "- display players stats (menu/MOTD)")
	register_clcmd("say /switch", "cmdSwitch", 0, "- switch client's stats on or off")
	register_clcmd("say_team /hp", "cmdHp", 0, "- display info. about your killer (chat)")
	register_clcmd("say_team /statsme", "cmdStatsMe", 0, "- display your stats (MOTD)")
	register_clcmd("say_team /rankstats", "cmdRankStats", 0, "- display your server stats (MOTD)")
	register_clcmd("say_team /me", "cmdMe", 0, "- display current round stats (chat)")
	register_clcmd("say_team /score", "cmdScore", 0, "- display last score (chat)")
	register_clcmd("say_team /rank", "cmdRank", 0, "- display your rank (chat)")
	register_clcmd("say_team /report", "cmdReport", 0, "- display weapon status (say_team_team)")
	register_clcmd("say_team /stats", "cmdStats", 0, "- display players stats (menu/MOTD)")
	register_clcmd("say_team /switch", "cmdSwitch", 0, "- switch client's stats on or off")


	register_clcmd("say /top15", "cmdPlace1", 0, "- display top 15 players (MOTD)")
	register_clcmd("say_team /top15", "cmdPlace1", 0, "- display top 15 players (MOTD)")

	// Register menus.
	register_menucmd(register_menuid("Server Stats"), 1023, "actionStatsMenu")

	// Register special configuration setting and default value.
	register_srvcmd("amx_statsx_mode", "cmdPluginMode", ADMIN_CFG, "<flags> - sets plugin options")

#if defined STATSX_DEBUG
	register_clcmd("say /hudtest", "cmdHudTest")
#endif

	register_cvar(HUD_DURATION_CVAR, HUD_DURATION)
	register_cvar(HUD_FREEZE_LIMIT_CVAR, HUD_FREEZE_LIMIT)
	

	// Init buffers and some global vars.
	g_sBuffer[0] = 0
	save_team_chatscore()
	
	g_HudSync_EndRound = CreateHudSyncObj()
	g_HudSync_SpecInfo = CreateHudSyncObj()
	
	g_msgSayText = get_user_msgid("SayText")
	g_msgTeamInfo = get_user_msgid("TeamInfo") 
}

public plugin_cfg()
{
	new addStast[] = "amx_statscfg add ^"%s^" %s"

	server_cmd(addStast, "ST_SHOW_KILLER_CHAT", "KillerChat")
	server_cmd(addStast, "ST_SHOW_ATTACKERS", "ShowAttackers")
	server_cmd(addStast, "ST_SHOW_VICTIMS", "ShowVictims")
	server_cmd(addStast, "ST_SHOW_KILLER", "ShowKiller")
	server_cmd(addStast, "ST_SHOW_TEAM_SCORE", "ShowTeamScore")
	server_cmd(addStast, "ST_SHOW_TOTAL_STATS", "ShowTotalStats")
	server_cmd(addStast, "ST_SHOW_BEST_SCORE", "ShowBestScore")
	server_cmd(addStast, "ST_SHOW_MOST_DISRUPTIVE", "ShowMostDisruptive")
	server_cmd(addStast, "ST_SHOW_HUD_STATS_DEF", "ShowStats")
	server_cmd(addStast, "ST_SHOW_DIST_HS_HUD", "ShowDistHS")
	server_cmd(addStast, "ST_STATS_PLAYER_MAP_END", "EndPlayer")
	server_cmd(addStast, "ST_STATS_TOP15_MAP_END", "EndTop15")
	server_cmd(addStast, "ST_SAY_HP", "SayHP")
	server_cmd(addStast, "ST_SAY_STATSME", "SayStatsMe")
	server_cmd(addStast, "ST_SAY_RANKSTATS", "SayRankStats")
	server_cmd(addStast, "ST_SAY_ME", "SayMe")
	server_cmd(addStast, "ST_SAY_RANK", "SayRank")
	server_cmd(addStast, "ST_SAY_REPORT", "SayReport")
	server_cmd(addStast, "ST_SAY_SCORE", "SayScore")
	server_cmd(addStast, "ST_SAY_TOP15", "SayTop15")
	server_cmd(addStast, "ST_SAY_STATS", "SayStatsAll")
	server_cmd(addStast, "ST_SPEC_RANK", "SpecRankInfo")

	// Update local configuration vars with value in cvars.
	get_config_cvars()

	//MastaMan Edition
	
	if(get_pcvar_num(pcvar_day))
	{
		g_Vault = nvault_open("statsx_shell_hour_attend")
	
		if(g_Vault == INVALID_HANDLE)
		{
			set_fail_state("Error opening nVault")
		}
	}
	
	if(get_pcvar_num(pcvar_pt))
	{
		g_Vault2 = nvault_open("statsx_shell_played_time")
	
		if(g_Vault2 == INVALID_HANDLE)
		{
			set_fail_state("Error opening nVault")
		}
		
		nvault_prune(g_Vault2 , 0 , get_systime() - (30 * 86400 ))
	}
			
	if(is_plugin_loaded("statsx.amxx", true) != -1)
	{
		server_cmd("amxx pause statsx.amxx")
	}
		
	new szCfgDir[MAX_TEXT_LENGTH], Time[9] 
	get_time("%H:%M:%S",Time,8)
	
	get_configsdir(szCfgDir, MAX_TEXT_LENGTH  - 1)
	formatex(szCfgDir, sizeof (szCfgDir) -1 , "%s/statsx_shell/statsx_shell.cfg", szCfgDir)
	server_cmd("exec %s", szCfgDir)
	
	
	server_print(" ")
	server_print("###############################################################################")
	server_print("^tTitle  : StatsX Shell (Ultimate StatsX)")
	server_print("^tVersion: %s", STATSX_SHELL_VER)
	server_print("^tAuthor : AMX MOD X DEV TEAM")
	server_print("^tEdited : MastaMan")
	server_print("^tSite   : http://amx-server.blogspot.com")
	server_print(" ")
	server_print("------------------------------------------------------------------------------")
	server_print(" ")
	if(file_exists(szCfgDir))
	{
		server_print("[%s] > Load settings from: statsx_shell.cfg", Time)
	}
	else
	{
		server_print("[%s] > Not found: statsx_shell.cfg ........................... [ERROR]", Time)
		server_print(" ")
		server_print("> Please reinstall plugin statsx_shell.amxx for ")
		server_print(" solve this problem or check your cfg!")
		server_print(" ")
		server_print("> Visit www.amx-server.blogspot.com for check new version and more info...")
		server_print(" ")
		server_print("###############################################################################")
		
		//log_amx("Not found: statsx_shell.cfg")
		
		
		return PLUGIN_CONTINUE
	}
	server_print(" ")
			
	new szData[MAX_TEXT_LENGTH], i
	new bool:bERROR_MESSAGE, szERROR_MESSAGE[70]
	new file = fopen(szCfgDir, "rt")
	while(!feof(file))
	{		
		new bool:g_bERROR_MESSAGE_TYPE1 = true
		new bool:g_bERROR_MESSAGE_TYPE2 = true
		
		fgets(file, szData, sizeof(szData) -1)
		
				
		if(szData[0] == '/' || szData[0] == ';' || strlen(szData) < 3)
		{
			continue
		}
	
		new param1[32], param2[32]

		parse(szData, param1, sizeof(param1), param2, sizeof(param2))
	
		////////////////////////////////////////////////
		
		for(new j = 0; j < sizeof(g_Statsx_Shell_Cvars); j++)
		{
			if(equali(param1, g_Statsx_Shell_Cvars[j]))
			{
				g_bERROR_MESSAGE_TYPE1 = false
			}
		}
		
		if(strlen(param2) < 1 || equali(param2, " "))
		{
			g_bERROR_MESSAGE_TYPE2 = true
		}
		else
		{
			g_bERROR_MESSAGE_TYPE2 = false
		}
		
		////////////////////////////////////////////////
				
		new szSpaceCount[128]
		new iLen = 0
				
		new iSpaceCount 
		
		////////////////////////////////////////////////
		
		if(!g_bERROR_MESSAGE_TYPE1)
		{						
			if(!g_bERROR_MESSAGE_TYPE2)
			{
				
				iLen = formatex(szERROR_MESSAGE, sizeof(szERROR_MESSAGE) - 1, "[%s] > Read cvar ^"%s^" ^"%s^" ", Time,param1, param2)
		
				iSpaceCount = sizeof(szERROR_MESSAGE) - iLen
					
				for(new k = 1; k < iSpaceCount; k ++)
				{
					iLen += formatex(szERROR_MESSAGE[iLen], sizeof(szERROR_MESSAGE) - iLen, ".")
				}
			
				server_print("%s%s%s", szERROR_MESSAGE, szSpaceCount, " [OK]")
				server_cmd("%s %s", param1, param2)
			}
			else
			{
				bERROR_MESSAGE = true
				
				iLen = formatex(szERROR_MESSAGE, sizeof(szERROR_MESSAGE) - 1, "[%s] > Bad value for ^"%s^" ", Time,param1)
		
				iSpaceCount = sizeof(szERROR_MESSAGE) - iLen
					
				for(new k = 1; k < iSpaceCount; k ++)
				{
					iLen += formatex(szERROR_MESSAGE[iLen], sizeof(szERROR_MESSAGE) - iLen, ".")
				}
			
				server_print("%s%s%s", szERROR_MESSAGE, szSpaceCount, " [ERROR]")
				//log_amx("Bad value for %s", param1)
			}
		}
		else
		{
			bERROR_MESSAGE = true
			
			iLen = formatex(szERROR_MESSAGE, sizeof(szERROR_MESSAGE) - 1, "[%s] > Unknown cvar ^"%s^" ", Time, param1)
		
			iSpaceCount = sizeof(szERROR_MESSAGE) - iLen
					
			for(new k = 1; k < iSpaceCount; k ++)
			{
				iLen += formatex(szERROR_MESSAGE[iLen], sizeof(szERROR_MESSAGE) - iLen, ".")
			}
			
			server_print("%s%s%s", szERROR_MESSAGE, szSpaceCount, " [ERROR]")
			//log_amx("Unknown cvar %s", param1)
		}
		
		
		i++
	}
	
	if(bERROR_MESSAGE)
	{
			server_print(" ")
			server_print("------------------------------------------------------------------------------")
			server_print(" ")
			server_print("[%s] > [!] WARNING: Read some cvar's from configuration failure!", Time)
			server_print("> Please check [ERROR] messages above...")
			server_print(" ")
			server_print("> Visit www.amx-server.blogspot.com for check new version and more info...")
			
	}
	else
	{
			server_print(" ")
			server_print("------------------------------------------------------------------------------")
			server_print(" ")
			server_print("[%s] > [OK] All settings load success!", Time)
	}
	
	fclose(file)	
	
	server_print(" ")
	server_print("###############################################################################")
	
	// MastaMan Edition
	
	if(get_pcvar_num(pcvar_style))
	{
		register_clcmd("say /top", "cmdPlace1", 0, "- display top 10 players (MOTD)")
		register_clcmd("say /place", "cmdPlace1", 0, "- display top 10 players (MOTD)")
		register_clcmd("say /1place", "cmdPlace1", 0, "- display top 10 players (MOTD)")
		register_clcmd("say /2place", "cmdPlace2", 0, "- display top 20 players (MOTD)")
		register_clcmd("say /3place", "cmdPlace3", 0, "- display top 30 players (MOTD)")
		register_clcmd("say /top1", "cmdPlace1", 0, "- display top 10 players (MOTD)")
		register_clcmd("say /top10", "cmdPlace1", 0, "- display top 10 players (MOTD)")
		register_clcmd("say /top2", "cmdPlace2", 0, "- display top 20 players (MOTD)")
		register_clcmd("say /top20", "cmdPlace2", 0, "- display top 20 players (MOTD)")
		register_clcmd("say /top3", "cmdPlace3", 0, "- display top 30 players (MOTD)")
		register_clcmd("say /top30", "cmdPlace3", 0, "- display top 30 players (MOTD)")
		register_clcmd("say /dmg", "cmdDmg", 0, "- display top 10 dmg players (MOTD)")
		register_clcmd("say /damage", "cmdDmg", 0, "- display top 10 dmg players (MOTD)")
		register_clcmd("say /hs", "cmdHs", 0, "- display top 10 hs players (MOTD)")
		register_clcmd("say /headshot", "cmdHs", 0, "- display top 10 hs players (MOTD)")
		register_clcmd("say /bot", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /bots", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /flop", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /flops", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /noob", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /noobs", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /lol", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /lols", "cmdBot10", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say /award", "cmdAward", 0, "- display top 10 bots (MOTD)")
		register_clcmd("say", "cmdTopX")
		register_clcmd("say /day", "cmdDay")
		register_clcmd("say /attend", "cmdDay")
		register_clcmd("say /time", "cmdPlTime")
		register_clcmd("say /pt", "cmdPlTime")
	}

	
	return PLUGIN_CONTINUE
}

public plugin_end()
{
	
	if(get_pcvar_num(pcvar_day))
	{
		nvault_close(g_Vault)
	}
	
	if(get_pcvar_num(pcvar_pt))
	{
		nvault_close(g_Vault2)
	}
}

public client_putinserver(id)
{
	if(get_pcvar_num(pcvar_connect_message))
	{
		set_task(2.5, "connect_message_anonce", id)
	}
}

public connect_message_anonce(id)
{
	new szName[32], szKey[50], szData[128], szHUDMessage[512]
	new szHour[5], szDay[5], szMonth[5]
	new izStats[8], izBody[8], szHostname[64]
	new  iHour, iDay, iMonth
	new iLen = 0
	new iColor_R, iColor_G, iColor_B, g_pcvarColor
		
	format_time(szHour, sizeof(szHour) - 1, "%H")
	format_time(szDay, sizeof(szDay) - 1, "%d")
	format_time(szMonth, sizeof(szMonth) - 1, "%m")
		
	iHour = str_to_num(szHour)
	iDay = str_to_num(szDay)
	iMonth = str_to_num(szMonth)
	
					
	get_user_name(id, szName, sizeof(szName) - 1)
	formatex(szKey, sizeof(szKey) - 1, "LAST_VISIT#%s", szName)
						
	new g_iLastPT = get_pcvar_num(pcvar_pt)
	new g_iLastVisit = get_pcvar_num(pcvar_connect_message_visit)
	
		
	new iRank = get_user_stats(id, izStats, izBody)
	new iMax = get_statsnum()
	get_pcvar_string(pcvar_hostname, szHostname, sizeof(szHostname) - 1)   
	
	iLen = formatex(szHUDMessage, sizeof(szHUDMessage) - 1, "%L %s^n^n%L %L^n", LANG_SERVER, "MM_WELCOME", szHostname, LANG_SERVER, "YOUR", LANG_SERVER, "RANK_IS", iRank, iMax)

	if(g_iLastPT && g_iLastVisit)
	{
		new g_iNvault = nvault_get(g_Vault2, szKey, szData, sizeof(szData) - 1)
		
		new szTmpDay[5], szTmpMonth[5], szTmpYear[5], szTmpHour[5], szTmpMinute[5]
		parse(szData, szTmpDay, sizeof(szTmpDay), szTmpMonth, sizeof(szTmpMonth), szTmpYear, sizeof(szTmpYear), szTmpHour, sizeof(szTmpHour), szTmpMinute, sizeof(szTmpMinute))
	
		if(strlen(szTmpMinute) == 1)
		{
			formatex(szTmpMinute, sizeof(szTmpMinute) - 1, "0%s", szTmpMinute)
		}
	
		if(g_iNvault && iDay == str_to_num(szTmpDay) && iMonth == str_to_num(szTmpMonth) && (iHour - str_to_num(szTmpHour)) >= 1)
		{
			iLen += formatex(szHUDMessage[iLen], sizeof(szHUDMessage) - iLen, "%L %L %s:%s", LANG_SERVER, "MM_LAST_VISIT", LANG_SERVER, "MM_TODAY", szTmpHour, szTmpMinute)
		}
		if(g_iNvault && (iDay - str_to_num(szTmpDay)) == 1 && iMonth == str_to_num(szTmpMonth))
		{
			iLen += formatex(szHUDMessage[iLen], sizeof(szHUDMessage) - iLen, "%L %L %s:%s", LANG_SERVER, "MM_LAST_VISIT", LANG_SERVER, "MM_YESTERDAY", szTmpHour, szTmpMinute)
		}
		if(g_iNvault && (iDay - str_to_num(szTmpDay)) == 2 && iMonth == str_to_num(szTmpMonth))
		{
			iLen += formatex(szHUDMessage[iLen], sizeof(szHUDMessage) - iLen, "%L %L %s:%s", LANG_SERVER, "MM_LAST_VISIT", LANG_SERVER, "MM_DAY_BEFORE", szTmpHour, szTmpMinute)
		}
		if(g_iNvault && 2 < (iDay - str_to_num(szTmpDay)) <= 7 && iMonth == str_to_num(szTmpMonth))
		{
			iLen += formatex(szHUDMessage[iLen], sizeof(szHUDMessage) - iLen, "%L %d %L %L %s:%s", LANG_SERVER, "MM_LAST_VISIT", (iDay - str_to_num(szTmpDay)), LANG_SERVER, "MM_DAY", LANG_SERVER, "MM_BEFORE", szTmpHour, szTmpMinute)
		}
		if(g_iNvault && (iDay - str_to_num(szTmpDay)) > 7 && iMonth == str_to_num(szTmpMonth))
		{
			iLen += formatex(szHUDMessage[iLen], sizeof(szHUDMessage) - iLen, "%L %s.%s.%s %s:%s", LANG_SERVER, "MM_LAST_VISIT", szTmpDay, szTmpMonth, szTmpYear, szTmpHour, szTmpMinute)
		}
	}
	
	g_pcvarColor = get_pcvar_num(pcvar_connect_message_color)
		
	if(g_pcvarColor == 10)
	{
		g_pcvarColor = random_num(1, 8)
	}
	
	switch(g_pcvarColor)
	{
		case 1:
		{
			// RED
			iColor_R = 255
			iColor_G = 0
			iColor_B = 0
		}

		case 2:
		{
			// BLUE
			iColor_R = 0
			iColor_G = 0
			iColor_B = 255
		}
		case 3:
		{
			// YELLOW
			iColor_R = 255
			iColor_G = 255
			iColor_B = 0
		}
		
		case 4:
		{
			// CYAN
			iColor_R = 0
			iColor_G = 255
			iColor_B = 255
		}
		
		case 5:
		{
			// MAGENTA
			iColor_R = 255
			iColor_G = 0
			iColor_B = 255
		}
		case 6:
		{
			// ORANGE
			iColor_R = 255
			iColor_G = 128
			iColor_B = 0
		}
		case 7:
		{
			// VIOLET
			iColor_R = 0
			iColor_G = 128
			iColor_B = 255
		}
		case 8:
		{
			// GRAY
			iColor_R = 100
			iColor_G = 100
			iColor_B = 100
		}
		case 9:
		{
			// RANDOM
			iColor_R = random_num(0, 255)
			iColor_G = random_num(0, 255)
			iColor_B = random_num(0, 255)
		}
		default:
		{
			// GREEN
			iColor_R = 0
			iColor_G = 255
			iColor_B = 0
		}
	}
	
	new iEffect, Float:iFadeIn, Float:iFadeOut, Float:iHoldTime
	switch(get_pcvar_num(pcvar_connect_message_effect))
	{
		case 1:
		{
			iEffect = 1
			iFadeIn = 0.2
			iFadeOut = 0.2
			iHoldTime = 7.0
		}
		case 2:
		{
			iEffect = 2
			iFadeIn = 0.05
			iFadeOut = 0.5
			iHoldTime = 7.0
		}
		default:
		{
			iEffect = 0
			iFadeIn = 0.5
			iFadeOut = 0.5
			iHoldTime = 7.0
		}
	}
	
	set_hudmessage(iColor_R, iColor_G, iColor_B, 0.15, 0.40, iEffect, 0.1, iHoldTime, iFadeIn, iFadeOut, -1)
	show_hudmessage(id, "%s", szHUDMessage)
}

// Set hudmessage format.
set_hudtype_killer(Float:fDuration)
	set_hudmessage(220, 80, 0, 0.05, 0.15, 0, 6.0, fDuration, (fDuration >= g_fHUDDuration) ? 1.0 : 0.0, 1.0, -1)

set_hudtype_endround(Float:fDuration)
{
	set_hudmessage(100, 200, 0, 0.05, 0.55, 0, 0.02, fDuration, (fDuration >= g_fHUDDuration) ? 1.0 : 0.0, 1.0)
}

set_hudtype_attacker(Float:fDuration)
	set_hudmessage(220, 80, 0, 0.55, 0.35, 0, 6.0, fDuration, (fDuration >= g_fHUDDuration) ? 1.0 : 0.0, 1.0, -1)

set_hudtype_victim(Float:fDuration)
	set_hudmessage(0, 80, 220, 0.55, 0.60, 0, 6.0, fDuration, (fDuration >= g_fHUDDuration) ? 1.0 : 0.0, 1.0, -1)

set_hudtype_specmode()
{
	set_hudmessage(255, 255, 255, 0.02, 0.96, 2, 0.05, 0.1, 0.01, 3.0, -1)
}

#if defined STATSX_DEBUG
public cmdHudTest(id)
{
	new i, iLen
	iLen = 0
	
	for (i = 1; i < 20; i++)
		iLen += format(g_sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "....x....1....x....2....x....3....x....4....x....^n")
	
	set_hudtype_killer(50.0)
	show_hudmessage(id, "%s", g_sBuffer)
}
#endif

// Stats formulas
Float:accuracy(izStats[8])
{
	if (!izStats[STATS_SHOTS])
		return (0.0)
	
	return (100.0 * float(izStats[STATS_HITS]) / float(izStats[STATS_SHOTS]))
}

Float:effec(izStats[8])
{
	if (!izStats[STATS_KILLS])
		return (0.0)
	
	return (100.0 * float(izStats[STATS_KILLS]) / float(izStats[STATS_KILLS] + izStats[STATS_DEATHS]))
}

// Distance formula (metric)
Float:distance(iDistance)
{
	return float(iDistance) * 0.0254
}

// Get plugin config flags.
set_plugin_mode(id, sFlags[])
{
	if (sFlags[0])
		g_iPluginMode = read_flags(sFlags)
	
	get_flags(g_iPluginMode, t_sText, MAX_TEXT_LENGTH)
	console_print(id, "%L", id, "MODE_SET_TO", t_sText)
	
	return g_iPluginMode
}

// Get config parameters.
get_config_cvars()
{
	g_fFreezeTime = get_cvar_float("mp_freezetime")
	
	if (g_fFreezeTime < 0.0)
		g_fFreezeTime = 0.0

	g_fHUDDuration = get_cvar_float(HUD_DURATION_CVAR)
	
	if (g_fHUDDuration < 1.0)
		g_fHUDDuration = 1.0

	g_fFreezeLimitTime = get_cvar_float(HUD_FREEZE_LIMIT_CVAR)
}

// Get and format attackers header and list.
get_attackers(id, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new izStats[8], izBody[8]
	new iAttacker
	new iFound, iLen
	new iMaxPlayer = get_maxplayers()

	iFound = 0
	sBuffer[0] = 0

	// Get and format header. Add killing attacker statistics if user is dead.
	// Make sure shots is greater than zero or division by zero will occur.
	// To print a '%', 4 of them must done in a row.
	izStats[STATS_SHOTS] = 0
	iAttacker = g_izKilled[id][KILLED_KILLER_ID]
	
	if (iAttacker)
		get_user_astats(id, iAttacker, izStats, izBody)
	
	if (izStats[STATS_SHOTS] && ShowFullStats)
	{
		get_user_name(iAttacker, t_sName, MAX_NAME_LENGTH)
		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L -- %s -- %0.2f%% %L:^n", id, "ATTACKERS", t_sName, accuracy(izStats), id, "ACC")
	}
	else
		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L:^n", id, "ATTACKERS")

	// Get and format attacker list.
	for (iAttacker = 1; iAttacker <= iMaxPlayer; iAttacker++)
	{
		if (get_user_astats(id, iAttacker, izStats, izBody, t_sWpn, MAX_WEAPON_LENGTH))
		{
			iFound = 1
			get_user_name(iAttacker, t_sName, MAX_NAME_LENGTH)
			
			if (izStats[STATS_KILLS])
			{
				if (!ShowDistHS)
					iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L / %s^n", t_sName, izStats[STATS_HITS], id, "HIT_S", 
									izStats[STATS_DAMAGE], id, "DMG", t_sWpn)
				else if (izStats[STATS_HS])
					iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L / %s / %0.0f m / MM_HS^n", t_sName, izStats[STATS_HITS], id, "HIT_S", 
									izStats[STATS_DAMAGE], id, "DMG", t_sWpn, distance(g_izUserAttackerDistance[id]))
				else
					iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L / %s / %0.0f m^n", t_sName, izStats[STATS_HITS], id, "HIT_S", 
									izStats[STATS_DAMAGE], id, "DMG", t_sWpn, distance(g_izUserAttackerDistance[id]))
			}
			else
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L^n", t_sName, izStats[STATS_HITS], id, "HIT_S", izStats[STATS_DAMAGE], id, "DMG")
		}
	}
	
	if (!iFound)
		sBuffer[0] = 0
	
	return iFound
}

// Get and format victims header and list
get_victims(id, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new izStats[8], izBody[8]
	new iVictim
	new iFound, iLen
	new iMaxPlayer = get_maxplayers()

	iFound = 0
	sBuffer[0] = 0

	// Get and format header.
	// Make sure shots is greater than zero or division by zero will occur.
	// To print a '%', 4 of them must done in a row.
	izStats[STATS_SHOTS] = 0
	get_user_vstats(id, 0, izStats, izBody)
	
	if (izStats[STATS_SHOTS])
		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L -- %0.2f%% %L:^n", id, "VICTIMS", accuracy(izStats), id, "ACC")
	else
		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L:^n", id, "VICTIMS")

	for (iVictim = 1; iVictim <= iMaxPlayer; iVictim++)
	{
		if (get_user_vstats(id, iVictim, izStats, izBody, t_sWpn, MAX_WEAPON_LENGTH))
		{
			iFound = 1
			get_user_name(iVictim, t_sName, MAX_NAME_LENGTH)
			
			if (izStats[STATS_DEATHS])
			{
				if (!ShowDistHS)
					iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L / %s^n", t_sName, izStats[STATS_HITS], id, "HIT_S", 
									izStats[STATS_DAMAGE], id, "DMG", t_sWpn)
				else if (izStats[STATS_HS])
					iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L / %s / %0.0f m / MM_HS^n", t_sName, izStats[STATS_HITS], id, "HIT_S", 
									izStats[STATS_DAMAGE], id, "DMG", t_sWpn, distance(g_izUserVictimDistance[id][iVictim]))
				else
					iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L / %s / %0.0f m^n", t_sName, izStats[STATS_HITS], id, "HIT_S", 
									izStats[STATS_DAMAGE], id, "DMG", t_sWpn, distance(g_izUserVictimDistance[id][iVictim]))
			}
			else
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%s -- %d %L / %d %L^n", t_sName, izStats[STATS_HITS], id, "HIT_S", izStats[STATS_DAMAGE], id, "DMG")
		}
	}
	
	if (!iFound)
		sBuffer[0] = 0

	return iFound
}

// Get and format kill info.
get_kill_info(id, iKiller, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iFound, iLen

	iFound = 0
	sBuffer[0] = 0

	if (iKiller && iKiller != id)
	{
		new izAStats[8], izABody[8], izVStats[8], iaVBody[8]

		iFound = 1
		get_user_name(iKiller, t_sName, MAX_NAME_LENGTH)

		izAStats[STATS_HITS] = 0
		izAStats[STATS_DAMAGE] = 0
		t_sWpn[0] = 0
		get_user_astats(id, iKiller, izAStats, izABody, t_sWpn, MAX_WEAPON_LENGTH)

		izVStats[STATS_HITS] = 0
		izVStats[STATS_DAMAGE] = 0
		get_user_vstats(id, iKiller, izVStats, iaVBody)

		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L^n", id, "KILLED_YOU_DIST", t_sName, t_sWpn, distance(g_izUserAttackerDistance[id]))
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%L^n", id, "DID_DMG_HITS", izAStats[STATS_DAMAGE], izAStats[STATS_HITS], g_izKilled[id][KILLED_KILLER_HEALTH], g_izKilled[id][KILLED_KILLER_ARMOUR])
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%L^n", id, "YOU_DID_DMG", izVStats[STATS_DAMAGE], izVStats[STATS_HITS])
	}
	
	return iFound
}

// Get and format most disruptive.
add_most_disruptive(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new id, iMaxDamageId, iMaxDamage, iMaxHeadShots

	iMaxDamageId = 0
	iMaxDamage = 0
	iMaxHeadShots = 0

	// Find player.
	for (id = 1; id < MAX_PLAYERS; id++)
	{
		if (g_izUserRndStats[id][STATS_DAMAGE] >= iMaxDamage && (g_izUserRndStats[id][STATS_DAMAGE] > iMaxDamage || g_izUserRndStats[id][STATS_HS] > iMaxHeadShots))
		{
			iMaxDamageId = id
			iMaxDamage = g_izUserRndStats[id][STATS_DAMAGE]
			iMaxHeadShots = g_izUserRndStats[id][STATS_HS]
		}
	}

	// Format statistics.
	if (iMaxDamageId)
	{
		id = iMaxDamageId
		
		new Float:fGameEff = effec(g_izUserGameStats[id])
		new Float:fRndAcc = accuracy(g_izUserRndStats[id])
		
		format(t_sText, MAX_TEXT_LENGTH, "%L: %s^n%d %L / %d %L -- %0.2f%% %L / %0.2f%% %L^n", LANG_SERVER, "MOST_DMG", g_izUserRndName[id], 
				g_izUserRndStats[id][STATS_HITS], LANG_SERVER, "HIT_S", iMaxDamage, LANG_SERVER, "DMG", fGameEff, LANG_SERVER, "EFF", fRndAcc, LANG_SERVER, "ACC")
		add(sBuffer, MAX_BUFFER_LENGTH, t_sText)
	}
	
	return iMaxDamageId
}

// Get and format best score.
add_best_score(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new id, iMaxKillsId, iMaxKills, iMaxHeadShots

	iMaxKillsId = 0
	iMaxKills = 0
	iMaxHeadShots = 0

	// Find player
	for (id = 1; id < MAX_PLAYERS; id++)
	{
		if (g_izUserRndStats[id][STATS_KILLS] >= iMaxKills && (g_izUserRndStats[id][STATS_KILLS] > iMaxKills || g_izUserRndStats[id][STATS_HS] > iMaxHeadShots))
		{
			iMaxKillsId = id
			iMaxKills = g_izUserRndStats[id][STATS_KILLS]
			iMaxHeadShots = g_izUserRndStats[id][STATS_HS]
		}
	}

	// Format statistics.
	if (iMaxKillsId)
	{
		id = iMaxKillsId
		
		new Float:fGameEff = effec(g_izUserGameStats[id])
		new Float:fRndAcc = accuracy(g_izUserRndStats[id])
		
		format(t_sText, MAX_TEXT_LENGTH, "%L: %s^n%d %L / %d hs -- %0.2f%% %L / %0.2f%% %L^n", LANG_SERVER, "BEST_SCORE", g_izUserRndName[id], 
				iMaxKills, LANG_SERVER, "KILL_S", iMaxHeadShots, fGameEff, LANG_SERVER, "EFF", fRndAcc, LANG_SERVER, "ACC")
		add(sBuffer, MAX_BUFFER_LENGTH, t_sText)
	}
	
	return iMaxKillsId
}

// Get and format team score.
add_team_score(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new Float:fzMapEff[MAX_TEAMS], Float:fzMapAcc[MAX_TEAMS], Float:fzRndAcc[MAX_TEAMS]

	// Calculate team stats
	for (new iTeam = 0; iTeam < MAX_TEAMS; iTeam++)
	{
		fzMapEff[iTeam] = effec(g_izTeamGameStats[iTeam])
		fzMapAcc[iTeam] = accuracy(g_izTeamGameStats[iTeam])
		fzRndAcc[iTeam] = accuracy(g_izTeamRndStats[iTeam])
	}

	// Format round team stats, MOTD
	format(t_sText, MAX_TEXT_LENGTH, "TERRORIST %d / %0.2f%% %L / %0.2f%% %L^nCT %d / %0.2f%% %L / %0.2f%% %L^n", g_izTeamScore[0], 
			fzMapEff[0], LANG_SERVER, "EFF", fzRndAcc[0], LANG_SERVER, "ACC", g_izTeamScore[1], fzMapEff[1], LANG_SERVER, "EFF", fzRndAcc[1], LANG_SERVER, "ACC")
	add(sBuffer, MAX_BUFFER_LENGTH, t_sText)
}

// Get and format team stats, chat version
save_team_chatscore()
{
	new Float:fzMapEff[MAX_TEAMS], Float:fzMapAcc[MAX_TEAMS], Float:fzRndAcc[MAX_TEAMS]

	// Calculate team stats
	for (new iTeam = 0; iTeam < MAX_TEAMS; iTeam++)
	{
		fzMapEff[iTeam] = effec(g_izTeamGameStats[iTeam])
		fzMapAcc[iTeam] = accuracy(g_izTeamGameStats[iTeam])
		fzRndAcc[iTeam] = accuracy(g_izTeamRndStats[iTeam])
	}

	// Format game team stats, chat
	format(g_sScore, MAX_BUFFER_LENGTH, "%L $t%d $g/ $t%0.2f%%$g %L / $t%0.2f%% $g%L  --  %L $t%d $g/ $t%0.2f%% $g%L / $t%0.2f%% $g%L", LANG_SERVER, "MM_T", g_izTeamScore[0], 
			fzMapEff[0], LANG_SERVER, "EFF", fzMapAcc[0], LANG_SERVER, "ACC", LANG_SERVER, "MM_CT", g_izTeamScore[1], fzMapEff[1], LANG_SERVER, "EFF", fzMapAcc[1], LANG_SERVER, "ACC")
}

// Get and format total stats.
add_total_stats(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	format(t_sText, MAX_TEXT_LENGTH, "%L: %d %L / %d hs -- %d %L / %d %L^n", LANG_SERVER, "TOTAL", g_izUserRndStats[0][STATS_KILLS], LANG_SERVER, "KILL_S", 
			g_izUserRndStats[0][STATS_HS], g_izUserRndStats[0][STATS_HITS], LANG_SERVER, "HITS", g_izUserRndStats[0][STATS_SHOTS], LANG_SERVER, "SHOT_S")
	add(sBuffer, MAX_BUFFER_LENGTH, t_sText)
}

// Get and format a user's list of body hits from an attacker.
add_attacker_hits(id, iAttacker, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iFound = 0
	
	if (iAttacker && iAttacker != id)
	{
		new izStats[8], izBody[8], iLen

		izStats[STATS_HITS] = 0
		get_user_astats(id, iAttacker, izStats, izBody)

		if (izStats[STATS_HITS])
		{
			iFound = 1
			iLen = strlen(sBuffer)
			get_user_name(iAttacker, t_sName, MAX_NAME_LENGTH)
			
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%L:^n", id, "HITS_YOU_IN", t_sName)
			
			for (new i = 1; i < 8; i++)
			{
				if (!izBody[i])
					continue
				
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%L: %d^n", id, MM_BODY_PART[i], izBody[i])
			}
		}
	}
	
	return iFound
}

// Get and format killed stats: killer hp, ap, hits.
format_kill_ainfo(id, iKiller, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iFound = 0
	
	if (iKiller && iKiller != id)
	{
		new izStats[8], izBody[8]
		new iLen
		
		iFound = 1
		get_user_name(iKiller, t_sName, MAX_NAME_LENGTH)
		izStats[STATS_HITS] = 0
		get_user_astats(id, iKiller, izStats, izBody, t_sWpn, MAX_WEAPON_LENGTH)

		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L (%d%L, %d%L) $g>>", id, "KILLED_BY_WITH", t_sName, t_sWpn, distance(g_izUserAttackerDistance[id]), 
						g_izKilled[id][KILLED_KILLER_HEALTH], id, "MM_HP",  g_izKilled[id][KILLED_KILLER_ARMOUR], id, "MM_AP")

		if (izStats[STATS_HITS])
		{
			for (new i = 1; i < 8; i++)
			{
				if (!izBody[i])
					continue
				
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, " $g%L: $t%d$g", id, MM_BODY_PART[i], izBody[i])
			}
		}
		else
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, " %L", id, "NO_HITS")
	}
	else
		format(sBuffer, MAX_BUFFER_LENGTH, "%L", id, "YOU_NO_KILLER")
	
	return iFound
}

// Get and format killed stats: hits, damage on killer.
format_kill_vinfo(id, iKiller, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iFound = 0
	new izStats[8]
	new izBody[8]
	new iLen

	izStats[STATS_HITS] = 0
	izStats[STATS_DAMAGE] = 0
	get_user_vstats(id, iKiller, izStats, izBody)

	if (iKiller && iKiller != id)
	{
		iFound = 1
		get_user_name(iKiller, t_sName, MAX_NAME_LENGTH)
		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L $g>>", id, "YOU_HIT", t_sName, izStats[STATS_HITS], izStats[STATS_DAMAGE])
	}
	else
		iLen = format(sBuffer, MAX_BUFFER_LENGTH, "%L $g>>", id, "LAST_RES", izStats[STATS_HITS], izStats[STATS_DAMAGE])

	if (izStats[STATS_HITS])
	{
		for (new i = 1; i < 8; i++)
		{
			if (!izBody[i])
				continue
			
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, " $g%L: $t%d$g", id, MM_BODY_PART[i], izBody[i])
		}
	}
	else
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, " %L", id, "NO_HITS")
	
	return iFound
}

// MastaMan Edition
format_topx(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new izStats[8], izBody[8]
	new iLen = 0

	new lKills[30], lDeaths[30], lHits[30], lShots[30], lEff[30], lAcc[30], lHs[30], lNick[30], lPot[45]
	
	
	format(lNick, 29, "%L", LANG_SERVER, "MM_NICK")
	replace_all(lNick, 29, " ", "&nbsp")
	format(lKills, 29, "%L", LANG_SERVER, "KILLS")
	format(lDeaths, 29, "%L", LANG_SERVER, "DEATHS")
	format(lHits, 29, "%L", LANG_SERVER, "HITS")
	format(lShots, 29, "%L", LANG_SERVER, "SHOTS")
	format(lHs, 29, "%L", LANG_SERVER, "MM_HS")
	replace_all(lHs, 29, " ", "&nbsp")
	format(lEff, 29, "%L", LANG_SERVER, "MM_EFF")
	format(lAcc, 29, "%L", LANG_SERVER, "MM_ACC")
	format(lPot, 44, "%L", LANG_SERVER, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	
	iLen = format_all_themes(sBuffer, iLen)
	
		
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><table width=100%% border=0 align=center cellpadding=0 cellspacing=1>")	
	
	if(get_pcvar_num(pcvar_style))
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs, lPot)
	}
	else
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs)
	}
		
	for (new i = iTopX; i < iTopEnd && MAX_BUFFER_LENGTH - iLen > 0; i++)
	{
		iLen = format_all_stats(g_sBuffer, izStats, izBody, iLen, i)
	}
}

// MastaMan Edition
format_place1(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iMax = get_statsnum()
	new izStats[8], izBody[8]
	new iLen = 0

	if(get_pcvar_num(pcvar_style))
	{
		if (iMax > 10)
			iMax = 10
	}
	else
	{
		if (iMax > 15)
			iMax = 15
	}

	new lFirstPlace[60], lKills[30], lDeaths[30], lHits[30], lShots[30], lEff[30], lAcc[30], lHs[30], lNick[30], lPot[45]
	
	
	format(lFirstPlace, 59, "%L", LANG_SERVER, "MM_FIRSTPLACE")
	format(lNick, 29, "%L", LANG_SERVER, "MM_NICK")
	replace_all(lNick, 29, " ", "&nbsp")
	format(lKills, 29, "%L", LANG_SERVER, "KILLS")
	format(lDeaths, 29, "%L", LANG_SERVER, "DEATHS")
	format(lHits, 29, "%L", LANG_SERVER, "HITS")
	format(lShots, 29, "%L", LANG_SERVER, "SHOTS")
	format(lHs, 29, "%L", LANG_SERVER, "MM_HS")
	replace_all(lHs, 29, " ", "&nbsp")
	format(lEff, 29, "%L", LANG_SERVER, "MM_EFF")
	format(lAcc, 29, "%L", LANG_SERVER, "MM_ACC")
	format(lPot, 44, "%L", LANG_SERVER, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	iLen = format_all_themes(sBuffer, iLen)
	
	if(get_pcvar_num(pcvar_style))
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h2>%s</h2> <table width=100%% border=0 align=center cellpadding=0 cellspacing=1>", lFirstPlace)
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs, lPot)
	}
	else
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><table width=100%% border=0 align=center cellpadding=0 cellspacing=1>")
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs)
	}
		
	
	for (new i = 0; i < iMax && MAX_BUFFER_LENGTH - iLen > 0; i++)
	{
		iLen = format_all_stats(g_sBuffer, izStats, izBody, iLen, i)
	}
}

format_all_themes(sBuffer[MAX_BUFFER_LENGTH + 1], iLen)
{
	if(get_pcvar_num(pcvar_design)<= STATSX_SHELL_DESIGN_MAX)
	{
		iDesign = get_pcvar_num(pcvar_design)
	}
	else
	{
		if(get_pcvar_num(pcvar_design) == (STATSX_SHELL_DESIGN_MAX + 1))
		{
			iDesign = random_num(1,STATSX_SHELL_DESIGN_MAX)
		}
	}
			
	switch(iDesign)
	{
		case 1:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN1_STYLE)
		}
		
		case 2:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN2_STYLE)
		}
		
		case 3:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN3_STYLE)
		}
		
		case 4:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN4_STYLE)
		}
		
		case 5:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN5_STYLE)
		}
		
		case 6:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN6_STYLE)
		}
		
		case 7:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN7_STYLE)
		}
		
		case 8:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN8_STYLE)
		}
		
		case 9:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN9_STYLE)
		}
		
		case 10:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN10_STYLE)
		}
		
		case 11:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN11_STYLE)
		}
		
		case 12:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN12_STYLE)
		}
		
		case 13:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DESIGN13_STYLE)
		}

		default:
		{
			iLen = format(sBuffer, MAX_BUFFER_LENGTH, STATSX_SHELL_DEFAULT_STYLE)			
		}
	}
		
	return iLen
}

format_all_stats(sBuffer[MAX_BUFFER_LENGTH + 1], izStats[8], izBody[8], iLen, i)
{
	get_stats(i, izStats, izBody, t_sName, MAX_NAME_LENGTH)
	replace_all(t_sName, MAX_NAME_LENGTH, "<", "&lt")
	replace_all(t_sName, MAX_NAME_LENGTH, ">", "&gt")
		
	if (szTrigger)
	{
		szTrigger = false
		
		if(get_pcvar_num(pcvar_style))
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%d<td>%s<td>%d<td>%d<td>%d", i + 1, t_sName, izStats[STATS_KILLS], 
				izStats[STATS_DEATHS], izStats[STATS_HS])
				
			if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
			{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img id=r width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
			}
			else
			{
					iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
			}
		}
		else
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%d<td>%s<td>%d<td>%d<td>%d</tr>", i + 1, t_sName, izStats[STATS_KILLS], 
				izStats[STATS_DEATHS], izStats[STATS_HS])

		}
	}
	else
	{
		szTrigger = true
		
		if(get_pcvar_num(pcvar_style))
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%d<td>%s<td>%d<td>%d<td>%d", i + 1, t_sName, izStats[STATS_KILLS], 
					izStats[STATS_DEATHS], izStats[STATS_HS])
				
			if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
			{
				
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img id=r width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
			}
			else
			{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
			}
		}
		else
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%d<td>%s<td>%d<td>%d<td>%d</tr>", i + 1, t_sName, izStats[STATS_KILLS], 
				izStats[STATS_DEATHS], izStats[STATS_HS])
		}
	}
	
	return iLen
}

format_dmg_stats(sBuffer[MAX_BUFFER_LENGTH + 1], izStats[8], iLen, i)
{
	if (szTrigger)
	{
		szTrigger = false

		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%d<td>%s<td>%d<td>%d<td>%d</tr>", i + 1, t_sName, izStats[STATS_DAMAGE], izStats[STATS_KILLS], 
			izStats[STATS_DEATHS])
			
		if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img id=r width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
		else
		{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
	
	}
	else
	{
		szTrigger = true
		
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%d<td>%s<td>%d<td>%d<td>%d", i + 1, t_sName, izStats[STATS_DAMAGE], 
				izStats[STATS_DEATHS], izStats[STATS_HS])
			
		if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img id=r width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
		else
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
	}
	
	return iLen
}

format_hs_stats(sBuffer[MAX_BUFFER_LENGTH + 1], izStats[8], iLen, i)
{
	if (szTrigger)
	{
		szTrigger = false

		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%d<td>%s<td>%d<td>%d<td>%d</tr>", i + 1, t_sName, izStats[STATS_HS], izStats[STATS_KILLS], 
			izStats[STATS_DEATHS])
			
		if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img id=r width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
		else
		{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
	
	}
	else
	{
		szTrigger = true
		
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%d<td>%s<td>%d<td>%d<td>%d", i + 1, t_sName, izStats[STATS_HS], 
				izStats[STATS_DEATHS], izStats[STATS_HS])
			
		if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img id=r width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
		else
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td><img width=%3.0f%%>%2.0f%%</tr>", (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
		}
	}
	
	return iLen
}

// MastaMan Edition
format_place2(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iMax = get_statsnum()
	new izStats[8], izBody[8]
	new iLen = 0

	if(get_pcvar_num(pcvar_style))
	{
		if (iMax > 20)
			iMax = 20
	}
	else
	{
		if (iMax > 15)
			iMax = 15
	}

	new lSecondPlace[60], lKills[30], lDeaths[30], lHits[30], lShots[30], lEff[30], lAcc[30], lHs[30], lNick[30], lPot[45]
	
	
	format(lSecondPlace, 59, "%L", LANG_SERVER, "MM_SECONDPLACE")
	format(lNick, 29, "%L", LANG_SERVER, "MM_NICK")
	replace_all(lNick, 29, " ", "&nbsp")
	format(lKills, 29, "%L", LANG_SERVER, "KILLS")
	format(lDeaths, 29, "%L", LANG_SERVER, "DEATHS")
	format(lHits, 29, "%L", LANG_SERVER, "HITS")
	format(lShots, 29, "%L", LANG_SERVER, "SHOTS")
	format(lHs, 29, "%L", LANG_SERVER, "MM_HS")
	replace_all(lHs, 29, " ", "&nbsp")
	format(lEff, 29, "%L", LANG_SERVER, "MM_EFF")
	format(lAcc, 29, "%L", LANG_SERVER, "MM_ACC")
	format(lPot, 44, "%L", LANG_SERVER, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	iLen = format_all_themes(sBuffer, iLen)
	
	if(get_pcvar_num(pcvar_style))
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h2>%s</h2> <table width=100%% border=0 align=center cellpadding=0 cellspacing=1>", lSecondPlace)
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs, lPot)
	}
	else
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><table width=100%% border=0 align=center cellpadding=0 cellspacing=1>")
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs)
	}
	
	for (new i = 10; i < iMax && MAX_BUFFER_LENGTH - iLen > 0; i++)
	{
		iLen = format_all_stats(g_sBuffer, izStats, izBody, iLen, i)	
	}
}

// MastaMan Edition
format_place3(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iMax = get_statsnum()
	new izStats[8], izBody[8]
	new iLen = 0

	if(get_pcvar_num(pcvar_style))
	{
		if (iMax > 30)
			iMax = 30
	}
	else
	{
		if (iMax > 15)
			iMax = 15
	}
	
	new lThirdPlace[60], lKills[30], lDeaths[30], lHits[30], lShots[30], lEff[30], lAcc[30], lHs[30], lNick[30], lPot[45]
	
	
	format(lThirdPlace, 59, "%L", LANG_SERVER, "MM_THIRDPLACE")
	format(lNick, 29, "%L", LANG_SERVER, "MM_NICK")
	replace_all(lNick, 29, " ", "&nbsp")
	format(lKills, 29, "%L", LANG_SERVER, "KILLS")
	format(lDeaths, 29, "%L", LANG_SERVER, "DEATHS")
	format(lHits, 29, "%L", LANG_SERVER, "HITS")
	format(lShots, 29, "%L", LANG_SERVER, "SHOTS")
	format(lHs, 29, "%L", LANG_SERVER, "MM_HS")
	replace_all(lHs, 29, " ", "&nbsp")
	format(lEff, 29, "%L", LANG_SERVER, "MM_EFF")
	format(lAcc, 29, "%L", LANG_SERVER, "MM_ACC")
	format(lPot, 44, "%L", LANG_SERVER, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	iLen = format_all_themes(sBuffer, iLen)
	
	if(get_pcvar_num(pcvar_style))
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h2>%s</h2> <table width=100%% border=0 align=center cellpadding=0 cellspacing=1>", lThirdPlace)
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs, lPot)
	}
	else
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><table width=100%% border=0 align=center cellpadding=0 cellspacing=1>")
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><tr><th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs)
	}
	
	for (new i = 20; i < iMax && MAX_BUFFER_LENGTH - iLen > 0; i++)
	{
		iLen = format_all_stats(g_sBuffer, izStats, izBody, iLen, i)
	}
}


// MastaMan Edition
format_bot10(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iMax = get_statsnum()
	new iBotX = iMax - 10
	new izStats[8], izBody[8]
	new iLen = 0

	new lBot[60], lKills[30], lDeaths[30], lHits[30], lShots[30], lEff[30], lAcc[30], lHs[30], lNick[30], lPot[45]
	
	
	format(lBot, 59, "%L", LANG_SERVER, "MM_BOT")
	format(lNick, 29, "%L", LANG_SERVER, "MM_NICK")
	replace_all(lNick, 29, " ", "&nbsp")
	format(lKills, 29, "%L", LANG_SERVER, "KILLS")
	format(lDeaths, 29, "%L", LANG_SERVER, "DEATHS")
	format(lHits, 29, "%L", LANG_SERVER, "HITS")
	format(lShots, 29, "%L", LANG_SERVER, "SHOTS")
	format(lHs, 29, "%L", LANG_SERVER, "MM_HS")
	replace_all(lHs, 29, " ", "&nbsp")
	format(lEff, 29, "%L", LANG_SERVER, "MM_EFF")
	format(lAcc, 29, "%L", LANG_SERVER, "MM_ACC")
	format(lPot, 44, "%L", LANG_SERVER, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	iLen = format_all_themes(sBuffer, iLen)
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h2>%s</h2> <table width=100%% border=0 align=center cellpadding=0 cellspacing=1>", lBot)
	
	if(get_pcvar_num(pcvar_style))
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs, lPot)
	}
	else
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lKills, lDeaths, lHs)
	}
		
	
	for (new i = iMax - 1; i > iBotX && MAX_BUFFER_LENGTH - iLen > 0; i--)
	{
		iLen = format_all_stats(g_sBuffer, izStats, izBody, iLen, i)
	}
}

find_max_stats(g_iStatsBase[], iMax, iExcludeID[])
{
	new g_iDataMax = 0	
	new iId
	
	for(new j = 0; j < iMax; j++)
	{
		if(!iExcludeID[j])
		{
			if(g_iStatsBase[j] > g_iDataMax)
			{	
				g_iDataMax = g_iStatsBase[j]
				iExcludeID[j] = true
				iId = j
			}
		}
	}	
	
	
	return iId
}


// MastaMan Edition
format_top_dmg(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iMax = get_statsnum()
	new izStats[8], izBody[8]
	new iLen = 0

	new g_iStatsBase[MAX_SORT_COUNT]
	new bool:iExcludeID[MAX_SORT_COUNT]
	
	new lDmg_Place[60], lDamage[30], lKills[30], lDeaths[30], lHits[30], lEff[30], lAcc[30], lHs[30], lNick[30], lPot[45]
	
	
	if (iMax > MAX_SORT_COUNT)
	{
		iMax = MAX_SORT_COUNT
	}
	
		
	for(new i = 0; i < iMax; i++)
	{
		get_stats(i, izStats, izBody, t_sName, MAX_NAME_LENGTH)
		
		g_iStatsBase[i] = izStats[STATS_DAMAGE]
	}
	

	
	format(lDmg_Place, 59, "%L", LANG_SERVER, "MM_DMG_PLACE")
	format(lNick, 29, "%L", LANG_SERVER, "MM_NICK")
	replace_all(lNick, 29, " ", "&nbsp")
	format(lDamage, 29, "%L", LANG_SERVER, "MM_DAMAGE")
	format(lKills, 29, "%L", LANG_SERVER, "KILLS")
	format(lDeaths, 29, "%L", LANG_SERVER, "DEATHS")
	format(lHits, 29, "%L", LANG_SERVER, "HITS")
	format(lHs, 29, "%L", LANG_SERVER, "MM_HS")
	replace_all(lHs, 29, " ", "&nbsp")
	format(lEff, 29, "%L", LANG_SERVER, "MM_EFF")
	format(lAcc, 29, "%L", LANG_SERVER, "MM_ACC")
	format(lPot, 44, "%L", LANG_SERVER, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	iLen = format_all_themes(sBuffer, iLen)
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h2>%s</h2> <table width=100%% border=0 align=center cellpadding=0 cellspacing=1>", lDmg_Place)
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lDamage, lKills, lDeaths,  lPot)
			
	for(new i = 0; i < 10; i++)
	{
		get_stats(find_max_stats(g_iStatsBase, iMax, iExcludeID), izStats, izBody, t_sName, MAX_NAME_LENGTH)
		replace_all(t_sName, MAX_NAME_LENGTH, "<", "&lt")
		replace_all(t_sName, MAX_NAME_LENGTH, ">", "&gt")
		
		iLen = format_dmg_stats(g_sBuffer, izStats, iLen, i)
	}
}

// MastaMan Edition
format_top_hs(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iMax = get_statsnum()
	new izStats[8], izBody[8]
	new iLen = 0

	new g_iStatsBase[MAX_SORT_COUNT]
	new bool:iExcludeID[MAX_SORT_COUNT]
	
	new lHs_Place[60], lKills[30], lDeaths[30], lHits[30], lEff[30], lAcc[30], lHs[30], lNick[30], lPot[45]
	
	
	if (iMax > MAX_SORT_COUNT)
	{
		iMax = MAX_SORT_COUNT
	}
	
		
	for(new i = 0; i < iMax; i++)
	{
		get_stats(i, izStats, izBody, t_sName, MAX_NAME_LENGTH)
		
		g_iStatsBase[i] = izStats[STATS_HS]
	}
	

	
	format(lHs_Place, 59, "%L", LANG_SERVER, "MM_HS_PLACE")
	format(lNick, 29, "%L", LANG_SERVER, "MM_NICK")
	replace_all(lNick, 29, " ", "&nbsp")
	format(lKills, 29, "%L", LANG_SERVER, "KILLS")
	format(lDeaths, 29, "%L", LANG_SERVER, "DEATHS")
	format(lHits, 29, "%L", LANG_SERVER, "HITS")
	format(lHs, 29, "%L", LANG_SERVER, "MM_HS")
	replace_all(lHs, 29, " ", "&nbsp")
	format(lEff, 29, "%L", LANG_SERVER, "MM_EFF")
	format(lAcc, 29, "%L", LANG_SERVER, "MM_ACC")
	format(lPot, 44, "%L", LANG_SERVER, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	iLen = format_all_themes(sBuffer, iLen)
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h2>%s</h2> <table width=100%% border=0 align=center cellpadding=0 cellspacing=1>", lHs_Place)
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s</tr>", "#", lNick, lHs, lKills, lDeaths,  lPot)
	
	for(new i = 0; i < 10; i++)
	{
		get_stats(find_max_stats(g_iStatsBase, iMax, iExcludeID), izStats, izBody, t_sName, MAX_NAME_LENGTH)
		replace_all(t_sName, MAX_NAME_LENGTH, "<", "&lt")
		replace_all(t_sName, MAX_NAME_LENGTH, ">", "&gt")
		
		iLen = format_hs_stats(g_sBuffer, izStats, iLen, i)
	}
}

format_day(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new g_szDayData[12], szKey[6]
	new iLen = 0
	new lHeader[100], lTitle1[30], lTitle2[30], szDate[128]
			
	format_time(szDate, sizeof(szDate) - 1, "%d.%m.%Y")
	formatex(lHeader, 99, "%L %L", LANG_SERVER, "MM_ATTEND", LANG_SERVER, "MM_ATTEND_TO", szDate)
	formatex(lTitle1, 29, "%L", LANG_SERVER, "MM_TIME")
	formatex(lTitle2, 29, "%L", LANG_SERVER, "MM_ATTEND")
		
	iLen = format_all_themes(sBuffer, iLen)
	
	if (g_Vault == INVALID_HANDLE)
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h3>Read data from vault failure!...</h3>")
		
		return PLUGIN_HANDLED
	}
	
	//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h3>%s</h3>", lHeader)
	
	if(get_pcvar_num(pcvar_day) == 1)
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<center><table width=600 border=0 style=^"font-size:14px^">")
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr height=250 valign=bottom>")
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td>100%%<div style=^"padding:15%% 0^">50%% </div> 0%% </td><td>")
		
		for(new i = 0; i < 24; i++)
		{
			formatex(szKey, 5,"%d-h" , i)
			nvault_get(g_Vault , szKey, g_szDayData, 11)
				
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<img style=^"height:%d^" width=18>", str_to_num(g_szDayData) * (250 / get_maxplayers()))
		}
		
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "</td></tr><td></td><td>")
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<pre> 0.....2.....4.....6.....8.....10....12....14....16....18....20....22...</pre>")
	}
	
	if(get_pcvar_num(pcvar_day) > 1)
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<center><table border=0 cellpadding=0 cellspacing=1px>")
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<th>%s<th width=250>%s", lTitle1, lTitle2)
		
		for(new i = 0; i < 24; i++)
		{
			formatex(szKey, 5,"%d-h" , i)
			nvault_get(g_Vault , szKey, g_szDayData, 11)
			
			if(szTrigger)
			{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%d:00<td><img width=%d> %d", i, (str_to_num(g_szDayData) * (250 / get_maxplayers())) - 10, str_to_num(g_szDayData))
				
				szTrigger = false
			}
			else
			{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%d:00<td><img width=%d> %d", i, (str_to_num(g_szDayData) * (250 / get_maxplayers())) - 10, str_to_num(g_szDayData))
				
				szTrigger = true
			}
		}
		
	}
	
	return PLUGIN_CONTINUE
}


format_played_time(id, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new iLen = 0
	new lTime[30], lName[30], szName[33], szTmpName[32]
	new szPlayers[32], iNum, szKey[32], szData[128]
	new lYear[30], lMonth[30], lDay[30], lWeek[30], lHour[30], lMinute[30]
	
	formatex(lYear, 29, "%L", LANG_SERVER, "MM_YEAR")
	formatex(lMonth, 29, "%L", LANG_SERVER, "MM_MONTH")
	formatex(lWeek, 29, "%L", LANG_SERVER, "MM_WEEK")
	formatex(lDay, 29, "%L", LANG_SERVER, "MM_DAY")
	formatex(lHour, 29, "%L", LANG_SERVER, "MM_HOUR")
	formatex(lMinute, 29, "%L", LANG_SERVER, "MM_MIN")
		
	formatex(lName, 29, "%L", LANG_SERVER, "MM_NICK")
	formatex(lTime, 29, "%L", LANG_SERVER, "MM_TIME")
		
	iLen = format_all_themes(sBuffer, iLen)
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><center><table border=0 width=50%%><th>#<th>%s<th>%s", lName, lTime)

	get_players(szPlayers, iNum)
	for(new i = 0; i < iNum; i++)
	{
		new iYear, iMonth, iDay, iWeek, iHour, iMinute, szTime[64]
		
		get_user_name(szPlayers[i], szName, sizeof(szName) - 1)
			
		get_user_name(id, szTmpName, sizeof(szTmpName) - 1)
		formatex(szKey, sizeof(szKey) - 1, "PLAYED_TIME#%s", szName)
				
		nvault_get(g_Vault2, szKey, szData, sizeof(szData) - 1)
		
		new iTime = str_to_num(szData) + get_user_time(szPlayers[i])
				
		if(iTime / MM_MINUTE)
		{
			iMinute = iTime / MM_MINUTE
			formatex(szTime, sizeof(szTime) - 1, "%d %s", iMinute, lMinute)
		}
		else
		{
			continue
		}
		
		if(iTime / MM_HOUR)
		{
			iHour = iTime / MM_HOUR
			iMinute = (iTime - (iHour * MM_HOUR)) / MM_MINUTE 
			formatex(szTime, sizeof(szTime) - 1, "%d %s %d %s", iHour, lHour, iMinute, lMinute)
		}
		
		if(iTime / MM_DAY)
		{
			iDay = iTime / MM_DAY
			iHour = (iTime - (iDay * MM_DAY)) / MM_HOUR
			formatex(szTime, sizeof(szTime) - 1, "%d %s %d %s %d %s", iDay, lDay, iHour, lHour, iMinute, lMinute)
		}
		
		if(iTime / (MM_WEEK))
		{
			iWeek = iTime / (MM_WEEK)
			iDay = (iTime - (iWeek * (MM_WEEK))) / MM_DAY
			formatex(szTime, sizeof(szTime) - 1, "%d %s %d %s %d %s", iDay, iHour, iMinute )
		}
		
		if(iTime / MM_MONTH)
		{
			iMonth = iTime / MM_MONTH
			iWeek = (iTime - (iMonth * MM_MONTH)) / 604800
			formatex(szTime, sizeof(szTime) - 1, "%d month %d week %d day %d hour %d min", iMonth, iWeek , iDay, iHour, iMinute )
		}
		
		if((iTime / MM_YEAR) > 1)
		{
			iYear = iTime / MM_YEAR
			iMonth = (iTime - (iYear * MM_YEAR)) / MM_MONTH
			formatex(szTime, sizeof(szTime) - 1, "%d year %d month %d week %d day %d hour %d min", iYear, iMonth, iWeek, iDay, iHour, iMinute )
		}
				
		if(equal(szTmpName, szName))
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%d<td>%s<td>%s", i + 1, szName, szTime)
		}
		else
		{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%d<td>%s<td>%s", i + 1, szName, szTime)
		}
	}
	
	return PLUGIN_CONTINUE
}

// MastaMan Edition
format_award(sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new izStats[8], izBody[8], szName[3][MAX_NAME_LENGTH], id
	new iLen = 0
	new Float:izAwardCash_Bonus[3], Float:izAwardSkil_Level[3],  izCash
			
	new lBonus[30]
		
	format(lBonus, 29, "%L", LANG_SERVER, "MM_BONUS")
	
	iLen = format_all_themes(sBuffer, iLen)

	id = iAwardID
	for(new i = 0; i < 3; i++)
	{
		get_stats(id, izStats, izBody, t_sName, MAX_NAME_LENGTH)
		replace_all(t_sName, MAX_NAME_LENGTH, "<", "&lt")
		replace_all(t_sName, MAX_NAME_LENGTH, ">", "&gt")
		
		copy(szName[i], MAX_NAME_LENGTH - 1, t_sName)
		
		izAwardCash_Bonus[i] = get_pcvar_num(pcvar_award_cash) * (((effec(izStats) + accuracy(izStats)) / 2) / 100)
		izAwardSkil_Level[i] = ((effec(izStats) + accuracy(izStats)) / 2)
			
		id += 10
	}
	
	
	iAwardID = random_num(0, 9)
	
	iLen = format_all_themes(sBuffer, iLen)
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><center><br><br><div id=clr>%s</div>", szName[0])
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<table border=0 id=clr cellpadding=0 cellspacing=0><tr style=^"vertical-align:bottom^">")
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td align=right width=300><p>%s</p><div id=c style=^"border:1px solid;height:80px;width:100px;font-size:50px;text-align:center^">2</div></td>", szName[1])
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td width=100><div id=c style=^"border:1px solid;height:140px;width:100px;font-size:50px;text-align:center^">1</div></td>")
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td align=left width=300><p>%s</p><div id=c style=^"border:1px solid;height:50px;width:100px;font-size:50px;text-align:center^">3</div></td>", szName[2])
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "</tr></table><br>")
	
	if(get_pcvar_num(pcvar_award_cash))
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<table width=90%% cellspacing=1 cellspadding=0>")
	
		for(new i = 0; i < 3; i++)
		{
			izCash = get_pcvar_num(pcvar_award_cash) / (i + 1)
			
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%d<td>%s", i + 1, szName[i])
			
			if(izAwardSkil_Level[i] < 50.0)
			{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td width=150><img id=r width=%3.0f%%>%2.0f%%", izAwardSkil_Level[i], izAwardSkil_Level[i])
			}
			else
			{
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td width=150><img width=%3.0f%%>%2.0f%%", izAwardSkil_Level[i], izAwardSkil_Level[i])	
			}
			
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td>%d$ (+%0.0f$ %s)</tr>", izCash, izAwardCash_Bonus[i], lBonus)
		}
	}
}

// MastaMan Edition
format_rankstats(id, sBuffer[MAX_BUFFER_LENGTH + 1], iMyId = 0)
{
	new izStats[8] = {0, ...}
	new izBody[8]
	new iRankPos, iLen
	new lKills[30], lDeaths[30], lHits[30], lShots[30], lDamage[30], lEff[30], lAcc[30], lPot[45]
	
	format(lKills, 29, "%L", id, "KILLS")
	format(lDeaths, 29, "%L", id, "DEATHS")
	format(lHits, 29, "%L", id, "HITS")
	format(lShots, 29, "%L", id, "SHOTS")
	format(lDamage, 29, "%L", id, "MM_DAMAGE")
	format(lEff, 29, "%L", id, "MM_EFF")
	format(lAcc, 29, "%L", id, "MM_ACC")
	format(lPot, 44, "%L", id, "MM_POT")
	
	ucfirst(lEff)
	ucfirst(lAcc)

	iLen = format_all_themes(sBuffer, iLen)

	
	iRankPos = get_user_stats(id, izStats, izBody)
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><h3>%L %L</h3>", id, (!iMyId || iMyId == id) ? "YOUR" : "PLAYERS", id, "RANK_IS", iRankPos, get_statsnum())
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<table width=40%% style=^"float:left; margin:0 7%% 0 7%%^" border=0 cellpadding=0 cellspacing=1><th colspan=2>%L</td>", id, "MM_STAT")
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%s<td>%d &nbsp&nbsp(%L)<tr><td>%s<td>%d<tr id=c><td>%s<td>%d<tr><td>%s<td>%d<tr id=c><td>%s<td>%d<tr><td>%s<td>%0.2f%%<tr id=c>", 
					lKills, izStats[STATS_KILLS], id, "MM_WITH_HS",izStats[STATS_HS], lDeaths, izStats[STATS_DEATHS], lHits, izStats[STATS_HITS], lShots, izStats[STATS_SHOTS], 
					lDamage, izStats[STATS_DAMAGE], lAcc, accuracy(izStats))
	
	if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td>%s<td><img id=r width=%3.0f%%>%2.0f%%</tr>", lPot, (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
	}
	else
	{
			iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td>%s<td><img width=%3.0f%%>%2.0f%%</tr>", lPot, (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
	}
		
	new L_BODY_PART[8][32]
	
	for (new i = 1; i < 8; i++)
	{
		format(L_BODY_PART[i], 31, "%L", id, BODY_PART[i])
	}
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "</table><table width=40%% border=0 cellpadding=0 cellspacing=1><th colspan=2>%L</td>", id, "MM_HIT")
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%s<td>%d<tr><td>%s<td>%d<tr id=c><td>%s<td>%d<tr><td>%s<td>%d<tr id=c><td>%s<td>%d<tr><td>%s<td>%d<tr id=c><td>%s<td>%d", 
					L_BODY_PART[1], izBody[1], L_BODY_PART[2], izBody[2], L_BODY_PART[3], izBody[3], L_BODY_PART[4], izBody[4], L_BODY_PART[5], 
					izBody[5], L_BODY_PART[6], izBody[6], L_BODY_PART[7], izBody[7])
}

// MastaMan Edition
format_stats(id, sBuffer[MAX_BUFFER_LENGTH + 1])
{
	new izStats[8] = {0, ...}
	new izBody[8]
	new iWeapon, iLen
	new lKills[30], lDeaths[30], lHits[30], lShots[30], lDamage[30], lEff[30], lAcc[30], lWeapon[30], lPot[45]
	
	format(lKills, 29, "%L", id, "KILLS")
	format(lDeaths, 29, "%L", id, "DEATHS")
	format(lHits, 29, "%L", id, "HITS")
	format(lShots, 29, "%L", id, "SHOTS")
	format(lDamage, 29, "%L", id, "MM_DAMAGE")
	format(lEff, 29, "%L", id, "MM_EFF")
	format(lAcc, 29, "%L", id, "MM_ACC")
	format(lPot, 44, "%L", id, "MM_POT")
	format(lWeapon, 29, "%L", id, "WEAPON")
	
	ucfirst(lEff)
	ucfirst(lAcc)
		
	get_user_wstats(id, 0, izStats, izBody)

	iLen = format_all_themes(sBuffer, iLen)

	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<body><table width=50%% border=0 cellpadding=0 cellspacing=1><th colspan=2>%L</td>", id, "MM_STAT")
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr id=c><td>%s<td>%d &nbsp&nbsp(%L)<tr><td>%s<td>%d<tr id=c><td>%s<td>%d<tr><td>%s<td>%d<tr id=c><td>%s<td>%d<tr><td>%s<td>%0.2f<tr id=c><td>%s<td>%0.2f<tr>", 
		lKills, izStats[STATS_KILLS], id, "MM_WITH_HS",izStats[STATS_HS], lDeaths, izStats[STATS_DEATHS], lHits, izStats[STATS_HITS], lShots, izStats[STATS_SHOTS], 
		lDamage, izStats[STATS_DAMAGE], lEff, effec(izStats), lAcc, accuracy(izStats))
		
	if(((effec(izStats) + accuracy(izStats)) / 2) < 50)
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td>%s<td><img id=r width=%3.0f%%>%2.0f%%",  lPot, (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
	}
	else
	{
		iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<td>%s<td><img width=%3.0f%%>%2.0f%%",  lPot, (((effec(izStats) + accuracy(izStats)) / 2) / 1.3), ((effec(izStats) + accuracy(izStats)) / 2))
	}
	
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "</table><br><table width=90%% border=0 cellpadding=0 cellspacing=1>")
	
	iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><th>%s<th>%s<th>%s<th>%s<th>%s<th>%s<th>%s", lWeapon, lKills, lDeaths, lHits, lShots, lDamage, lAcc)
	
	new bool:szTrigger = true
	for (iWeapon = 1; iWeapon < xmod_get_maxweapons() && MAX_BUFFER_LENGTH - iLen > 0 ; iWeapon++)
	{				
		if (get_user_wstats(id, iWeapon, izStats, izBody))
		{
			xmod_get_wpnname(iWeapon, t_sWpn, MAX_WEAPON_LENGTH)
			if(szTrigger)
			{
				szTrigger = false
				
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr class=c><td>%s<td>%d<td>%d<td>%d<td>%d<td>%d<td>%3.0f", t_sWpn, izStats[STATS_KILLS], izStats[STATS_DEATHS], 
							izStats[STATS_HITS], izStats[STATS_SHOTS], izStats[STATS_DAMAGE], accuracy(izStats))
			}
			else
			{
				szTrigger = true
				
				iLen += format(sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "<tr><td>%s<td>%d<td>%d<td>%d<td>%d<td>%d<td>%3.0f", t_sWpn, izStats[STATS_KILLS], izStats[STATS_DEATHS], 
							izStats[STATS_HITS], izStats[STATS_SHOTS], izStats[STATS_DAMAGE], accuracy(izStats))
			}
		}
	}
}



// Show round end stats. If gametime is zero then use default duration time. 
show_roundend_hudstats(id, Float:fGameTime)
{
	// Bail out if there no HUD stats should be shown
	// for this player or end round stats not created.
	if (!g_izStatsSwitch[id]) return
	if (!g_sAwardAndScore[0]) return

	// If round end timer is zero clear round end stats.
	if (g_fShowStatsTime == 0.0)
	{
		ClearSyncHud(id, g_HudSync_EndRound)
#if defined STATSX_DEBUG
		log_amx("Clear round end HUD stats for #%d", id)
#endif
	}

	// Set HUD-duration to default or remaining time.
	new Float:fDuration
	
	if (fGameTime == 0.0)
		fDuration = g_fHUDDuration
	else
	{
		fDuration = g_fShowStatsTime + g_fHUDDuration - fGameTime
		
		if (fDuration > g_fFreezeTime + g_fFreezeLimitTime)
			fDuration = g_fFreezeTime + g_fFreezeLimitTime
	}
	
	// Show stats only if more time left than coded minimum.
	if (fDuration >= HUD_MIN_DURATION)
	{
		set_hudtype_endround(fDuration)
		ShowSyncHudMsg(id, g_HudSync_EndRound, "%s", g_sAwardAndScore)
#if defined STATSX_DEBUG
		log_amx("Show %1.2fs round end HUD stats for #%d", fDuration, id)
#endif
	}
}

// Show round end stats.
show_user_hudstats(id, Float:fGameTime)
{
	// Bail out if there no HUD stats should be shown
	// for this player or user stats timer is zero.
	if (!g_izStatsSwitch[id]) return
	if (g_fzShowUserStatsTime[id] == 0.0) return

	// Set HUD-duration to default or remaining time.
	new Float:fDuration
	
	if (fGameTime == 0.0)
		fDuration = g_fHUDDuration
	else
	{
		fDuration = g_fzShowUserStatsTime[id] + g_fHUDDuration - fGameTime
		
		if (fDuration > g_fFreezeTime + g_fFreezeLimitTime)
			fDuration = g_fFreezeTime + g_fFreezeLimitTime
	}

	// Show stats only if more time left than coded minimum.
	if (fDuration >= HUD_MIN_DURATION)
	{
		if (ShowKiller)
		{
			new iKiller
			
			iKiller = g_izKilled[id][KILLED_KILLER_ID]
			get_kill_info(id, iKiller, g_sBuffer)
			add_attacker_hits(id, iKiller, g_sBuffer)
			set_hudtype_killer(fDuration)
			show_hudmessage(id, "%s", g_sBuffer)
#if defined STATSX_DEBUG
			log_amx("Show %1.2fs %suser HUD k-stats for #%d", fDuration, g_sBuffer[0] ? "" : "no ", id)
#endif
		}
		
		if (ShowVictims)
		{
			get_victims(id, g_sBuffer)
			set_hudtype_victim(fDuration)
			show_hudmessage(id, "%s", g_sBuffer)
#if defined STATSX_DEBUG
			log_amx("Show %1.2fs %suser HUD v-stats for #%d", fDuration, g_sBuffer[0] ? "" : "no ", id)
#endif
		}
		
		if (ShowAttackers)
		{
			get_attackers(id, g_sBuffer)
			set_hudtype_attacker(fDuration)
			show_hudmessage(id, "%s", g_sBuffer)
#if defined STATSX_DEBUG
			log_amx("Show %1.2fs %suser HUD a-stats for #%d", fDuration, g_sBuffer[0] ? "" : "no ", id)
#endif
		}
	}
}

//------------------------------------------------------------
// Plugin commands
//------------------------------------------------------------

// Set or get plugin config flags.
public cmdPluginMode(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1)) 
		return PLUGIN_HANDLED
	
	if (read_argc() > 1)
		read_argv(1, g_sBuffer, MAX_BUFFER_LENGTH)
	else
		g_sBuffer[0] = 0
	
	set_plugin_mode(id, g_sBuffer)
	
	return PLUGIN_HANDLED
}

// Display MOTD stats.
public cmdStatsMe(id)
{
	if (!SayStatsMe)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}

	format_stats(id, g_sBuffer)
	
	get_user_name(id, t_sName, MAX_NAME_LENGTH)
	format(t_sName, MAX_NAME_LENGTH - 1, "StatsMe ^"%s^"", t_sName)
	
	show_motd(id, g_sBuffer, t_sName)
	
	return PLUGIN_CONTINUE
}

// Display MOTD rank.
public cmdRankStats(id)
{
	if (!SayRankStats)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_rankstats(id, g_sBuffer)
	
	get_user_name(id, t_sName, MAX_NAME_LENGTH)
	format(t_sName, MAX_NAME_LENGTH - 1, "RankStats ^"%s^"", t_sName)
	
	show_motd(id, g_sBuffer, t_sName)
	
	return PLUGIN_CONTINUE
}

//MastaMan Edition
public cmdTopX(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(pcvar_topx))
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	new szArg[128]
	read_args(szArg, 127)
	remove_quotes(szArg)
	new szTopX[32]

	new szMotdTitle[30]
	
	if(equal(szArg, "/top", 4))
	{
		copy(szTopX, charsmax(szTopX), szArg[4])
		
		iTopX = str_to_num(szTopX)

		if(get_pcvar_num(pcvar_style) && iTopX > 30)
		{
			if (get_statsnum() < iTopX + 10)
			{
				iTopEnd = get_statsnum()
				iTopX = iTopEnd - 10
				
				formatex(szMotdTitle, charsmax(szMotdTitle), "%L %d - %d", LANG_SERVER, "MM_TOPX_T", iTopX + 1, iTopEnd)
			}
			else
			{
				iTopX = iTopX - 1
				iTopEnd = iTopX + 10
			
				formatex(szMotdTitle, charsmax(szMotdTitle), "%L %d - %d", LANG_SERVER, "MM_TOPX_T", iTopX + 1, iTopEnd)
			}
			
			format_topx(g_sBuffer)

			show_motd(id, g_sBuffer, szMotdTitle)
		}
	}
	
	return PLUGIN_CONTINUE
}


// Display MOTD top15 ranked.
public cmdPlace1(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	new szMotdTitle[30]
	
	if(get_pcvar_num(pcvar_style))
	{
		formatex(szMotdTitle, charsmax(szMotdTitle), "10%L",id, "MM_PLACE")
	}
	else
	{
		szMotdTitle = "Top 15"
	}
	
	format_place1(g_sBuffer)
	show_motd(id, g_sBuffer, szMotdTitle)


	return PLUGIN_CONTINUE
}

public cmdPlace2(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_place2(g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, charsmax(szMotdTitle), "20%L",id, "MM_PLACE")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

public cmdPlace3(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_place3(g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, charsmax(szMotdTitle), "30%L",id, "MM_PLACE")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

public cmdBot10(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(pcvar_bot))
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_bot10(g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, charsmax(szMotdTitle), "%L",id, "MM_BOT_T")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

public cmdAward(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(pcvar_award))
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_award(g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, charsmax(szMotdTitle), "%L",id, "MM_AWARD_T")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

public cmdDay(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(pcvar_day))
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_day(g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, sizeof(szMotdTitle) - 1, "%L", LANG_SERVER, "MM_ATTEND")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

public cmdPlTime(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(pcvar_pt))
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
		
	format_played_time(id, g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, charsmax(szMotdTitle), "%L",id, "MM_PT_T")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

public cmdDmg(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(pcvar_dmg))
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_top_dmg(g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, charsmax(szMotdTitle), "%L",id, "MM_DMG_PLACE_T")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

public cmdHs(id)
{
	if (!SayTop15)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(pcvar_hs))
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_top_hs(g_sBuffer)
	
	new szMotdTitle[30]
	formatex(szMotdTitle, charsmax(szMotdTitle), "%L",id, "MM_HS_PLACE_T")
	show_motd(id, g_sBuffer, szMotdTitle)
	
	return PLUGIN_CONTINUE
}

// Display killer information.
public cmdHp(id)
{
	if (!SayHP)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	new iKiller = g_izKilled[id][KILLED_KILLER_ID]
	
	format_kill_ainfo(id, iKiller, g_sBuffer)
	colorChat(id, CHATCOLOR_RED, "* %s", g_sBuffer)
	
	return PLUGIN_CONTINUE
}

// Display user stats.
public cmdMe(id)
{
	if (!SayMe)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	format_kill_vinfo(id, 0, g_sBuffer)
	colorChat(id, CHATCOLOR_GREEN,"* %s", g_sBuffer)
	
	return PLUGIN_CONTINUE
}

// Display user rank
public cmdRank(id)
{
	if (!SayRank)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}

	new izStats[8], izBody[8]
	new iRankPos, iRankMax
		
	iRankPos = get_user_stats(id, izStats, izBody)
	iRankMax = get_statsnum()
	
	colorChat(id, CHATCOLOR_GREEN, "* %L", id, "YOUR_RANK_IS", iRankPos, iRankMax, izStats[STATS_KILLS], izStats[STATS_HITS], ((effec(izStats) + accuracy(izStats)) / 2))
	
	return PLUGIN_CONTINUE
}

// Report user weapon status to team.
public cmdReport(id)
{
	if (!SayReport)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	new iWeapon, iClip, iAmmo, iHealth, iArmor
	
	iWeapon = get_user_weapon(id, iClip, iAmmo) 
	
	if (iWeapon != 0)
		xmod_get_wpnname(iWeapon, t_sWpn, MAX_WEAPON_LENGTH)
	
	iHealth = get_user_health(id) 
	iArmor = get_user_armor(id)
	
	new lWeapon[16]
	
	format(lWeapon, 15, "%L", id, "WEAPON")
	strtolower(lWeapon)
	
	if (iClip >= 0)
	{
		format(g_sBuffer, MAX_BUFFER_LENGTH, "^x04%s: ^x03%s^x04, %L: ^x03%d/%d^x04, %L: ^x03%d^x04, %L: ^x03%d", lWeapon, t_sWpn, LANG_SERVER, "AMMO", iClip, iAmmo, LANG_SERVER, "HEALTH", iHealth, LANG_SERVER, "ARMOR", iArmor) 
	}
	else
		format(g_sBuffer, MAX_BUFFER_LENGTH, "^x04%s: ^x03%s^x04, %L: ^x03%d^x04, %L: ^x03%d", lWeapon, t_sWpn[7], LANG_SERVER, "HEALTH", iHealth, LANG_SERVER, "ARMOR", iArmor) 
	
	engclient_cmd(id, "say_team", g_sBuffer)
	
	return PLUGIN_CONTINUE
} 

// Display team map score
public cmdScore(id)
{
	if (!SayScore)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	colorChat(id, CHATCOLOR_GREEN, "%L: %s", id, "GAME_SCORE", g_sScore)
	
	return PLUGIN_CONTINUE
}

// Client switch to enable or disable stats announcements.
public cmdSwitch(id)
{
	g_izStatsSwitch[id] = (g_izStatsSwitch[id]) ? 0 : -1 
	num_to_str(g_izStatsSwitch[id], t_sText, MAX_TEXT_LENGTH)
	client_cmd(id, "setinfo _amxstatsx %s", t_sText)
	
	new lEnDis[32]
	
	format(lEnDis, 31, "%L", id, g_izStatsSwitch[id] ? "ENABLED" : "DISABLED")
	colorChat(id, CHATCOLOR_GREEN, "* %L", id, "STATS_ANNOUNCE", lEnDis)
	
	return PLUGIN_CONTINUE
}

// Player stats menu.
public cmdStats(id)
{
	if (!SayStatsAll)
	{
		colorChat(id, CHATCOLOR_RED, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
	}
	
	showStatsMenu(id, g_izUserMenuPosition[id] = 0)
	
	return PLUGIN_CONTINUE
}

//--------------------------------
// Menu
//--------------------------------

public actionStatsMenu(id, key)
{
	switch (key)
	{
		// Key '1' to '7', execute action on this option
		case 0..6:
		{
			new iOption, iIndex
			iOption = (g_izUserMenuPosition[id] * PPL_MENU_OPTIONS) + key
			
			if (iOption >= 0 && iOption < 32)
			{
				iIndex = g_izUserMenuPlayers[id][iOption]
			
				if (is_user_connected(iIndex))
				{
					switch (g_izUserMenuAction[id])
					{
						case 0: format_stats(iIndex, g_sBuffer)
						case 1: format_rankstats(iIndex, g_sBuffer, id)
						default: g_sBuffer[0] = 0
					}
					
					if (g_sBuffer[0])
					{
						get_user_name(iIndex, t_sName, MAX_NAME_LENGTH)
						show_motd(id, g_sBuffer, t_sName)
					}
				}
			}
			
			showStatsMenu(id, g_izUserMenuPosition[id])
		}
		// Key '8', change action
		case 7:
		{
			g_izUserMenuAction[id]++
			
			if (g_izUserMenuAction[id] >= MAX_PPL_MENU_ACTIONS)
				g_izUserMenuAction[id] = 0
			
			showStatsMenu(id, g_izUserMenuPosition[id])
		}
		// Key '9', select next page of options
		case 8: showStatsMenu(id, ++g_izUserMenuPosition[id])
		// Key '10', cancel or go back to previous menu
		case 9:
		{
			if (g_izUserMenuPosition[id] > 0)
				showStatsMenu(id, --g_izUserMenuPosition[id])
		}
	}
	
	return PLUGIN_HANDLED
}

new g_izUserMenuActionText[MAX_PPL_MENU_ACTIONS][62]

showStatsMenu(id, iMenuPos)
{
	formatex(g_izUserMenuActionText[0], charsmax(g_izUserMenuActionText[]),"\r%L", id, "MM_RANKSTATS")
	formatex(g_izUserMenuActionText[1], charsmax(g_izUserMenuActionText[]),"\r%L", id, "MM_RANK")
		
	new iLen, iKeyMask, iPlayers
	new iUserIndex, iMenuPosMax, iMenuOption, iMenuOptionMax
	
	get_players(g_izUserMenuPlayers[id], iPlayers)
	iMenuPosMax = ((iPlayers - 1) / PPL_MENU_OPTIONS) + 1
	
	// If menu pos does not excist use last menu (if players has left)
	if (iMenuPos >= iMenuPosMax)
		iMenuPos = iMenuPosMax - 1

	iUserIndex = iMenuPos * PPL_MENU_OPTIONS
	iLen = format(g_sBuffer, MAX_BUFFER_LENGTH, "\y%L\R%d/%d^n\w^n", id, "SERVER_STATS", iMenuPos + 1, iMenuPosMax)
	iMenuOptionMax = iPlayers - iUserIndex
	
	if (iMenuOptionMax > PPL_MENU_OPTIONS) 
		iMenuOptionMax = PPL_MENU_OPTIONS
	
	for (iMenuOption = 0; iMenuOption < iMenuOptionMax; iMenuOption++)
	{
		get_user_name(g_izUserMenuPlayers[id][iUserIndex++], t_sName, MAX_NAME_LENGTH)
		iKeyMask |= (1<<iMenuOption)
		iLen += format(g_sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "%d. %s^n\w", iMenuOption + 1, t_sName)
	}
	
	iKeyMask |= MENU_KEY_8|MENU_KEY_0
	iLen += format(g_sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "^n8. %s^n\w", g_izUserMenuActionText[g_izUserMenuAction[id]])
	
	if (iPlayers > iUserIndex)
	{
		iLen += format(g_sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "^n9. %L...", id, "MORE")
		iKeyMask |= MENU_KEY_9
	}
	
	if (iMenuPos > 0)
		iLen += format(g_sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "^n0. %L", id, "BACK")
	else
		iLen += format(g_sBuffer[iLen], MAX_BUFFER_LENGTH - iLen, "^n0. %L", id, "EXIT")
	
	show_menu(id, iKeyMask, g_sBuffer, -1, "Server Stats")
	
	return PLUGIN_HANDLED
}

//------------------------------------------------------------
// Plugin events
//------------------------------------------------------------

// Reset game stats on game start and restart.
public eventStartGame()
{
	read_data(2, t_sText, MAX_TEXT_LENGTH)
	
	if (t_sText[6] == 'w')
	{
		read_data(3, t_sText, MAX_TEXT_LENGTH)
		g_fStartGame = get_gametime() + float(str_to_num(t_sText))
	}
	else
		g_fStartGame = get_gametime()
	
	return PLUGIN_CONTINUE
}

// Round start
public eventStartRound()
{
	new iTeam, id, i
	
	if (read_data(1) >= floatround(get_cvar_float("mp_roundtime") * 60.0,floatround_floor))
	{
	
#if defined STATSX_DEBUG
		log_amx("Reset round stats")
#endif
		
		// Reset game stats on game start and restart.
		if (g_fStartGame > 0.0 && g_fStartGame <= get_gametime())
		{
#if defined STATSX_DEBUG
			log_amx("Reset game stats")
#endif
			

			g_fStartGame = 0.0

			// Clear team and game stats.
			for (iTeam = 0; iTeam < MAX_TEAMS; iTeam++)
			{
				g_izTeamEventScore[iTeam] = 0
				
				for (i = 0; i < 8; i++)
					g_izTeamGameStats[iTeam][i] = 0
			}

			// Clear game stats, incl '0' that is sum of all users.
			for (id = 0; id < MAX_PLAYERS; id++)
			{
				for (i = 0; i < 8; i++)
					g_izUserGameStats[id][i] = 0
			}
		}

		// Update team score with "TeamScore" event values and
		// clear team round stats.
		for (iTeam = 0; iTeam < MAX_TEAMS; iTeam++)
		{
			g_izTeamScore[iTeam] = g_izTeamEventScore[iTeam]
			
			for (i = 0; i < 8; i++)
				g_izTeamRndStats[iTeam][i] = 0
		}

		// Clear user round stats, incl '0' that is sum of all users.
		for (id = 0; id < MAX_PLAYERS; id++)
		{
			g_izUserRndName[id][0] = 0
			
			for (i = 0; i < 8; i++)
				g_izUserRndStats[id][i] = 0
			
			g_fzShowUserStatsTime[id] = 0.0
		}

		// Allow end round stats and reset end round triggered indicator.
		g_iRoundEndTriggered = 0
		g_iRoundEndProcessed = 0
		g_fShowStatsTime = 0.0

		// Update local configuration vars with value in cvars.
		get_config_cvars()
	}

	return PLUGIN_CONTINUE
}

// Reset killer info on round restart.
public eventResetHud(id)
{
	new args[1]
	args[0] = id
	
	if (g_iPluginMode & MODE_HUD_DELAY)
		set_task(0.01, "delay_resethud", 200 + id, args, 1)
	else
		delay_resethud(args)
			
	return PLUGIN_CONTINUE
}

public delay_resethud(args[])
{
	new id = args[0]
	new Float:fGameTime

	// Show user and score round stats after HUD-reset
#if defined STATSX_DEBUG
	log_amx("Reset HUD for #%d", id)
#endif
	fGameTime = get_gametime()
	show_user_hudstats(id, fGameTime)
	show_roundend_hudstats(id, fGameTime)

	// Reset round stats
	g_izKilled[id][KILLED_KILLER_ID] = 0
	g_izKilled[id][KILLED_KILLER_STATSFIX] = 0
	g_izShowStatsFlags[id] = -1		// Initialize flags
	g_fzShowUserStatsTime[id] = 0.0
	g_izUserAttackerDistance[id] = 0
	
	for (new i = 0; i < MAX_PLAYERS; i++)
		g_izUserVictimDistance[id][i] = 0
	
	return PLUGIN_CONTINUE
}

// Save killer info on death.
public client_death(killer, victim, wpnindex, hitplace, TK)
{
	// Bail out if no killer.
	if (!killer)
		return PLUGIN_CONTINUE

	if (killer != victim)
	{
		new iaVOrigin[3], iaKOrigin[3]
		new iDistance
		
		get_user_origin(victim, iaVOrigin)
		get_user_origin(killer, iaKOrigin)
		
		g_izKilled[victim][KILLED_KILLER_ID] = killer
		g_izKilled[victim][KILLED_KILLER_HEALTH] = get_user_health(killer)
		g_izKilled[victim][KILLED_KILLER_ARMOUR] = get_user_armor(killer)
		g_izKilled[victim][KILLED_KILLER_STATSFIX] = 0

		iDistance = get_distance(iaVOrigin, iaKOrigin)
		g_izUserAttackerDistance[victim] = iDistance
		g_izUserVictimDistance[killer][victim] = iDistance
	}
	
	g_izKilled[victim][KILLED_TEAM] = get_user_team(victim)
	g_izKilled[victim][KILLED_KILLER_STATSFIX] = 1

	// Display kill stats for the player if round
	// end stats was not processed.
	if (!g_iRoundEndProcessed)
		kill_stats(victim)

	return PLUGIN_CONTINUE
}

// Display hudmessage stats on death.
// This will also update all round and game stats.
// Must be called at least once per round.
kill_stats(id)
{
	// Bail out if user stats timer is non-zero, 
	// ie function already called.
	if (g_fzShowUserStatsTime[id] > 0.0)
	{
		return
	}
		
	new team = get_user_team(id)
	if (team < 1 || team > 2)
	{
		return
	}

	// Flag kill stats displayed for this player.
	g_fzShowUserStatsTime[id] = get_gametime()

	// Add user death stats to user round stats
	new izStats[8], izBody[8]
	new iTeam, i
	new iKiller

	iKiller = g_izKilled[id][KILLED_KILLER_ID]

	// Get user's team (if dead use the saved team)
	if (iKiller)
		iTeam = g_izKilled[id][KILLED_TEAM] - 1
	else
		iTeam = get_user_team(id) - 1

	get_user_name(id, g_izUserRndName[id], MAX_NAME_LENGTH)

	if (get_user_rstats(id, izStats, izBody))
	{
		// Update user's team round stats
		if (iTeam >= 0 && iTeam < MAX_TEAMS)
		{
			for (i = 0; i < 8; i++)
			{
				g_izTeamRndStats[iTeam][i] += izStats[i]
				g_izTeamGameStats[iTeam][i] += izStats[i]
				g_izUserRndStats[0][i] += izStats[i]
				g_izUserGameStats[0][i] += izStats[i]
			}
		}

		// Update user's round stats
		if (g_izUserUserID[id] == get_user_userid(id))
		{
			for (i = 0; i < 8; i++)
			{
				g_izUserRndStats[id][i] += izStats[i]
				g_izUserGameStats[id][i] += izStats[i]
			}
		} else {
			g_izUserUserID[id] = get_user_userid(id)
			
			for (i = 0; i < 8; i++)
			{
				g_izUserRndStats[id][i] = izStats[i]
				g_izUserGameStats[id][i] = izStats[i]
			}
		}

	}	// endif (get_user_rstats())

	// Report stats in the chat section, if player is killed.
	if (KillerChat && iKiller && iKiller != id)
	{
		if (format_kill_ainfo(id, iKiller, g_sBuffer))
		{
			colorChat(id, CHATCOLOR_GREEN, "* %s", g_sBuffer)
			format_kill_vinfo(id, iKiller, g_sBuffer)
		}
		
		colorChat(id, CHATCOLOR_GREEN, "* %s", g_sBuffer)
	}

	// Display player stats info.
#if defined STATSX_DEBUG
	log_amx("Kill stats for #%d", id)
#endif
	show_user_hudstats(id, 0.0)
}

public award_cash()
{
	if(!get_pcvar_num(pcvar_award) || !get_pcvar_num(pcvar_award_cash))
	{
		return PLUGIN_HANDLED
	}
	
	new izStats[8], izBody[8]
	new szPlayers[32], szName[MAX_NAME_LENGTH], iNumPlayers
	new iAwardCash_Bonus, iAwardCash,  iPlace, iAwardChance
			
	get_players(szPlayers, iNumPlayers) 
	
	for(new i = 0; i < 30; i++)
	{
		iAwardChance = random_num(0, floatround(get_pcvar_float(pcvar_award_chance) * 10.0))
		
		get_stats(i, izStats, izBody, t_sName, MAX_NAME_LENGTH)
		
		for(new k = 0; k < iNumPlayers; k++) 
		{ 
			get_user_name(szPlayers[k], szName, MAX_NAME_LENGTH - 1)
			
			if(equal(szName, t_sName))
			{
				if(get_pcvar_float(pcvar_award_chance))
				{
					if(!iAwardChance)
					{
						continue
					}
				}
				
				if (0 < (i + 1) <= 10) iPlace = 1
				if (10 < (i + 1) <= 20) iPlace = 2
				if (20 < (i + 1) <= 30) iPlace = 3
								
				iAwardCash = get_pcvar_num(pcvar_award_cash) / iPlace
				iAwardCash_Bonus = floatround(get_pcvar_num(pcvar_award_cash) * (((effec(izStats) + accuracy(izStats)) / 2) / 100))
				
				if((iAwardCash + iAwardCash_Bonus + cs_get_user_money(szPlayers[k])) >= 16000)
				{
					cs_set_user_money(szPlayers[k], 16000)
				}
				else
				{
					cs_set_user_money(szPlayers[k], (iAwardCash + iAwardCash_Bonus + cs_get_user_money(szPlayers[k])))
				}
				
				if(get_pcvar_num(pcvar_award_anonce_chat))
				{
					if(cs_get_user_team(szPlayers[k]) != CS_TEAM_SPECTATOR && get_pcvar_num(pcvar_pt_bonus_anonce))
					{
						colorChat(szPlayers[k], CHATCOLOR_GREEN, "%L", LANG_SERVER, "MM_AWARD", iAwardCash, iAwardCash_Bonus, i + 1)
					}
				}
			}
		} 
	}
	
	return PLUGIN_CONTINUE
}

public time_play_bonus()
{
	if(!get_pcvar_num(pcvar_pt_bonus) || !get_pcvar_num(pcvar_pt))
	{
		return PLUGIN_HANDLED
	}
		
	new iCash, iTmpCash, iDay, szDay[5]
	new szPlayers[32], iNum, szName[32]
	new szKey[50], szData[128]
	
	new iCash_1h = get_pcvar_num(pcvar_pt_bonus_1h)
	new iCash_2h = get_pcvar_num(pcvar_pt_bonus_2h)
	new iCash_3h = get_pcvar_num(pcvar_pt_bonus_3h)
	new iCash_4h = get_pcvar_num(pcvar_pt_bonus_4h)
	new iCash_5h = get_pcvar_num(pcvar_pt_bonus_5h)
		
	format_time(szDay, sizeof(szDay) - 1, "%d")
	iDay = str_to_num(szDay)
		
	get_players(szPlayers, iNum)
	for(new i = 0; i < iNum; i++)
	{
		if(cs_get_user_team(szPlayers[i]) == CS_TEAM_SPECTATOR)
		{
			continue
		}
		
		get_user_name(szPlayers[i], szName, sizeof(szName) - 1)
		formatex(szKey, sizeof(szKey) - 1, "TODAY_PLAY#%s", szName)
		nvault_get(g_Vault2, szKey, szData, sizeof(szData) - 1)
		
		new szToday[5], szTodayPlay[256]
		parse(szData, szToday, sizeof(szToday), szTodayPlay, sizeof(szTodayPlay))
				
		if(iDay != str_to_num(szToday))
		{
			formatex(szData, sizeof(szData) - 1, "%d 0", iDay)
			nvault_set(g_Vault2, szKey, szData)
						
			continue
		}
		
		new iTime = (get_user_time(szPlayers[i]) + str_to_num(szTodayPlay)) / MM_HOUR
		
		iCash = cs_get_user_money(szPlayers[i])

		if(!iTime)
		{
			continue
		}
		
		if(iTime == 1 && iCash_1h != 0)
		{		
			if((iCash + iCash_1h) > 16000)
			{
				cs_set_user_money(szPlayers[i], 16000)
			}
			else
			{
				cs_set_user_money(szPlayers[i], iCash + iCash_1h)
			}
			iTmpCash = iCash_1h
		}
		
		if(iTime == 2 && iCash_2h != 0)
		{		
			if((iCash + iCash_2h) > 16000)
			{
				cs_set_user_money(szPlayers[i], 16000)
			}
			else
			{
				cs_set_user_money(szPlayers[i], iCash + iCash_2h)
			}
			iTmpCash = iCash_2h
		}
		
		if(iTime == 3 && iCash_3h != 0)
		{		
			if((iCash + iCash_3h) > 16000)
			{
				cs_set_user_money(szPlayers[i], 16000)
			}
			else
			{
				cs_set_user_money(szPlayers[i], iCash + iCash_3h)
			}
			iTmpCash = iCash_3h
		}
		
		if(iTime == 4 && iCash_4h != 0)
		{		
			if((iCash + iCash_4h) > 16000)
			{
				cs_set_user_money(szPlayers[i], 16000)
			}
			else
			{
				cs_set_user_money(szPlayers[i], iCash + iCash_4h)
			}
			iTmpCash = iCash_4h
		}
		
		if(iTime > 5 && iCash_5h != 0)
		{		
			if((iCash + iCash_5h) > 16000)
			{
				cs_set_user_money(szPlayers[i], 16000)
			}
			else
			{
				cs_set_user_money(szPlayers[i], iCash + iCash_5h)
			}
			iTmpCash = iCash_5h
		}
		
		colorChat(szPlayers[i], CHATCOLOR_GREEN, "%L", LANG_SERVER, "MM_TIME_PLAY_BONUS", iTime, iTmpCash)
		
	}
	
	return PLUGIN_HANDLED
}

public eventEndRound()
{
	award_cash()
	
	day_stat()
	
	time_play_bonus()

	// Update local configuration vars with value in cvars.
	get_config_cvars()

	// If first end round event in the round, calculate team score.
	if (!g_iRoundEndTriggered)
	{
		read_data(2, t_sText, MAX_TEXT_LENGTH)
		
		if (t_sText[7] == 't')			// Terrorist wins
			g_izTeamScore[0]++
		else if (t_sText[7] == 'c')		// CT wins
			g_izTeamScore[1]++
	}

	set_task(0.3, "ERTask", 997)
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	if(get_pcvar_num(pcvar_pt))
	{
		played_time(id)
	}
}

public played_time(id)
{
	new szPlayers[32], iNum, szKey[32], szData[128], szName[32]
	
	new szMinute[5], szHour[5], szDay[5], szMonth[5], szYear[5]
	new iMinute, iHour, iDay, iMonth, iYear
		
	format_time(szMinute, sizeof(szMinute) - 1, "%M")
	format_time(szHour, sizeof(szHour) - 1, "%H")
	format_time(szDay, sizeof(szDay) - 1, "%d")
	format_time(szMonth, sizeof(szMonth) - 1, "%m")
	format_time(szYear, sizeof(szYear) - 1, "%Y")
	
	iMinute = str_to_num(szMinute)
	iHour = str_to_num(szHour)
	iDay = str_to_num(szDay)
	iMonth = str_to_num(szMonth)
	iYear = str_to_num(szYear)
	
	get_players(szPlayers, iNum)
	
	get_user_name(id, szName, sizeof(szName) - 1)
	formatex(szKey, sizeof(szKey) - 1, "PLAYED_TIME#%s", szName)
	
	nvault_get(g_Vault2, szKey, szData, sizeof(szData) - 1)
	
	new iTime = str_to_num(szData)
	
	formatex(szData, sizeof(szData) - 1, "%d", iTime + (get_user_time(id)))
	
	nvault_set(g_Vault2 , szKey, szData) 
	
	formatex(szKey, sizeof(szKey) - 1, "LAST_VISIT#%s", szName)
	formatex(szData, sizeof(szData) - 1, "%d %d %d %d %d", iDay, iMonth, iYear,iHour, iMinute)
	nvault_set(g_Vault2 , szKey, szData)
	
	formatex(szKey, sizeof(szKey) - 1, "TODAY_PLAY#%s", szName)
	nvault_get(g_Vault2, szKey, szData, sizeof(szData) - 1)
	
	new szToday[5], szTodayPlay[256]
	parse(szData, szToday, sizeof(szToday), szTodayPlay, sizeof(szTodayPlay))
	
	if(str_to_num(szToday) != iDay)
	{
		formatex(szData, sizeof(szData) - 1, "%d 0", iDay)
		nvault_set(g_Vault2 , szKey, szData)
	}
	else
	{
		formatex(szData, sizeof(szData) - 1, "%d %d", iDay, (get_user_time(id) + str_to_num(szTodayPlay)))
		nvault_set(g_Vault2 , szKey, szData)
	}
}

public day_stat()
{
	if(!get_pcvar_num(pcvar_day))
	{
		return PLUGIN_HANDLED
	}
	
	new g_szData[12], Players[32], iNum, i
	new szDate[5], szTime[5], szKey[6]
	
	format_time(szDate, sizeof(szDate) - 1, "%d")
	format_time(szTime, sizeof(szTime) - 1, "%H")
		
	i = str_to_num(szTime)
	
	nvault_get(g_Vault , "DAY" , g_szData , 11)
		
	if(str_to_num(g_szData) != str_to_num(szDate))
	{
		day_stat_clear()
	}
	
	formatex(szKey, 5, "%d-h", i)
	nvault_get(g_Vault , szKey , g_szData , 11 )
	
	get_players(Players, iNum)
			
	if(str_to_num(g_szData) < iNum)
	{
		new szStr[5]
		
		formatex(szStr, 4, "%d", iNum)
		formatex(szKey, 5, "%d-h", i)
		
		nvault_set(g_Vault , szKey , szStr)
	}
		
	return PLUGIN_CONTINUE
}

public day_stat_clear()
{
	new szDate[5], szKey[6]
	format_time(szDate, sizeof(szDate) - 1, "%d")
	
	for(new i = 0; i < 24; i++)
	{
		formatex(szKey, 5, "%d-h", i)
		nvault_set(g_Vault , szKey , "0")
	}
		
	nvault_set(g_Vault , "DAY" , szDate)
	
	return PLUGIN_CONTINUE
}

public ERTask()
{
	// Flag round end triggered.
	g_iRoundEndTriggered = 1

	// Display round end stats to all players.
	endround_stats()
}

endround_stats()
{
	// Bail out if end round stats has already been processed
	// or round end not triggered.
	if (g_iRoundEndProcessed || !g_iRoundEndTriggered)
		return

	new iaPlayers[32], iPlayer, iPlayers, id

	get_players(iaPlayers, iPlayers)

	// Display attacker & victim list for all living players.
	// This will also update all round and game stats for all players
	// not killed.
#if defined STATSX_DEBUG
	log_amx("End round stats")
#endif
	
	for (iPlayer = 0; iPlayer < iPlayers; iPlayer++)
	{
		id = iaPlayers[iPlayer]
		
		if (g_fzShowUserStatsTime[id] == 0.0)
		{
			kill_stats(id)
		}
	}

	g_sAwardAndScore[0] = 0

	// Create round awards.
	if (ShowMostDisruptive)
		add_most_disruptive(g_sAwardAndScore)
	if (ShowBestScore)
		add_best_score(g_sAwardAndScore)

	// Create round score. 
	// Compensate HUD message if awards are disabled.
	if (ShowTeamScore || ShowTotalStats)
	{
		if (ShowMostDisruptive && ShowBestScore)
			add(g_sAwardAndScore, MAX_BUFFER_LENGTH, "^n^n")
		else if (ShowMostDisruptive || ShowBestScore)
			add(g_sAwardAndScore, MAX_BUFFER_LENGTH, "^n^n^n^n")
		else
			add(g_sAwardAndScore, MAX_BUFFER_LENGTH, "^n^n^n^n^n^n")

		if (ShowTeamScore)
			add_team_score(g_sAwardAndScore)
		
		if (ShowTotalStats)
			add_total_stats(g_sAwardAndScore)
	}

	save_team_chatscore()

	// Get and save round end stats time.
	g_fShowStatsTime = get_gametime()

	// Display round end stats to all players.
	for (iPlayer = 0; iPlayer < iPlayers; iPlayer++)
	{
		id = iaPlayers[iPlayer]
		show_roundend_hudstats(id, 0.0)
	}

	// Flag round end processed.
	g_iRoundEndProcessed = 1
}

public eventTeamScore()
{
	new sTeamID[1 + 1], iTeamScore
	read_data(1, sTeamID, 1)
	iTeamScore = read_data(2)
	g_izTeamEventScore[(sTeamID[0] == 'C') ? 1 : 0] = iTeamScore
	
	return PLUGIN_CONTINUE
}

public eventIntermission()
{
	if (EndPlayer || EndTop15)
		set_task(1.0, "end_game_stats", 900)
}

public end_game_stats()
{
	new iaPlayers[32], iPlayer, iPlayers, id

	if (EndPlayer)
	{
		get_players(iaPlayers, iPlayers)
		
		for (iPlayer = 0; iPlayer < iPlayers; iPlayer++)
		{
			id = iaPlayers[iPlayer]
			
			if (!g_izStatsSwitch[id])
				continue	// Do not show any stats
			
			cmdStatsMe(iaPlayers[iPlayer])
		}
	}
	else if (EndTop15)
	{
		get_players(iaPlayers, iPlayers)
		format_place1(g_sBuffer)
		
		for (iPlayer = 0; iPlayer < iPlayers; iPlayer++)
		{
			id = iaPlayers[iPlayer]
			
			if (!g_izStatsSwitch[id])
				continue	// Do not show any stats
			
			new szMotdTitle[30]
			formatex(szMotdTitle, charsmax(szMotdTitle), "1 - %L",id, "MM_PLACE")
			show_motd(iaPlayers[iPlayer], g_sBuffer, szMotdTitle)
		}
	}
	
	return PLUGIN_CONTINUE
}

public eventSpecMode(id)
{
	new sData[12]
	read_data(2, sData, 11)
	g_izSpecMode[id] = (sData[10] == '2')
	
	return PLUGIN_CONTINUE
} 

public eventShowRank(id)
{
	if (SpecRankInfo && g_izSpecMode[id])
	{
		new iPlayer = read_data(2)
		
		if (is_user_connected(iPlayer))
		{
			new izStats[8], izBody[8]
			new iRankPos, iRankMax
			
			get_user_name(iPlayer, t_sName, MAX_NAME_LENGTH)
			
			iRankPos = get_user_stats(iPlayer, izStats, izBody)
			iRankMax = get_statsnum()
			
			set_hudtype_specmode()
			ShowSyncHudMsg(id, g_HudSync_SpecInfo, "%L", id, "X_RANK_IS", t_sName, iRankPos, iRankMax)
		}
	}
	
	return PLUGIN_CONTINUE
}

public client_connect(id)
{
	if (ShowStats)
	{
		get_user_info(id, "_amxstatsx", t_sText, MAX_TEXT_LENGTH)
		g_izStatsSwitch[id] = (t_sText[0]) ? str_to_num(t_sText) : -1
	}
	else
		g_izStatsSwitch[id] = 0

	g_izKilled[id][KILLED_KILLER_ID] = 0
	g_izKilled[id][KILLED_KILLER_STATSFIX] = 0
	g_izShowStatsFlags[id] = 0		// Clear all flags
	g_fzShowUserStatsTime[id] = 0.0

	return PLUGIN_CONTINUE
}

new iEffect, iColor_R, iColor_G, iColor_B, g_pcvarColor
new Float:iFadeIn, Float:iFadeOut, Float:iHoldTime, Float:iPos_X, Float:iPos_Y

public StatsMarquee(id)
{
	if(!get_pcvar_num(pcvar_statsmarquee))
	{
		return PLUGIN_HANDLED
	}
	
	new izStats[8], izBody[8]
	
	get_stats(marquee_iID, izStats, izBody, m_sName, MAX_NAME_LENGTH)
	
	switch(get_pcvar_num(pcvar_statsmarquee_position))
	{
		case 1:
		{
			iPos_X = 0.7
			iPos_Y = 0.05	
		}
		case 2:
		{
			iPos_X = 0.02
			iPos_Y = 0.7	
		}
		case 3:
		{
			iPos_X = 0.02
			iPos_Y = 0.2	
		}
		default:
		{
			iPos_X = 0.7
			iPos_Y = 0.78
		}
	}
	
	g_pcvarColor = get_pcvar_num(pcvar_statsmarquee_color)
	
	if(g_pcvarColor == 11)
	{
		g_pcvarColor = random_num(1, 9)
	}
	
	switch(g_pcvarColor)
	{
		case 1:
		{
			// RED
			iColor_R = 255
			iColor_G = 0
			iColor_B = 0
		}
		case 2:
		{
			// GREEN
			iColor_R = 0
			iColor_G = 255
			iColor_B = 0
		}
		case 3:
		{
			// BLUE
			iColor_R = 0
			iColor_G = 0
			iColor_B = 255
		}
		case 4:
		{
			// YELLOW
			iColor_R = 255
			iColor_G = 255
			iColor_B = 0
		}
		case 5:
		{
			// CYAN
			iColor_R = 0
			iColor_G = 255
			iColor_B = 255
		}
		case 6:
		{
			// MAGENTA
			iColor_R = 255
			iColor_G = 0
			iColor_B = 255
		}
		case 7:
		{
			// ORANGE
			iColor_R = 255
			iColor_G = 128
			iColor_B = 0
		}
		case 8:
		{
			// VIOLET
			iColor_R = 0
			iColor_G = 128
			iColor_B = 255
		}
		case 9:
		{
			// GRAY
			iColor_R = 100
			iColor_G = 100
			iColor_B = 100
		}
		case 10:
		{
			// RANDOM
			iColor_R = random_num(0, 255)
			iColor_G = random_num(0, 255)
			iColor_B = random_num(0, 255)
		}
		default:
		{
			
		}
	}
	
	if(get_pcvar_num(pcvar_style))
	{
		switch(marquee_iID)
		{
			case 0:
			{
				formatex(marquee_place, charsmax(marquee_place), "%L", id, "MM_FIRSTPLACE")
				
				if(!g_pcvarColor)
				{
					iColor_R = 0
					iColor_G = 255
					iColor_B = 0
				}
			}
			case 10:
			{
				formatex(marquee_place, charsmax(marquee_place), "%L", id, "MM_SECONDPLACE")
				
				if(!g_pcvarColor)
				{
					iColor_R = 255
					iColor_G = 255
					iColor_B = 0
				}
			}
			case 20:
			{
				formatex(marquee_place, charsmax(marquee_place), "%L", id, "MM_THIRDPLACE")
				
				if(!g_pcvarColor)
				{
					iColor_R = 255
					iColor_G = 0
					iColor_B = 0
				}
			}
		}
	}
	else
	{
		formatex(marquee_place, charsmax(marquee_place), "%L", id, "SERVER_STATS")
	}
	
	
	switch(get_pcvar_num(pcvar_statsmarquee_effect))
	{
		case 1:
		{
			iEffect = 1
			iFadeIn = 0.2
			iFadeOut = 0.2
			iHoldTime = 5.8
		}
		case 2:
		{
			iEffect = 2
			iFadeIn = 0.05
			iFadeOut = 0.5
			iHoldTime = 2.0
		}
		default:
		{
			iEffect = 0
			iFadeIn = 0.5
			iFadeOut = 0.5
			iHoldTime = 5.5
		}
	}
	
	
	set_hudmessage(iColor_R, iColor_G, iColor_B, iPos_X, iPos_Y, iEffect, 0.1, iHoldTime, iFadeIn, iFadeOut, -1)
	show_hudmessage(0,"%L", id, "MM_MARQUEE" , marquee_place, m_sName, marquee_iID + 1, izStats[0], izStats[1])
	
	marquee_iID++
		
	if(marquee_iID >= 30)
	{
		marquee_iID = 0
		set_task(300.0, "StatsMarquee", 0, _, 0)
	}
	else
	{
		set_task(6.0, "StatsMarquee", 0, _, 0)
	}
	
	
	
	return PLUGIN_CONTINUE
}

/*	Thanks for Damaged Soul for finding the information on how to do this.
	http://forums.alliedmods.net/showthread.php?p=79604#post79604

	This is code snippets I find useful.

	^x01 is Yellow
	^x03 is Team Color. Ie. Red (Terrorist) or blue (Counter-Terrorist) or grey (SPECTATOR or UNASSIGNED).
	^x04 is Green

	The colors red, grey, and blue can't be used on the same line. This is not possible at all to do.

	Also there are limitation to using Red or Grey while on the TEAM CT.
	You would have to do for example if they were on CT.

	ColorChat(0, RED, "%s, ^x01This color is yellow. ^x03This color is red. ^x04This color is green.);

	You have to set the Type to RED because of certain messages that need to be sent out so a person on the
	team CT can be sent red colors.
	
	Some important information. When using MSG_ALL to send color message to all clients and your going to use blue/grey/red
	color sending the TeamInfo Message to tempoary change the player team to achieve this. You must send that message in MSG_ALL
	also. If your going to only send it to one person. You need to MSG_ONE on TeamInfo and SayText. (Thanks to CheapSuit I was able
	to see their was an error and fix it).
	
*/

colorChat(id, ChatColor:color, const msg[], {Float,Sql,Result,_}:...)
{
	new team, index, MSG_Type
	new bool:teamChanged = false
	static message[192]
	
	switch(color)
	{
		case CHATCOLOR_NORMAL: // Normal
		{
			message[0] = 0x01;
		}
		case CHATCOLOR_GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // Grey, Red, Blue
		{
			message[0] = 0x03;
		}
	}
	
	vformat(message[1], 190, msg, 4);
	replace_all(message, 190, "$g", "^x04")
	replace_all(message, 190, "$n", "^x01")
	replace_all(message, 190, "$t", "^x03")
		
	if(id == 0)
	{
		index = findAnyPlayer();
		MSG_Type = MSG_ALL;
	}
	else
	{
		index = id;
		MSG_Type = MSG_ONE;
	}
	if(index != 0)
	{
		team = get_user_team(index);	
		if(color == CHATCOLOR_RED && team != 1)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[1])
			teamChanged = true
		}
		else
		if(color == CHATCOLOR_BLUE && team != 2)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[2])
			teamChanged = true
		}
		else
		if(color == CHATCOLOR_GREY && team != 0)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[0])
			teamChanged = true
		}
		messageSayText(index, MSG_Type, message);
		if(teamChanged)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[team])
		}
	}
}

messageSayText(id, type, message[])
{
	message_begin(type, g_msgSayText, _, id)
	write_byte(id)		
	write_string(message)
	message_end()
}
	
messageTeamInfo(id, type, team[])
{
	message_begin(type, g_msgTeamInfo, _, id)
	write_byte(id)
	write_string(team)
	message_end()
}
	
findAnyPlayer()
{
	static players[32], inum, pid
	
	get_players(players, inum, "ch")
	
	for (new a = 0; a < inum; a++)
	{
		pid = players[a]
		if(is_user_connected(pid))
			return pid
	}
	
	return 0
}

