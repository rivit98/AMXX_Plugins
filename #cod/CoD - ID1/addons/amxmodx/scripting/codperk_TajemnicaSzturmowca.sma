#include <amxmodx>
#include <hamsandwich>
#include <codmod>

#define DMG_BULLET (1<<1)

new const perk_name[] = "Tajemnica Szturmowca";
new const perk_desc[] = "Dostajesz M4A1 i dodatkowe 10 obrazen z niego";

new bool:ma_perk[33];

public plugin_init()
{
        register_plugin(perk_name, "1.0", "RiviT");
  
        cod_register_perk(perk_name, perk_desc);
        RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
}

public cod_perk_enabled(id)
{
        cod_give_weapon(id, CSW_M4A1);
        ma_perk[id] = true;
}

public cod_perk_disabled(id)
{
        cod_take_weapon(id, CSW_M4A1);
        ma_perk[id] = false;
}
  
public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
        if(!is_user_connected(idattacker))
                return HAM_IGNORED;
  
        if(!ma_perk[idattacker])
                return HAM_IGNORED;
  
        if(get_user_weapon(idattacker) == CSW_M4A1 && damagebits & DMG_BULLET)
        {
               SetHamParamFloat(4, damage+10)
               return HAM_HANDLED
      }
          
        return HAM_IGNORED;
}