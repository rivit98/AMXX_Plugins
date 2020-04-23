/* Spectator Banner(PICTURE) Ads 
   Have you ever seen the banner pictuer(left up corner) when watching HLTV?
   We can see it ingame now when you are death or become spectator.
   Should it using by Valve Ads? Who know! Enjoy it!
*/

/* Description::
   Ramdon select one tga file when map was loaded.
   Tested on CS/CZ, may works on other MOD.
*/

/* Install Instructions::
   Put the tga files in (cstrike\gfx) folder
   Put the banner_ads.amxx in (cstrike\addons\amxmodx\plugins) folder
*/

/* Console Commands::
   spec_banner_ads 1/0 // Enable & Disable Function
*/

/* Change Log::
   v0.1 First released
*/

/* Notice::
   The tga file only support 24b color format.
   The zip file contain tga only fit 800*600 display resolution of client.
   Change the size if most client used difference resolution.
*/

/* Screenshots::
*/


#define PLUGIN  "Spectator Banner Ads"
#define VERSION "0.1.16"
#define AUTHOR  "iG_os"

#include <amxmodx>

#define SVC_DIRECTOR 51  // come from util.h
#define DRC_CMD_BANNER 9 // come from hltv.h

// sum of tga files
#define TGASUM 2

// tga of banners
new szTga[TGASUM][] ={
"gfx/friends.tga",
"gfx/amxx.tga"
}

new pCVAR_Tga
new g_SendOnce[33]

public plugin_precache()
{
   register_plugin(PLUGIN, VERSION, AUTHOR)
   register_logevent("joined_team", 3, "1=joined team")

   pCVAR_Tga = register_cvar("spec_banner_ads", "1")

   if (get_pcvar_num(pCVAR_Tga))
   {
      for (new i=0; i<TGASUM; i++)
         precache_generic(szTga[i])
   }
}


public client_putinserver(id)
{
   g_SendOnce[id] = true
}


public joined_team()
{
   new loguser[80], name[32]
   read_logargv(0, loguser, 79)
   parse_loguser(loguser, name, 31)
   new id = get_user_index(name)

   if ( get_pcvar_num(pCVAR_Tga) && g_SendOnce[id] && is_user_connected(id) )
   {
      // random select one tga
      new index = random_num( 0, TGASUM - 1)
      g_SendOnce[id] = false

      // send show tga command to client
      message_begin( MSG_ONE, SVC_DIRECTOR, _, id )
      write_byte( strlen( szTga[index]) + 2 ) // command length in bytes
      write_byte( DRC_CMD_BANNER )
      write_string( szTga[index] ) // banner file
      message_end()
   }
}


