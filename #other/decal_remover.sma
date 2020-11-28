#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

#define PLUGIN "Decal Remover"
#define AUTHOR "ConnorMcLeod"
#define VERSION "0.0.1"

#define FEV_RELIABLE (1<<1)
#define FEV_GLOBAL (1<<2)

new g_iDecalReset
new g_iTaskEnt

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    RegisterTask()

    g_iDecalReset = engfunc(EngFunc_PrecacheEvent, 1, "events/decal_reset.sc")
}

RegisterTask()
{
    new iEnt
    new iMaxEnts = global_get(glb_maxEntities)
    new szClassName[2]
    // without amxx, the ent id is maxplayers + 1
    // but if a plugin creates some entities during precache it won't
    // so use this code to retrieve the ent
    for(iEnt = get_maxplayers() + 1; iEnt<iMaxEnts; iEnt++)
    {
        if( pev_valid(iEnt) )
        {
            pev(iEnt, pev_classname, szClassName, charsmax(szClassName))
            if( !szClassName[0] )
            {
                g_iTaskEnt = iEnt
                RegisterHamFromEntity(Ham_Think, iEnt, "Task_RemoveDecals", 1)
                return
            }
        }
    }
}

public Task_RemoveDecals( iEnt )
{
    if( iEnt != g_iTaskEnt )
    {
    /*    new szClassName[32]
        pev(iEnt, pev_classname, szClassName, charsmax(szClassName))
        log_to_file("ClassLessEnt", szClassName)*/
        return
    }

    static iCount
    if( ++iCount % 2 == 0 )
    {
        engfunc(EngFunc_PlaybackEvent, FEV_RELIABLE|FEV_GLOBAL, 0, g_iDecalReset, 0.0, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0}, 0.0, 0.0, 0, 0, 0, 0)
    }
} 