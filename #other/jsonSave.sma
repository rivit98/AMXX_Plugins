#include <amxmodx>
#include <json>

#pragma compress 1
#pragma semicolon 1

#define AUTHOR "aSior - amxx.pl/user/60210-asiorr/"


new const jsonFilePath[] = "addons/amxmodx/data/playerPoints.json";


enum (+= 1)
{
	labelPoints
};

new const dataLabels[][] =
{
	"points"
};


// Reward points.
new const rewardKill = 1;
new const rewardHeadshot = 2;
new const rewardKillStreak = 3;

// Minimum amount of kills to activate killstreak rewards.
new const killStreakRequirements = 5;


new userPoints[MAX_PLAYERS + 1],
	bool:userDataLoaded[MAX_PLAYERS + 1],
	userKillStreak[MAX_PLAYERS + 1],

	JSON:jsonHandle;


public plugin_init()
{
	register_plugin("x", "v0.1", AUTHOR);

	// Register post player-killed ham event.
	register_event("DeathMsg", "playerDeathEvent", "a");

	// Create .json handle.
	jsonHandle = json_parse(jsonFilePath, true, false);

	// Handle json object if invalid.
	if(jsonHandle == Invalid_JSON)
	{
		jsonHandle = json_init_object();
	}
}

public playerDeathEvent()
{
	new killer = read_data(1),
		victim = read_data(2);

	// Reset player's killstreak.
	userKillStreak[victim] = 0;

	// Return if victim or killer is not connected.
	if(!is_user_connected(victim) || !is_user_connected(killer))
	{
		return;
	}

	// Add points reward.
	userPoints[killer] += read_data(3) ? rewardHeadshot : rewardKill;

	// Increment and check if player's killstreak passes statement.
	if(++userKillStreak[killer] < killStreakRequirements)
	{
		return;
	}

	// Reward for killstreak.
	userPoints[killer] += rewardKillStreak;
}

public client_putinserver(index)
{
	// Return if player is a bot or HTLV.
	if(is_user_hltv(index) || is_user_bot(index))
	{
		return;
	}

	userDataLoaded[index] = false;
	userPoints[index] = 0;
	userKillStreak[index] = 0;

	// Get user points.
	getPointsData(index);
}

public client_disconnect(index)
{
	// Save user points.
	savePointsData(index);
}

public plugin_end()
{
	// Save .json object to file.
	json_serial_to_file(jsonHandle, jsonFilePath, true);

	// Free .json handle.
	json_free(jsonHandle);
}

getPointsData(index)
{
	userPoints[index] = getUserDataInt(index, dataLabels[labelPoints]);
}

savePointsData(index)
{
	saveUserDataInt(index, dataLabels[labelPoints], userPoints[index]);
}


saveUserDataInt(index, label[], data, bool:dotNotation = true)
{
	// Return if player is not connected or his data was not loaded yet.
	if(!is_user_connected(index) || !userDataLoaded[index])
	{
		return -1;
	}

	// Return data from .json.
	return json_object_set_number(jsonHandle, fmt("%n.%s", index, label), data, dotNotation);
}

getUserDataInt(index, label[], bool:dotNotation = true)
{
	// Return if player is not connected or is not connecting.
	if(!is_user_connected(index) && !is_user_connecting(index))
	{
		return -1;
	}

	// Set user data to loaded.
	userDataLoaded[index] = true;

	// Return data from .json.
	return json_object_get_number(jsonHandle, fmt("%n.%s", index, label), dotNotation);
}