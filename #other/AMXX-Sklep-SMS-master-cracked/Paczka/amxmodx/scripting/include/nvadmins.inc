#if defined _nvadmins_included
  #endinput
#endif
#define _nvadmins_included

native na_add_admin(szKlucz[], iRodzajKlucza, szDodatkowyParametr[], szFlagi[], szDataWaznosci[], szOpis[]);
/***************************
	Dodaje nowego admina
	
	Parametry
		szKlucz[] - klucz admina
		iRodzajKlucza - rodzaj klucza, 1 - Nick, 2 - SID, 3-IP
		szDodatkowyParametr[] - dodatkowy parametr dla klucza
		szFlagi[] - flagi admina
		szDataWaznosci[] - data wygasniecia admina
		szOpis[] - opis dodanego admina
		
	Zwraca
		PLUGIN_CONTINUE w przypadku powodzenia
		
***************************/

native na_edit_admin(szKlucz[], iRodzajKlucza, iWpis, szFlagi[], szDataWaznosci[], szOpis[])
/***************************
	Edytuje admina
	
	Parametry
		szKlucz[] - klucz admina
		iRodzajKlucza - rodzaj klucza, 1 - Nick, 2 - SID, 3-IP
		iWpis - nr wpisu ktory ma zostac edytowany
		szFlagi[] - flagi jakie ma ustawic, pozostaw puste aby nic nie zmieniac w zapisie
		szDataWaznosci[] - data waznosci jaka ma ustawic, pozostaw puste aby nic nie zmieniac w zapisie
		szOpis[] - opis / dodatkowy parametr klucza, w zaleznosci od wpisu, pozostaw puste aby nic nie zmieniac w zapisie (jesli chodzi o opis)
		
	Zwraca
		PLUGIN_CONTINUE w przypadku powodzenia
		PLUGIN_HANDLED w przypadku niepowodzenia
		
***************************/

native na_delete_admin(szKlucz[], iRodzajKlucza, iWpis)
/***************************
	Usuwa admina
	
	Parametry
		szKlucz[] - klucz admina
		iRodzajKlucza - rodzaj klucza, 1 - Nick, 2 - SID, 3-IP
		iWpis - nr wpisu ktory ma zostac usuniety, 0 - usuwa wszystkie wpisy admina
		
	Zwraca
		...
		
***************************/

native na_has_admin(szKlucz[], iRodzajKlucza)
/***************************
	Sprawdza czy dany admin istnieje
	
	Parametry
		szKlucz[] - klucz admina
		iRodzajKlucza - rodzaj klucza, 1 - Nick, 2 - SID, 3-IP
		
	Zwraca
		1 jezeli istnieje, 0 jezeli nie istnieje
		
***************************/

native na_has_admin_with_desc(szKlucz[], iRodzajKlucza, szOpis[])
/***************************
	Sprawdza czy dany admin ma przypisane flagi z danym opisem
	
	Parametry
		szKlucz[] - klucz admina
		iRodzajKlucza - rodzaj klucza, 1 - Nick, 2 - SID, 3-IP
		szOpis[] - opis admina
		
	Zwraca
		1 jezeli istnieje, 0 jezeli nie istnieje
		
***************************/

native na_get_nvaultid()
//Zwraca index pliku nVault

/***************************
	Zwraca index gracza na podstawie rodzaju klucza
	
	Parametry
		iRodzajKlucza - rodzaj klucza, 1 - Nick, 2 - SID, 3-IP
		szKlucz[] - klucz gracza
		
	Zwraca
		index znalezionego gracza, 0 - nic nie znaleziono
		
***************************/
stock na_get_user_index(iRodzajKlucza, const szKlucz[])
{
	new szKluczGracza[64];
	
	switch(iRodzajKlucza)
	{
		case 1: return get_user_index(szKlucz);
		case 2:
		{
			for(new id = 1; id <= g_iIloscSlotow; id++)
			{
				if(!is_user_connected(id))
					continue;
				
				get_user_authid(id, szKluczGracza, 63);
				
				if(equal(szKlucz, szKluczGracza))
					return id;
			}
		}
		case 3:
		{
			for(new id = 1; id <= g_iIloscSlotow; id++)
			{
				if(!is_user_connected(id))
					continue;
				
				get_user_ip(id, szKluczGracza, 63);
				
				if(equal(szKlucz, szKluczGracza))
					return id;
			}
		}
	}
	
	return 0;
}

/***************************
	Zwraca do tablicy klucz gracza na podstawie jego rodzaju
	
	Parametry
		id - index gracza
		iKey - rodzaj klucza, 1 - Nick, 2 - SID, 3-IP
		szReturn[] - tablica do ktorej zostanie zwrocony klucz gracza
		iLen - wielkosc tablicy
		
	Zwraca
		...
		
***************************/
stock na_get_user_key(id, iKey, szReturn[], iLen)
{
	switch(iKey)
	{
		case 1: get_user_name(id, szReturn, iLen);
		case 2: get_user_authid(id, szReturn, iLen);
		case 3: get_user_ip(id, szReturn, iLen);
	}
}

stock na_get_data_after_days(iDaysNum, szReturn[], iLen)
{
	new iMaksIloscDni[] = { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
	new szDane[3][10];
	new iDane[3];
	
	get_time("%d", szDane[0], 9);
	get_time("%m", szDane[1], 9);
	get_time("%Y", szDane[2], 9);
	
	iDane[0] = str_to_num(szDane[0]);
	iDane[1] = str_to_num(szDane[1]);
	iDane[2] = str_to_num(szDane[2]);
	
	if(floatfract(float(iDane[2])/4.0) == 0.0)
		iMaksIloscDni[2] ++;
	
	iDane[0] += iDaysNum;
	
	while(iDane[0] > iMaksIloscDni[iDane[1]])
	{
		iDane[0] -= iMaksIloscDni[iDane[1]];
		iDane[1] ++;
		
		if(iDane[1] == 13)
		{
			iDane[1] = 1;
			iDane[2] ++;
		}
	}
	
	formatex(szReturn, iLen, "%d-%d-%d", iDane[0], iDane[1], iDane[2]);
}

	
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
