/* COD MOD BY RiviT */


#if defined _codmod_included
  #endinput
#endif
#define _codmod_included

#define COD_CONTINUE 0
#define COD_STOP 4

#define STATUS_PREMIUM (1<<0)
#define STATUS_SPREMIUM (1<<1)

#pragma tabsize 0

native cod_add_user_clan_gold(id, ile)
native bool:cod_get_user_clan(id)
native cod_add_user_bonus_trim(id, wartosc);
native cod_add_user_bonus_stamina(id, wartosc);
native cod_add_user_bonus_intelligence(id, wartosc);
native cod_add_user_bonus_health(id, wartosc);
native cod_add_user_xp(id, wartosc);
forward cod_klan_changed(id, const nazwaKlanu[])
native cod_get_bonus_weapons_bitsum(id)
native cod_get_perk_durability(id)
native cod_set_perk_durability(id, wartosc)
native cod_user_fast_reload(id, bool:mode)
native cod_set_user_rendering(id, ile)
native cod_remove_user_rendering(id)
native cod_refresh_rendering(id)

native cod_get_user_status(id);
/*------------------------------
Zwraca status gracza
0 - Zwykly gracz
1 - Gracz Premium
2 - Gracz Super Premium
3 - Gracz Premium i Super Premium
------------------------------*/

native cod_get_user_xp(id);
/*------------------------------
Zwraca doswiadczenie gracza
------------------------------*/


native cod_get_user_level(id);
/*------------------------------
Zwraca poziom gracza
------------------------------*/

native cod_set_user_xp(id, wartosc);
/*------------------------------
Ustawia doswiadczenie gracza
------------------------------*/


native cod_get_user_class(id);
/*------------------------------
Zwraca klase gracza
------------------------------*/


native cod_set_user_class(id, klasa, zmien=0);
/*------------------------------
Ustawia klase gracza, 
jezeli zmien=1 zmienia ja natychmiast
------------------------------*/


native cod_get_user_perk(id, &wartosc=0);
/*------------------------------
Zwraca perk gracza, 
oraz przypisuje zmiennej wartosc wartosc perku
------------------------------*/

native cod_set_user_perk(id, perk, wartosc=-1, pokaz_info=1);
/*------------------------------
Ustawia perk gracza. 
Jezeli wartosc = -1, wartosc perku bedzie losowa.
Jezeli perk = -1 perk bedzie losowy
------------------------------*/

native cod_get_classes_num();


native cod_get_user_health(id, zdrowie_zdobyte=1, zdrowie_klasy=1, zdrowie_bonusowe=1);
/*------------------------------
Zwraca punkty statystyki zdrowie
------------------------------*/


native cod_get_user_intelligence(id, inteligencja_zdobyta=1, inteligencja_klasy=1, inteligencja_bonusowa=1);
/*------------------------------
Zwraca punkty statystyki inteligencja
------------------------------*/


native cod_get_user_trim(id, kondycja_zdobyta=1, kondycja_klasy=1, kondycja_bonusowa=1);
/*------------------------------
Zwraca punkty statystyki kondycja
------------------------------*/


native cod_get_user_stamina(id, wytrzymalosc_zdobyta=1, wytrzymalosc_klasy=1, wytrzymalosc_bonusowa=1);
/*------------------------------
Zwraca punkty statystyki wytrzymalosc
------------------------------*/


native cod_inflict_damage(attacker, victim, Float:dmg, Float:czynnik_inteligencji=1.0, byt_uszkadzajacy=0, damagebits=0);
/*------------------------------
Zadaje obrazenia z uwzglednieniem inteligencji
------------------------------*/


native cod_get_perkid(const nazwa_perku[]);
/*------------------------------
Zwaca numer perku o podanej nazwie
------------------------------*/

native cod_get_perk_name(perk, Return[], len);
/*------------------------------
Kopiuje nazwe perku do Return
------------------------------*/


native cod_get_perk_desc(perk, Return[], len);
/*------------------------------
Kopiuje opis perku do Return
------------------------------*/


native cod_get_classid(const nazwa_klasy[]);
/*------------------------------
Zwaca numer klasy o podanej nazwie
------------------------------*/


native cod_get_class_name(perk, Return[], len);
/*------------------------------
Kopiuje nazwe klasy do Return
------------------------------*/


native cod_get_class_desc(perk, Return[], len);
/*------------------------------
Kopiuje opis klasy do Return
------------------------------*/

native cod_get_perks_num();
//Zwraca ilosc perkow


native cod_give_weapon(id, bron);
/*------------------------------
Daje okreslona bron oraz pozwala na jej posiadanie
------------------------------*/


native cod_take_weapon(id, bron);
/*------------------------------
Zabiera okreslona bron oraz zabrania jej posiadania
------------------------------*/


native cod_register_perk(const nazwa[], const opis[], min_wartosc=0, max_wartosc=0);
/*------------------------------
Rejestruje nowy perk oraz zwraca jego numer
------------------------------*/


native cod_register_class(const nazwa[], const opis[], bronie, punkty_zdrowia, punkty_kondycji, punkty_inteligencji, punkty_wytrzymalosci, const frakcja[]);
/*------------------------------
Rejestruje nowa klase oraz zwraca jej numer
------------------------------*/	


native cod_get_level_xp(poziom);
/*------------------------------
Zwraca ilosc potrzebnego doswiadczenia do przejscia danego poziomu
------------------------------*/


forward cod_perk_changed(id, perk);
/*------------------------------
Forward wysylany do wszystkich pluginow w momencie zmiany perku
------------------------------*/


forward cod_class_changed(id, klasa);
/*------------------------------
Forward wysylany do wszystkich pluginow w momencie zmiany klasy
------------------------------*/


forward cod_perk_enabled(id, wartosc);
/*------------------------------
Forward wysylany do pluginu z ktorego zarejestrowany jest perk w momencie aktywacji
------------------------------*/


forward cod_perk_disabled(id);
/*------------------------------
Forward wysylany do pluginu z ktorego zarejestrowany jest perk w momencie dezaktywacji
------------------------------*/


forward cod_perk_used(id);
/*------------------------------
Forward wysylany do pluginu z ktorego zarejestrowany jest perk w momencie uzycia perku
------------------------------*/


forward cod_class_enabled(id);
/*------------------------------
Forward wysylany do pluginu z ktorego zarejestrowana jest klasa w momencie aktywacji
------------------------------*/


forward cod_class_disabled(id);
/*------------------------------
Forward wysylany do pluginu z ktorego zarejestrowana jest kasa w momencie dezaktywacji
------------------------------*/

forward cod_class_skill_used(id);
/*------------------------------
Forward wysylany do pluginu z ktorego zarejestrowana jest kasa w momencie uzycia umiejetnosci klasy
------------------------------*/