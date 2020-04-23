#include <amxmodx>
#include <fakemeta>
#include <csx>

#define AUTHOR "aSior - amxx.pl/user/60210-asior/"

#define MAX_PLAYERS 32
#define MAX_CHARS 33

#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)
#define ForArray(%1,%2) for(new %1 = 0; %1 < sizeof %2; %1++)
#define ForDynamicArray(%1,%2) for(new %1 = 0; %1 < ArraySize(%2); %1++)
#define ForFile(%1,%2,%3,%4,%5) for(new %1 = 0; read_file(%2, %1, %3, %4, %5); %1++)

new const configFilePath[] = "addons/amxmodx/configs/RanksConfig.ini";

new const configFileDataSeparator = '=';

new const configFileKillsSeparator = '-';

new const configFileForbiddenChars[] =
{
	'/',
	';',
	'\'
};


new const ranksListMenuCommands[][] =
{
	"say /rangi",
	"say_team /rangi",

	"say /ranga",
	"say_team /ranga",

	"say /listarang",
	"say_team /listarang"
};


new const nativeData[][] =
{
	{ "GetUserRankName", "native_GetUserRankName" },
	{ "GetUserRank", "native_GetUserRank" }
};


new Array:rankName,
	Array:rankFrags[2],
	userRank[MAX_PLAYERS + 1],
	clientName[MAX_PLAYERS + 1][MAX_CHARS];

public plugin_init()
{
	register_plugin("x", "v0.1", AUTHOR);

	register_message(get_user_msgid("SayText"), "handleSayText");

	register_event("DeathMsg", "DeathMsg", "a");

	register_forward(FM_ClientUserInfoChanged, "clientInfoChanged");
}

public clientInfoChanged(index)
	get_user_name(index, clientName[index], charsmax(clientName[]));

public plugin_natives()
	ForArray(i, nativeData)
		register_native(nativeData[0], nativeData[1], true);

public plugin_precache()
	LoadConfigFile();

public LoadConfigFile()
{
	rankName = ArrayCreate(MAX_CHARS, 1);

	ForRange(i, 0, 1)
		rankFrags[i] = ArrayCreate(1, 1);

	new currentLine[MAX_CHARS * 2], lineLength, readRankName[MAX_CHARS * 2], readRankKills[2][15], key[MAX_CHARS], value[MAX_CHARS * 2], bool:continueLine;

	ForFile(i, configFilePath, currentLine, charsmax(currentLine), lineLength)
	{
		if(!currentLine[0])
			continue;

		continueLine = false;

		ForArray(j, configFileForbiddenChars)
			if(currentLine[0] == configFileForbiddenChars[j])
			{
				continueLine = true;
				
				break;
			}

		if(continueLine)
			continue;

		parse(currentLine, readRankName, charsmax(readRankName));

		strtok(currentLine, key, charsmax(key), value, charsmax(value), configFileDataSeparator);
		
		trim(value);
		
		strtok(value, readRankKills[0], charsmax(readRankKills[]), readRankKills[1], charsmax(readRankKills[]), configFileKillsSeparator);
	
		ArrayPushString(rankName, readRankName);

		ForRange(i, 0, 1)
			ArrayPushCell(rankFrags[i], str_to_num(readRankKills[!i ? 1 : 0]));
	}

	if(!ArraySize(rankName))
		return;

	log_amx("Zaladowano: %i rang(i) w zakresie (%i - %i).", ArraySize(rankName), ArrayGetCell(rankFrags[1], 0), ArrayGetCell(rankFrags[0], ArraySize(rankName) - 1));

	ForArray(i, ranksListMenuCommands)
		register_clcmd(ranksListMenuCommands[i], "mainMenu");
}

public handleSayText(msgId, msgDest, msgEnt)
{
	new index = get_msg_arg_int(1);

	if(!is_user_connected(index))
		return PLUGIN_CONTINUE;

	new chatString[2][192], clientRank[MAX_CHARS];

	get_msg_arg_string(2, chatString[0], charsmax(chatString[]));

	ArrayGetString(rankName, userRank[index], clientRank, charsmax(clientRank));

	if(!equal(chatString[0], "#Cstrike_Chat_All"))
		formatex(chatString[1], charsmax(chatString[]), "^x03[^x04%s^x03] %s", clientRank, chatString[0]);
	else
	{
		get_msg_arg_string(4, chatString[0], charsmax(chatString[]));
		set_msg_arg_string(4, "");

		formatex(chatString[1], charsmax(chatString[]), "^x03[^x04%s^x03] %s^x01 : %s", clientRank, clientName[index], chatString[0]);
	}

	set_msg_arg_string(2, chatString[1]);

	return PLUGIN_CONTINUE;
}

public DeathMsg()
{
	new killer = read_data(1), victim = read_data(2);

	if(killer == victim || !is_user_connected(victim) || !is_user_connected(killer))
		return;

	GetUserRank(killer);
}

public client_authorized(index)
{
	get_user_name(index, clientName[index], charsmax(clientName[]));

	GetUserRank(index);
}

public GetUserRank(index)
{
	if(!ArraySize(rankName))
		return;

	new userStats[8], blank[8];

	get_user_stats(index, userStats, blank);

	if(userRank[index] == ArraySize(rankName))
		return;

	ForDynamicArray(i, rankName)
	{
		if(userStats[0] >= ArrayGetCell(rankFrags[1], i) && userStats[0] <= ArrayGetCell(rankFrags[0], i))
		{
			userRank[index] = userRank[index] + 1 > ArraySize(rankName) ? ArraySize(rankName) : i;

			break;
		}
	}
}

public mainMenu(index)
{	
	new menuTitle[MAX_CHARS * 2], item[MAX_CHARS * 2], menuIndex

	ArrayGetString(rankName, userRank[index], menuTitle, charsmax(menuTitle));

	format(menuTitle, charsmax(menuTitle), "Twoja ranga: %s (%i / %i)^nLista rang:", menuTitle, userRank[index] + 1, ArraySize(rankName));
	
	menuIndex = menu_create(menuTitle, "mainMenu_handler");

	ForDynamicArray(i, rankName)
	{
		ArrayGetString(rankName, i, item, charsmax(item));

		formatex(item, charsmax(item), "%s (Od: %i || Do: %i)", item, ArrayGetCell(rankFrags[1], i), ArrayGetCell(rankFrags[0], i));

		menu_additem(menuIndex, item);
	}

	menu_display(index, menuIndex);

	return PLUGIN_HANDLED;
}

public mainMenu_handler(index, menu, item)
{
	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}

public native_GetUserRank(index)
	return userRank[index];

public native_GetUserRankName(index, string[], length)
{
	param_convert(2);

	ArrayGetString(rankName, userRank[index], string, length);
}