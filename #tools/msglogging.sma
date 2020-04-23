/* Message Logging 1.17 by Damaged Soul

   AMX Mod X Version: 1.75 and above
   Supported Mods: All
   
   This file is provided as is (no warranties).
  
   ***************
   * Description *
   ***************
   This plugin allows for the logging of any or all messages sent by the HL engine or mod (such as 
   DeathMsg, CurWeapon, etc) It also allows these messages to be filtered by entity.
   
   Information that is logged includes:
      - Message name
      - Number of message arguments
      - Message ID
      - Message destination (i.e. Broadcast, One, All, etc)
      - Message origin
      - Entity that received the message
      - Entity classname
      - Entity netname
      - Every argument value and type
   
   ********************
   * Required Modules *
   ********************
   Fakemeta
   
   *********
   * Usage *
   *********
   Console Commands:
      amx_msglog <command> [argument]
         - Displays help for logging engine/mod messages when no command is given
         - Commands:
              start [msg name or id]
                 - Starts logging given message or all if no argument
              stop [msg name or id]
                 - Stops logging given message or all if no argument
              list [page]
                 - Displays list of messages and their logging status
   
   Cvars:
      amx_ml_filter [Default Value: 1]
         - Allows for filtering messages by entity index
         - Set this to the index of the entity for which you want to log messages
         - If this is set to 0, message logging will be done for all entities

      amx_ml_logmode [Default Value: 1]
         - Determines where to log message information
         - Set this to 0 to log information to the standard AMX Mod X log file
         - Set this to 1 to log information to a separate file (messages.log) in the log directory

   Examples:
      To log the DeathMsg message:
         amx_msglog start DeathMsg OR amx_msglog start 83

      To stop logging the DeathMsg message:
         amx_msglog stop DeathMsg OR amx_msglog stop 83
	
      To log all messages except the DeathMsg message:
         amx_msglog start
         amx_msglog stop DeathMsg OR amx_msglog stop 83

      To log messages only sent to third player of the server:
         amx_ml_filter 3

      To log messages sent to all entities:
         amx_ml_filter 0

   *******************
   * Version History *
   *******************
   1.17 [Feb. 11, 2007]
      - Fixed: Long arguments were being reported as bytes (Thanks XxAvalanchexX)
      
   1.16 [Oct. 4, 2006]
      - Fixed: String arguments of messages that contained format paramaters (such as %s) caused
               runtime error 25 (thanks sawce :avast:)
      - Tabs and new-lines in string arguments of messages are now converted to ^t and ^n
 
   1.15 [July 4, 2006]
      - Now uses the Fakemeta module instead of Engine
      - Now uses vformat instead of the deprecated format_args when logging information
      - Very minor optimizations

   1.11 [May 11, 2006]
      - Fixed: String arguments of messages were being logged as numbers

   1.10 [Apr. 23, 2006]
      - Minor optimizations including the use of pcvar natives to improve performance a bit
      - Much of the logged text has been rewritten in an attempt to make it more like the Half-Life
        log standard
      - Now when using the start or stop commands on a specified message, both the message name and
        ID are printed instead of just whatever was given as the argument
      - Added: amx_ml_logmode cvar for controlling where to log message information
      - Fixed: When no arguments were given to amx_msglog, usage information was not printed

   1.03 [Oct. 26, 2004]
      - Public release
      - Fixed: Entity filter wasn't actually checking for valid entities correctly (thanks JGHG)

   1.02 [Oct. 25, 2004]
      - Fixed: If logging had been started for a message, stopped, then started again, same message
               was logged twice.
      - Fixed: If message name or ID was invalid, started/stopped logging all messages instead

   1.01 [Oct. 23, 2004]
      - Fixed: List command was not reporting correct logging status
      - Fixed: Filter was incorrectly filtering messages if amx_ml_filter was 0

   1.00 [Oct. 19, 2004]
      - Initial version
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

// Plugin information constants
new const PLUGIN[] = "Message Logging"
new const AUTHOR[] = "Damaged Soul"
new const VERSION[] = "1.16"

#define MAX_ENGINE_MESSAGES   63  // Max messages reserved by engine (DO NOT MODIFY)
#define MAX_POSSIBLE_MESSAGES 255 // Max possible messages for mod, is 255 really the limit?

#define MSGLOG_STOPPED        0	  // Logging status: Stopped
#define MSGLOG_STARTED        1	  // Logging status: Started

// Cvar pointers
new g_cvarFilter, g_cvarLogMode

// Filename of separate log file for message info
new const LOGFILE_NAME[] = "messages.log"

// Is message currently being hooked for logging?
new bool:g_msgLogging[MAX_POSSIBLE_MESSAGES + 1] = {false}
// Is message registered to message_forward?
new bool:g_msgRegistered[MAX_POSSIBLE_MESSAGES + 1] = {false}
// Stores the names of messages, indexed by message ID
new g_msgCache[MAX_POSSIBLE_MESSAGES + 1][32]

// Max messages allowed by mod
new g_maxMessages = MAX_ENGINE_MESSAGES

new const NULL_STR[] = "<NULL>"

/* Initialize plugin; Register commands and cvars */
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_cvarFilter = register_cvar("amx_ml_filter", "1")
	g_cvarLogMode = register_cvar("amx_ml_logmode", "1")
	
	register_concmd("amx_msglog", "cmd_msglog", ADMIN_ADMIN, 
			"<command> [argument] - displays help for logging engine/mod messages")

	g_maxMessages = generate_msg_table()
}

/* Handles command amx_msglog */
public cmd_msglog(id, level, cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	new argCmd[6]
	read_argv(1, argCmd, 5)
	remove_quotes(argCmd)
	
	if (equali(argCmd, "start") || equali(argCmd, "stop")) // start or stop commands
	{
		new argMsg[32]
		read_argv(2, argMsg, 31)
		remove_quotes(argMsg)
		
		new msgid = str_to_msgid(argMsg)
		
		if (is_msg_valid(msgid))
		{
			new status = get_msglog_status(msgid)
			
			if (argCmd[2] == 'a') // start <message>
			{
				if (status == MSGLOG_STOPPED)
				{
					set_msglog_status(msgid, MSGLOG_STARTED)
					log_msgf("Logging started for message (%s ^"%d^")", g_msgCache[msgid], msgid)
				}
				else
					console_print(id, "Logging has already been started for message (%s ^"%d^")", g_msgCache[msgid], msgid)
			}
			else // stop <message>
			{
				if (status == MSGLOG_STARTED)
				{
					set_msglog_status(msgid, MSGLOG_STOPPED)
					log_msgf("Logging stopped for message (%s ^"%d^")", g_msgCache[msgid], msgid)
				}
				else
					console_print(id, "Logging has already been stopped for message (%s ^"%d^")", g_msgCache[msgid], msgid)
			}
		}
		else
		{
			// If msg name or ID isn't blank, then at this point we have an invalid msg
			if (argMsg[0])
			{
				console_print(id, "%s is not a valid message name or ID", argMsg)
				return PLUGIN_HANDLED
			}
			
			if (argCmd[2] == 'a') // start
			{
				set_msglog_status(0, MSGLOG_STARTED)
				log_msgf("Logging started for all messages")
			}
			else // stop
			{
				set_msglog_status(0, MSGLOG_STOPPED)
				log_msgf("Logging stopped for all messages")
			}
		}
	}
	else if (equali(argCmd, "list")) // list command
	{
		new argStart[4]
		new start = read_argv(2, argStart, 3) ? str_to_num(argStart) : 1
		
		if (start < 1)
			start = 1
		else if (start > g_maxMessages)
			start = g_maxMessages
			
		new end = start + 9
		if (end > g_maxMessages)
			end = g_maxMessages
			
		new logstatus[8], msgname[32]
		
		console_print(id, "^n------------ Message Logging Statuses -------------")
		console_print(id, "     %-31s   %s", "Message Name", "Status")
		
		for (new i = start; i <= end; i++)
		{
			copy(msgname, 31, g_msgCache[i])
			
			if (!msgname[0])
				copy(msgname, 31, "<Unknown>")
			
			copy(logstatus, 7, g_msgLogging[i] ? "LOGGING" : "IDLE")
			
			console_print(id, "%3d: %-31s   %s", i, msgname, logstatus)
		}
		
		console_print(id, "Entries %d - %d of %d", start, end, g_maxMessages)
		
		if (end < g_maxMessages)
			console_print(id, "-------- Use 'amx_msglog list %d' for more --------", end + 1)
		else
			console_print(id,"-------- Use 'amx_msglog list 1' for beginning --------")
		
	}
	else
	{
		// Display usage information
		console_print(id, "Usage:  amx_msglog <command> [argument]")
		console_print(id, "Valid commands are: ")
		
		console_print(id, "   start [msg name or id] - Starts logging given message or all if no argument")
		console_print(id, "   stop [msg name or id]  - Stops logging given message or all if no argument")
		console_print(id, "   list [page]            - Displays list of messages and their logging status")
	}
	
	return PLUGIN_HANDLED
}

/* Forward for hooked messages */ 
public message_forward(msgid, msgDest, msgEnt) {
	if (!g_msgLogging[msgid]) return PLUGIN_CONTINUE
	
	new entFilter = get_pcvar_num(g_cvarFilter)
	
	/* If value of amx_ml_filter isn't a valid entity index (0 is accepted in order to log ALL)
	   Then stop all logging */
	if (entFilter != 0 && !pev_valid(entFilter)) {
		set_msglog_status(0, MSGLOG_STOPPED)
			
		log_msgf("Logging stopped for all messages because entity index ^"%d^" is not valid", entFilter)
		return PLUGIN_CONTINUE
	}
	
	// If not filtering by entity and the receiver entity doesn't match the filter, don't log message
	if (entFilter != 0 && msgEnt != 0 && msgEnt != entFilter)
		return PLUGIN_CONTINUE

	new msgname[32], id[4], argcount, dest[15], Float:msgOrigin[3], entStr[7], entClassname[32], entNetname[32]
	
	// Get message name
	copy(msgname, 31, g_msgCache[msgid])
	
	// If message has no name, then set the name to message ID
	if (!msgname[0])
	{
		num_to_str(msgid, id, 3)
		copy(msgname, 31, id)
	}
	
	// Get number of message arguments
	argcount = get_msg_args()
	
	// Determine the destination of the message
	switch (msgDest) {
		case MSG_BROADCAST:
			copy(dest, 9, "Broadcast")
		case MSG_ONE:
			copy(dest, 3,  "One")
		case MSG_ALL:
			copy(dest, 3,  "All")
		case MSG_INIT:
			copy(dest, 4,  "Init")
		case MSG_PVS:
			copy(dest, 3,  "PVS")
		case MSG_PAS:
			copy(dest, 3,  "PAS")
		case MSG_PVS_R:
			copy(dest, 12, "PVS Reliable")
		case MSG_PAS_R:
			copy(dest, 12, "PAS Reliable")
		case MSG_ONE_UNRELIABLE:
			copy(dest, 14, "One Unreliable")
		case MSG_SPEC:
			copy(dest, 4,  "Spec")
		default:
			copy(dest, 7,  "Unknown")
	}
	
	// Get the origin of the message (only truly valid for PVS through PAS_R)
	get_msg_origin(msgOrigin)
	
	// Get the receiving entity's classname and netname
	if (msgEnt != 0) {
		num_to_str(msgEnt, entStr, 6)
		pev(msgEnt, pev_classname, entClassname, 31)
		pev(msgEnt, pev_netname, entNetname, 31)
		
		if (!entNetname[0])
			copy(entNetname, 31, NULL_STR)
	} else {
		copy(entStr, 6, NULL_STR)
		copy(entClassname, 6, NULL_STR)
		copy(entNetname, 6, NULL_STR)
	}
	
	// Log message information (MessageBegin)
	log_msgf("MessageBegin (%s ^"%d^") (Destination ^"%s<%d>^") (Args ^"%d^") (Entity ^"%s^") (Classname ^"%s^") (Netname ^"%s^") (Origin ^"%f %f %f^")", 
		msgname, msgid, dest, msgDest, argcount, entStr, entClassname, entNetname, msgOrigin[0], msgOrigin[1], msgOrigin[2])
	
	static str[256]
	
	// Log all argument data
	if (argcount > 0)
	{
		for (new i = 1; i <= argcount; i++) {
			switch (get_msg_argtype(i)) {
				case ARG_BYTE:
					log_msgf("Arg %d (Byte ^"%d^")", i, get_msg_arg_int(i))
				case ARG_CHAR:
					log_msgf("Arg %d (Char ^"%d^")", i, get_msg_arg_int(i))
				case ARG_SHORT:
					log_msgf("Arg %d (Short ^"%d^")", i, get_msg_arg_int(i))
				case ARG_LONG:
					log_msgf("Arg %d (Long ^"%d^")", i, get_msg_arg_int(i))
				case ARG_ANGLE:
					log_msgf("Arg %d (Angle ^"%f^")", i, get_msg_arg_float(i))
				case ARG_COORD:
					log_msgf("Arg %d (Coord ^"%f^")", i, get_msg_arg_float(i))
				case ARG_STRING:
				{
					get_msg_arg_string(i, str, 255)
					
					replace_all(str, 254, "^t", "^^t")
					replace_all(str, 254, "^n", "^^n")
					replace_all(str, 254, "%", "%%")
					
					log_msgf("Arg %d (String ^"%s^")", i, str)
				}
				case ARG_ENTITY:
					log_msgf("Arg %d (Entity ^"%d^")", i, get_msg_arg_int(i))
				default:
					log_msgf("Arg %d (Unknown ^"%d^")", i, get_msg_arg_int(i))
			}
		}
	}
	else
	{
		log_msgf("Message contains no arguments")
	}
	
	// Log that the message ended (MessageEnd)
	log_msgf("MessageEnd (%s ^"%d^")", msgname, msgid)
	
	return PLUGIN_CONTINUE
}

/***************** Other Functions *****************/

/* Fills g_msgCache with message names for faster look up
   Return value: Number of messages that are valid */
generate_msg_table() {	
	for (new i = MAX_ENGINE_MESSAGES + 1; i <= MAX_POSSIBLE_MESSAGES; i++)
	{
		// Store the message name in the cache for faster lookup
		if (!get_user_msgname(i, g_msgCache[i], 31))
			return i - 1
	}
	
	return MAX_POSSIBLE_MESSAGES
}

/* Returns true if msgid is a valid message */
bool:is_msg_valid(msgid)
{
	return (msgid > 0 && msgid <= g_maxMessages)
}

/* Returns message ID from string */
str_to_msgid(const str[]) {
	new n = str_to_num(str)
	
	if (n <= 0 )
		return get_user_msgid(str)
		
	return n
}

/* Gets logging status of message */
get_msglog_status(msgid)
{
	return g_msgLogging[msgid] ? MSGLOG_STARTED : MSGLOG_STOPPED
}

/* Sets logging status of message
   If msgid = 0, status will be applied to all messages */
set_msglog_status(msgid, status)
{	
	if (msgid > 0) // Individual message
	{
		g_msgLogging[msgid] = (status == MSGLOG_STARTED)
		if (!g_msgRegistered[msgid]) 
		{
			register_message(msgid, "message_forward")
			g_msgRegistered[msgid] = true
		}

	}
	else // ALL messages
	{
		for (new i = 1; i <= g_maxMessages; i++) 
		{
			g_msgLogging[i] = (status == MSGLOG_STARTED)
			if (status == MSGLOG_STARTED) 
			{
				if (!g_msgRegistered[i]) 
				{
					register_message(i, "message_forward")
					g_msgRegistered[i] = true
				}
			}
		}
	}	
}

/* Writes messages to log file depending on value of amx_ml_logmode */ 
log_msgf(const fmt[], {Float,Sql,Result,_}:...)
{		
	static buffer[512]
	vformat(buffer, 511, fmt, 2)
	
	if (get_pcvar_num(g_cvarLogMode))
		log_to_file(LOGFILE_NAME, buffer)
	else
		log_amx(buffer)
}
