#include <amxmodx>
#include fakemeta
#include engine

new gMax
new classname[64], entnum, i;

public plugin_init() 
{
	register_plugin("Czysciciel", "1.0", "RiviT");
	
	register_event("HLTV", "Czysc", "a", "1=0", "2=0");
	gMax = get_maxplayers()
}

public Czysc()
{
      entnum = engfunc(EngFunc_NumberOfEntities);
      for(i = gMax; i <= entnum; i++)
      {
            if(!pev_valid(i)) continue;

		checkEnt(i)
      }
}

public client_disconnect(id)
{
      entnum = engfunc(EngFunc_NumberOfEntities);
      for(i = gMax; i <= entnum; i++)
      {
            if(!pev_valid(i) || pev(i, pev_owner) != id) continue;

		checkEnt(i)
      }
}

checkEnt(i)
{
      pev(i, pev_classname, classname, charsmax(classname))
      if(equal(classname, "paczka") || equal(classname, "dynamite") || equal(classname, "mine") || equal(classname, "sentry_shot") || equal(classname, "sentry_base") || equal(classname, "rocket") || equal(classname, "medkit") || equal(classname, "magnet") || equal(classname, "minef") || equal(classname, "bomb"))
            remove_entity(i)
}