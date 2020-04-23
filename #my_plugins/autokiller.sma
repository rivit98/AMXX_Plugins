#include <amxmodx>
#include dhudmessage

#define TASKID_KILL 3215
#define TASKID_ODLICZANIE 3217

new iTime;

public plugin_init()
{
	register_plugin("Autokiller", "1.0", "Rivit");

	register_event("HLTV", "Round_Start", "a", "1=0", "2=0");
      register_logevent("UsunTaski", 2, "0=World triggered", "1=Round_End");

	register_cvar("autokiller_time", "150")
}

public Round_Start()
{
      UsunTaski()
      iTime = 10
      set_task(float(get_cvar_num("autokiller_time")-10), "odlicz", TASKID_KILL)
}

public odlicz()
      set_task(1.0, "kill", TASKID_ODLICZANIE, _, _, "a", iTime)

public kill()
{
      set_dhudmessage(255, 255, 255, -1.0, 0.2, 0, _, 0.8, 0.1, 0.1, false);
      show_dhudmessage(0, "Automatyczne zabicie za:^n%i", --iTime)

      if(!iTime)
      {
            for(iTime = 1; iTime <= get_maxplayers(); iTime++)
            {
                  if(is_user_alive(iTime))
                        user_kill(iTime, 1)
            }
      }
}

public UsunTaski()
{
      remove_task(TASKID_KILL)
      remove_task(TASKID_ODLICZANIE)
}