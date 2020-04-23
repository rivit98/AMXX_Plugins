/********************************************* 
* (c) 2002-2003, OLO 
* This file is provided as is (no warranties). 
**********************************************
* Ported by Burnzy
*  Visit www.burnsdesign.org
**********************************************
* Radio and chicken kill announcement on cs_italy.
*
* Changelog:
*  1.1: -Made so when u blew up radio, it showed ur name
*       -Made so when u killed a chicken, it showed ur name
*  1.0: -First Release
*********************************************/

#include <amxmodx>

public plugin_init()
{
  register_plugin( "Italy Bonus Kill", "1.1", "OLO"  )
  
  new mapname[32]
  get_mapname( mapname, 31  )
  
  if ( equali( mapname ,  "cs_italy"  ) )
  {
    register_event( "23" , "chickenKill", "a" , "1=108" , /*"12=106",*/ "15=4" )
    register_event( "23" , "radioKill", "a" , "1=108" , /*"12=294",*/ "15=2" )
  }  
}

public chickenKill()
{
  new kill = read_data(1);
  new killer_name[33]
  get_user_name(kill,killer_name,32)
  set_hudmessage(200, 100, 0, -1.0, 0.70, 0, 0.5, 5.0, 0.05, 0.05, 2)
  show_hudmessage(0,"%s killed one of the fuckin' chickens!!!", killer_name)
}

public radioKill()
{
  new kill = read_data(1);
  new killer_name[33]
  get_user_name(kill,killer_name,32)
  set_hudmessage(200, 100, 0, -1.0, 0.70, 0, 0.5 , 5.0, 0.05, 0.05, 2)
  show_hudmessage(0,"%s blew up the big ass radio!!!", killer_name)  
}