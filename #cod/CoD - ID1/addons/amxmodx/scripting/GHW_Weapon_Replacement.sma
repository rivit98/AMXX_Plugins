#define VERSION   "1.3"

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define MAX_SOUNDS   50
#define MAX_p_MODELS   50
#define MAX_v_MODELS   50
#define MAX_w_MODELS   50

#define MAP_CONFIGS   1

new Array: vArrayModels;

new new_sounds[MAX_SOUNDS][48]
new old_sounds[MAX_SOUNDS][48]
new soundsnum

new new_p_models[MAX_p_MODELS][48]
new old_p_models[MAX_p_MODELS][48]
new p_modelsnum

new new_w_models[MAX_w_MODELS][48]
new old_w_models[MAX_w_MODELS][48]
new w_modelsnum

new maxplayers
new bool: bModels[ 33 ];

public plugin_init()
{
   register_plugin("Weapon Model + Sound Replacement",VERSION,"GHW_Chronic Edited by DarkGL edited by RiviT")
   register_forward(FM_EmitSound,"Sound_Hook")
   register_forward(FM_SetModel,"W_Model_Hook",1)
   
   register_event("CurWeapon","Changeweapon_Hook","be","1=1")
   
   register_logevent("newround",2,"1=Round_Start")
   
   register_forward( FM_UpdateClientData , "fmClientData" , 1 );
   
   maxplayers = get_maxplayers()
   
   register_clcmd( "say /models" ,       "modelCommand" );
   register_clcmd( "say /modele" ,       "modelCommand" );
   register_clcmd( "say_team /models" ,    "modelCommand" );
   register_clcmd( "say_team /modele" ,    "modelCommand" );
}

public modelCommand( id )
   bModels[ id ]   =   !bModels[ id ];

public client_connect( id )
   bModels[ id ]   =   true;

public plugin_precache()
{
      register_cvar("ghw_zestaw_modeli", "1")
      new val = get_cvar_num("ghw_zestaw_modeli")
      new configfile[200]
      formatex(configfile, 199, "addons/amxmodx/configs/ghw/new_weapons%i.ini", val)
   
      if(file_exists(configfile))
            load_models(configfile)
      else
            set_fail_state("Nie ma zestawu numer %i", val)
}

public load_models(configfile[]){
   vArrayModels   =   ArrayCreate( 2 , 1 );
   new iArray[ 3 ];

      new read[96], left[48], right[48], right2[32], trash
      for(new i=0;i<file_size(configfile,1);i++)
      {
         read_file(configfile,i,read,95,trash)
         if(containi(read,";")!=0 && containi(read," ")!=-1)
         {
            strbreak(read,left,47,right,47)
            if(containi(right," ")!=-1)
            {
               strbreak(right,right,47,right2,31)
               replace_all(right2,31,"^"","")
            }
            replace_all(right,47,"^"","")
            if(file_exists(right))
            {
               if(containi(right,".mdl")==strlen(right)-4)
               {
                  new iPrecache   =   precache_model(right);
                  if(!iPrecache)
                  {
                     log_amx("Error attempting to precache model: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
                  }
                  else if(containi(left,"models/p_")==0)
                  {
                     formatex(new_p_models[p_modelsnum],47,right)
                     formatex(old_p_models[p_modelsnum],47,left)
                     p_modelsnum++
                  }
                  else if(containi(left,"models/v_")==0)
                  {
                     new iPrecacheOld   =   precache_model( left );
                     if( iPrecacheOld ){
                        iArray[ 0 ]      =   iPrecacheOld;
                        iArray[ 1 ]    =   iPrecache;
                        ArrayPushArray( vArrayModels , iArray )
                     }
                  }
                  else if(containi(left,"models/w_")==0)
                  {
                     formatex(new_w_models[w_modelsnum],47,right)
                     formatex(old_w_models[w_modelsnum],47,left)
                     w_modelsnum++
                  }
                  else
                  {
                     log_amx("Model type(p_ / v_ / w_) unknown for model: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
                  }
               }
               else if(containi(right,".wav")==strlen(right)-4 || containi(right,".mp3")==strlen(right)-4)
               {
                  replace(right,47,"sound/","")
                  replace(left,47,"sound/","")
                  if(!precache_sound(right))
                  {
                     log_amx("Error attempting to precache sound: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
                  }
                  else
                  {
                     formatex(new_sounds[soundsnum],47,right)
                     formatex(old_sounds[soundsnum],47,left)
                     soundsnum++
                  }
               }
               else
               {
                  log_amx("Invalid File: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
               }
            }
            else
            {
               log_amx("File Inexistent: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
            }
            /*if(!file_exists(left))
            {
               log_amx("Warning: File Inexistent: ^"%s^" (Line %d of new_weapons.ini). ONLY A WARNING. PLUGIN WILL STILL WORK!!!!",left,i+1)
            }*/
         }
      }
}

public fmClientData( id, sendweapons, cd_handle ){
   if( !is_user_connected( id ) || !bModels[ id ] || get_cd( cd_handle , CD_ViewModel ) == 0){
      return FMRES_IGNORED;
   }
   new iArray[ 3 ] ,
      oldWeapon   =   get_cd( cd_handle , CD_ViewModel );
      
   for( new i = 0 ; i < ArraySize( vArrayModels ) ; i++ ){
      
      ArrayGetArray( vArrayModels , i , iArray );
      
      if( iArray[ 0 ]   ==   oldWeapon ){
         
         set_cd( cd_handle , CD_ViewModel , iArray[ 1 ] );
         return FMRES_HANDLED;
         
      }
   }
   
   return FMRES_IGNORED;
}

public Changeweapon_Hook(id)
{
   if(!is_user_alive(id))
   {
      return PLUGIN_CONTINUE
   }
   static model[32], i

   pev(id,pev_weaponmodel2,model,31)
   for(i=0;i<p_modelsnum;i++)
   {
      if(equali(model,old_p_models[i]))
      {
            set_pev(id,pev_weaponmodel2,new_p_models[i])
            break;
      }
   }
   return PLUGIN_CONTINUE
}

public Sound_Hook(id,channel,sample[])
{
   if(!is_user_alive(id))
   {
      return FMRES_IGNORED
   }
   if(channel!=CHAN_WEAPON && channel!=CHAN_ITEM)
   {
      return FMRES_IGNORED
   }

   static i

   for(i=0;i<soundsnum;i++)
   {
      if(equali(sample,old_sounds[i]))
      {
            engfunc(EngFunc_EmitSound,id,CHAN_WEAPON,new_sounds[i],1.0,ATTN_NORM,0,PITCH_NORM)
            return FMRES_SUPERCEDE
      }
   }
   return FMRES_IGNORED
}

public W_Model_Hook(ent,model[])
{
   if(!pev_valid(ent))
   {
      return FMRES_IGNORED
   }
   static i
   for(i=0;i<w_modelsnum;i++)
   {
      if(equali(model, old_w_models[i]))
      {
         engfunc(EngFunc_SetModel,ent,new_w_models[i])
         return FMRES_SUPERCEDE
      }
   }
   return FMRES_IGNORED
}

public newround()
{
   static ent, classname[8], model[32]
   ent = engfunc(EngFunc_FindEntityInSphere,maxplayers,Float:{0.0,0.0,0.0},4800.0)
   while(ent)
   {
      if(pev_valid(ent))
      {
         pev(ent,pev_classname,classname,7)
         if(containi(classname,"armoury")!=-1)
         {
            pev(ent,pev_model,model,31)
            W_Model_Hook(ent,model)
         }
      }
      ent = engfunc(EngFunc_FindEntityInSphere,ent,Float:{0.0,0.0,0.0},4800.0)
   }
}
