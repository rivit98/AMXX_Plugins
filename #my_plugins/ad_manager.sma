#include <amxmodx>
#include amxmisc

#define CZAS_TASK 25

new Array:reklamy;

new gmsgSayText;
new currAd = -1

public plugin_init()
{
   register_plugin("Ad Manager", "1.0", "Rivit");
   
   gmsgSayText = get_user_msgid("SayText");

   set_task(10.0, "load");
}

public load()
{
      new filepath[64];
      get_configsdir(filepath, 63);
      formatex(filepath, 63, "%s/advertisements.ini", filepath);

      if(!file_exists(filepath))
            set_fail_state("[Ad Manager] Nie mozna znalezc pliku advertisements.ini w configs/");

      new fHandle = fopen(filepath, "rt");

      if(!fHandle) return;

      reklamy = ArrayCreate(128, 1)
      
      new output[128];

      for(new a = 0; a < file_size(filepath, 1) && !feof(fHandle); a++)
      {
            fgets(fHandle, output, 127);

            if(!output[0] || output[0] == '^n' || output[0] == '^r' || output[0] == '^t' || output[0] == ' ' || output[0] == ';')  continue;
            trim(output)
            setColor(output, charsmax(output));

            ArrayPushString(reklamy, output)
      }

      if(ArraySize(reklamy))
            set_task(CZAS_TASK.0, "eventTask", _, _, _, "b");

      fclose(fHandle);
}

public eventTask()
{
      currAd = (currAd < ArraySize(reklamy) - 1) ? currAd + 1 : 0

      new message[128]
      ArrayGetString(reklamy, currAd, message, charsmax(message))

      new plist[32], playernum, player;  
      get_players(plist, playernum, "c");
 
      for(new i = 0; i < playernum; i++)
      {
            player = plist[i];
            message_begin(MSG_ONE, gmsgSayText, {0,0,0}, player);
            write_byte(player);
            write_string(message);
            message_end();
      }

      return PLUGIN_HANDLED;
}

setColor(string[], len)
{
   if (contain(string, "!t") != -1 || contain(string, "!g") != -1 || contain(string,"!n") != -1)
   {
      replace_all(string, len, "!t", "^x03");
      replace_all(string, len, "!n", "^x01");
      replace_all(string, len, "!g", "^x04");
      
      format(string, len, "^x01%s", string);
   }
}