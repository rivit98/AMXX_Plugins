#if defined _csgo_included
  #endinput
#endif
#define _csgo_included

#include <ColorChat>
#define CSGO_BLOCKWPNSKINS ((1<<2)|(1<<4)|(1<<6)|(1<<9)|(1<<25))

/*
Opis:
	Rejestruje nowa misje
	
Parametry: 
	szNazwa[] - nazwa misji
	szOpis[] - opis misji
	szNagroda[] - nagroda za misje
	iWymaganyPostep - wymagany postep wymagany do ukonczenia misji
	iWymaganaRanga - wymagana ranga do rozpoczecia misji
	
Zwraca:
	index misji
*/
native csgo_register_mission(szNazwa[], szOpis[], szNagroda[], iWymaganyPostep, iWymaganaRanga);

/*
Opis:
	Zwraca do tablicy nazwe rangi
	
Parametry: 
	iRanga- index rangi
	szNazwa[] - tablica, do ktorej zwrocona zostanie nazwa rangi
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_rank_name(iRanga, szNazwa[], iLen);

/*
Opis:
	Zwraca wymagana ilosc fragow dla rangi
	
Parametry: 
	iRanga - index rangi
	
Zwraca:
	wymagana ilosc fragow dla rangi
*/
native csgo_get_req_rank_frags(iRanga);

/*
Opis:
	Zwraca wymagany stosunek fragow/smierci dla rangi
	
Parametry: 
	iRanga - index rangi
	
Zwraca:
	wymagany stosunek fragow/smierci dla rangi
*/
native Float:csgo_get_req_rank_ratio(iRanga);

/*
Opis:
	Zwraca index rangi, opierajac sie o sprawdzanie jej nazwy
	
Parametry: 
	szNazwa[] - nazwa rangi, ktorej index ma zostac zwrocony
	
Zwraca:
	index rangi
*/
native csgo_get_rank_by_name(szNazwa[]);

/*
Opis:
	Zwraca ilosc rang
	
Parametry: 
	...
	
Zwraca:
	ilosc rang
*/
native csgo_get_ranksnum();

/*
Opis:
	Zwraca nazwe skina do tablicy
	
Parametry: 
	iBron - index broni (CSWID)
	iSkin - index skina
	szNazwa[] - tablica, do ktorej zostanie zwrocona nazwa skina
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_skin_name(iBron, iSkin, szNazwa[], iLen);

/*
Opis:
	Zwraca sciezke do skina (model V) do tablicy
	
Parametry: 
	iBron - index broni (CSWID)
	iSkin - index skina
	szSciezka[] - tablica, do ktorej zostanie zwrocona sciezka
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_skin_way_to_mdl(iBron, iSkin, szNazwa[], iLen);

/*
Opis:
	Zwraca sciezke do skina (model P) do tablicy
	
Parametry: 
	iBron - index broni (CSWID)
	iSkin - index skina
	szSciezka[] - tablica, do ktorej zostanie zwrocona sciezka
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_skin_way_to_p_mdl(iBron, iSkin, szNazwa[], iLen);

/*
Opis:
	Zwraca index skina, opierajac sie o sprawdzanie jego nazwy
	
Parametry: 
	iBron - index broni (CSW)
	szNazwa[] - nazwa skina, ktorego index ma zostac zwrocony
	
Zwraca:
	index rangi
*/
native csgo_get_skin_by_name(iBron, szNazwa[]);


/*
Opis:
	Zwraca ilosc skinow
	
Parametry: 
	iBron - index broni
	
Zwraca:
	ilosc skinow danej broni
*/
native csgo_get_skinsnum(iBron);

/*
Opis:
	Zwraca nazwe skrzynki do tablicy
	
Parametry: 
	iSkrzynka - index skrzynki
	szNazwa[] - tablica, do ktorej zostanie zwrocona nazwa skrzynki
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_crate_name(iSkrzynka, szNazwa[], iLen);

/*
Opis:
	Zwraca sume broni skrzynki
	
Parametry: 
	iSkrzynka - index skrzynki
	
Zwraca:
	sume broni skrzynki
*/
native csgo_get_crate_weaponssum(iSkrzynka);

/*
Opis:
	Zwraca szanse na trafienie skrzynki
	
Parametry: 
	iSkrzynka - index skrzynki
	
Zwraca:
	szanse na trafienie skrzynki
*/
native csgo_get_crate_chance_to_drop(iSkrzynka);

/*
Opis:
	Zwraca szanse na trafienie skina w skrzynce
	
Parametry: 
	iSkrzynka - index skrzynki
	
Zwraca:
	szanse na trafienie skina
*/
native csgo_get_crate_chance_to_drop_s(iSkrzynka);

/*
Opis:
	Zwraca index skzrynki, opierajac sie o sprawdzanie jej nazwy
	
Parametry: 
	szNazwa[] - nazwa skrzynki, ktorej index ma zostac zwrocony
	
Zwraca:
	index skrzynki
*/
native csgo_get_crate_by_name(szNazwa[]);


/*
Opis:
	Zwraca ilosc skrzynek
	
Parametry: 
	...
	
Zwraca:
	ilosc skrzynek
*/
native csgo_get_cratesnum();

/*
Opis:
	Zwraca nazwe misji do tablicy
	
Parametry: 
	iMisja - index misji
	szNazwa[] - tablica, do ktorej zostanie zwrocona nazwa misji
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_mission_name(iMisja, szNazwa[], iLen);

/*
Opis:
	Zwraca opis misji do tablicy
	
Parametry: 
	iMisja - index misji
	szOpis[] - tablica, do ktorej zostanie zwrocony opis misji
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_mission_desc(iMisja, szOpis[], iLen);

/*
Opis:
	Zwraca nagrode za misje do tablicy
	
Parametry: 
	iMisja - index misji
	szNazwa[] - tablica, do ktorej zostanie zwrocona nagroda za misje
	iLen - dlugosc tablicy
	
Zwraca:
	...
*/
native csgo_get_mission_reward(iMisja, szNagroda[], iLen);

/*
Opis:
	Zwraca postep wymagany do ukonczenia misji
	
Parametry: 
	iMisja - index misji
	
Zwraca:
	postep wymagany do ukonczenia misji
*/
native csgo_get_req_mission_progress(iMisja);

/*
Opis:
	Zwraca wymagana range potrzebna do podjecia sie misji
	
Parametry: 
	iMisja - index misji
	
Zwraca:
	wymagana range, ktora jest potrzebna do podjecia sie misji
*/
native csgo_get_req_mission_rank(iMisja);

/*
Opis:
	Zwraca ilosc misji
	
Parametry: 
	...
	
Zwraca:
	ilosc misji
*/
native csgo_get_missionsnum();

/*
Opis:
	Zwraca range gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	range gracza
*/
native csgo_get_user_rank(id);

/*
Opis:
	Zwraca fragi gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	fragi gracza
*/
native csgo_get_user_frags(id);

/*
Opis:
	Zwraca smierci gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	smierci gracza
*/
native csgo_get_user_deaths(id);

/*
Opis:
	Zwraca domyslny skin gracza dla danej broni
	
Parametry: 
	id - index gracza
	iBron - index broni (CSWID)
	
Zwraca:
	domyslnego skina dla danej broni gracza
*/
native csgo_get_user_default_skin(id, iBron);

/*
Opis:
	Zwraca ilosc danych skinow
	
Parametry: 
	id - index gracza
	iBron - index broni (CSWID)
	iSkin - index skina
	
Zwraca:
	ilosc danych skinow
*/
native csgo_get_user_skins(id, iBron, iSkin);

/*
Opis:
	Zwraca klucze gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	klucze gracza
*/
native csgo_get_user_keys(id);

/*
Opis:
	Zwraca skrzynki gracza
	
Parametry: 
	id - index gracza
	iSkrzynka - index skrzynki
	
Zwraca:
	skrzynki gracza
*/
native csgo_get_user_crates(id, iSkrzynka);

/*
Opis:
	Zwraca aktualna misje gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	index aktualnej misji, 0 - brak misji
*/
native csgo_get_user_active_mission(id);

/*
Opis:
	Zwraca postep misji gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	postep misji gracza
*/
native csgo_get_user_mission_progress(id);

/*
Opis:
	Zwraca ilosc euro gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	ilosc euro gracza
*/
native csgo_get_user_euro(id);

/*
Opis:
	Ustawia fragi gracza
	
Parametry: 
	id - index gracza
	iFragi - ilosc fragow do ustawienia
	
Zwraca:
	...
*/
native csgo_set_user_frags(id, iFragi);

/*
Opis:
	Ustawia smierci gracza
	
Parametry: 
	id - index gracza
	iSmierci - ilosc smierci do ustawienia
	
Zwraca:
	...
*/
native csgo_set_user_deahts(id, iSmierci);

/*
Opis:
	Ustawia domyslny skin gracza dla danej broni
	
Parametry: 
	id - index gracza
	iBron - id broni (CSWID)
	iSkin - id skina, ktory ma zostac ustawiony
	
Zwraca:
	...
*/
native csgo_set_user_default_skin(id, iBron, iSkin);

/*
Opis:
	Ustawia ilosc danych skinow
	
Parametry: 
	id - index gracza
	iBron - index broni (CSWID)
	iSkin - index skina ktory ma zostac ustawiony
	iIlosc - ilosc skinow
	
	
Zwraca:
	...
*/
native csgo_set_user_skins(id, iBron, iSkin, iIlosc);

/*
Opis:
	Ustawia klucze gracza
	
Parametry: 
	id - index gracza
	iKlucze - ilosc kluczy do ustawienia
	
Zwraca:
	...
*/
native csgo_set_user_keys(id, iKlucze);

/*
Opis:
	Ustawia skrzynki gracza
	
Parametry: 
	id - index gracza
	iSkrzynka - index skrzynki
	iIlosc - ilosc skrzynek do ustawienia
	
Zwraca:
	...
*/
native csgo_set_user_crates(id, iSkrzynka, iIlosc);

/*
Opis:
	Ustawia postep misji gracza
	
Parametry: 
	id - index gracza
	iPostep - postep jaki ma zostac ustawiony
	
Zwraca:
	...
*/
native csgo_set_user_mission_progress(id, iPostep);

/*
Opis:
	Ustawia wartosc euro gracza
	
Parametry: 
	id - index gracza
	iEuro - ilosc euro do ustawienia
	
Zwraca:
	...
*/
native csgo_set_user_euro(id, iEuro);

/*
Opis:
	Zwraca index pliku nVault z rangami
	
Parametry: 
	...
	
Zwraca:
	index pliku nVault z rangami
*/
native csgo_get_ranks_vaultid();

/*
Opis:
	Zwraca index pliku nVault ze skinami
	
Parametry: 
	...
	
Zwraca:
	index pliku nVault ze skinami
*/
native csgo_get_skins_vaultid();

/*
Opis:
	Zwraca index pliku nVault ze skrzynkami
	
Parametry: 
	...
	
Zwraca:
	index pliku nVault ze skrzynkami
*/
native csgo_get_crates_vaultid();

/*
Opis:
	Zwraca index pliku nVault z misjami
	
Parametry: 
	...
	
Zwraca:
	index pliku nVault z misjami
*/
native csgo_get_missions_vaultid();


/*
Opis:
	Otwiera menu 'Moje skiny'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_myskins(id);


/*
Opis:
	Otwiera menu 'Lista skinow'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_skinslist(id);


/*
Opis:
	Otwiera menu 'Moje skrzynki'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_mycrates(id);


/*
Opis:
	Otwiera MOTD 'Lista skrzynek'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_crateslist(id);


/*
Opis:
	Wymusza zakup klucza u gracza
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_buy_key(id);


/*
Opis:
	Otwiera menu 'Misje'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_missions(id);


/*
Opis:
	Otwiera MOTD 'Lista rang'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_rankslist(id);


/*
Opis:
	Otwiera MOTD 'Pomoc'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_help(id);


/*
Opis:
	Otwiera MOTD 'Komendy'
	
Parametry: 
	id - index gracza
	
Zwraca:
	...
*/
native csgo_open_commands(id);


/*
Opis:
	Wywolywany w trakcie rozpoczecia misji
	
Parametry:
	id - index gracza
	iMisja - index misji
*/
forward csgo_user_mission_start(id, iMisja);

/*
Opis:
	Wywolywany w trakcie zakonczenia misji
	
Parametry:
	id - index gracza
	iMisja - index misji
*/
forward csgo_user_mission_complete(id, iMisja);

/*
Opis:
	Wywolywany w trakcie awansu rangi gracza
	
Parametry:
	id - index gracza
	iRanga - ranga, do ktorej awansowal
*/
forward csgo_user_rank_advance(id, iRanga);

//Stocki

public csgo_print_message(id, const szWiadomosc[], any:...) {
	new szFormatowanaWiadomosc[256];
	vformat(szFormatowanaWiadomosc, 255, szWiadomosc, 3);
	
	ColorChat(id, GREEN, "[CSGO:MOD]^x01 %s", szFormatowanaWiadomosc);
}

stock csgo_get_short_weaponname(iBron, szNazwa[], iLen) {
	new szNazwaBroni[32];
	get_weaponname(iBron, szNazwaBroni, 31);
	copy(szNazwa, iLen, szNazwaBroni[7]);
	strtoupper(szNazwa);
}

stock csgo_format_euro(iEuro, szEuro[], iLen) {
	new szEuro2[2][8], iMscKropki; 
	num_to_str(iEuro, szEuro2[0], 7);
	iMscKropki = strlen(szEuro2[0]);
	
	if(iMscKropki >= 3) {
		iMscKropki -= 2;
		copy(szEuro2[1], 7, szEuro2[0][iMscKropki]);
		copy(szEuro2[0][iMscKropki], 7-iMscKropki, "");
		formatex(szEuro, iLen, "%s.%s", szEuro2[0] ,szEuro2[1]);
	}
	else {
		formatex(szEuro, iLen, "0.%02d", iEuro);
	}
}
