#if defined _smsshop_included
	#endinput
#endif
#define _smsshop_included

#define MAX_ILOSC_USLUG 32
#define MAX_ILOSC_JEDNOSTEK_ILOSCI 16

#define DL_PELNEJ_NAZWY_USLUGI 64
#define DL_KROTKIEJ_NAZWY_USLUGI 32
#define DL_PELNEJ_KWOTY_USLUGI 64
#define DL_KROTKIEJ_KWOTY_USLUGI 8
#define DL_PELNEJ_ILOSCI_USLUGI 16
#define DL_KROTKIEJ_ILOSCI_USLUGI 8
#define DL_TRESCI_SMS 16
#define DL_NUMERU_SMS 8

#define DL_NAZWY_API 32

#define SS_CONTINUE PLUGIN_CONTINUE
#define SS_STOP PLUGIN_HANDLED

/*
	Rejestruje usluge
	
	szPelnaNazwaUslugi[] - pelna nazwa uslugi ktora wykorzystana bedzie w m.in. menu wyboru uslug
	szKrotkaNazwaUslugi[] - krotka nazwa uslugi ktora wykorzystywana bedzie w m.in. zapisie uslugi dla gracza na serwerze, sciezki do okienka MOTD, itd.
	iWymaganaFlagaUslugi - jaka gracz musi miec flage aby moc skorzystac z tej uslugi? 0 - nie musi miec flagi
	
	Zwraca: index uslugi
*/
native ss_register_service(szPelnaNazwaUslugi[], szKrotkaNazwaUslugi[], const iWymaganaFlagaUslugi = 0);

/*
	Dodaje jednostke ilosci dla uslugi
	
	iUsluga - index uskugi do jakiej zostanie dodany czas
	szPelnaJednostkaIlosciUslugi[] - pelna nazwa jednostki ilosci uslugi wykorzystywana w m. in. menu wyboru ilosci
	szKrotkaJednostkaIlosciUslugi[] - krotka jednostka ilosci np. ilosc monet, ilosc dni - wykorzystywana w skryptach
	szPelnaKwotaUslugi[] - pelna kwota uslugi wykorzystywana w m. in. menu wyboru czasow
	szKrotkaKwotaUslugi[] - krotka kwota uslugi wykorzystywana w m. in. API SMS
	
	Zwraca: id jednostki ilosci
*/
native ss_add_service_qu(iUsluga, szPelnaJednostkaIlosciUslugi[], szKrotkaJednostkaIlosciUslugi[], szPelnaKwotaUslugi[], szKrotkaKwotaUslugi[]);

/*
	Rejestruje API
	
	szNazwaAPI[] - nazwa nowego API
	
	Zwraca: index API
*/
native ss_register_api(szNazwaAPI[]);

//Zwraca 1 jezeli API jest wlaczone, 0 - wylaczone
native ss_is_api_enabled();

//Zwraca ilosc uslug
native ss_get_services_num();

//Zwraca ilosc jednostek ilosci uslugi
native ss_get_service_qus_num(iUsluga);

/*
	Otwiera graczowi menu wybierania sposobu platnosci. Przydatne kiedy zatrzymalismy otwieranie tego menu w ss_buy_service_pre, a potem chcemy do tego wrocic
	
	id - id gracza
	
	Zwraca: ...
*/
native ss_go_to_choosing_pay_method(id);

/*
	Dodaje juz kupiona usluga graczowi
	
	id - id gracza
	iUsluga - id uslugi
	iJednostkaIlosci - id jednostki ilosci uslugi
	
	Zwraca: ...
*/
native ss_add_user_service(id, iUsluga, iJednostkaIlosci);

//Finalizuje caly zakup - wyswietla informacje o zakupie dla gracza oraz loguje zakup w pliku
native ss_finalize_user_service(id);

//Zwraca usluge ktora ostatnio gracz wybral w menu, przydatne do sprawdzanie ktora usluge chce kupic
native ss_get_last_user_service(id);

//Zwraca jednostke ilosci jaka ostatnio gracz wybral w menu, przydatne do sprawdzenia ilosci dla kupionej uslugi
native ss_get_last_user_qu(id);

/*
	Zwraca ostatni wpisany przez gracza kod SMS
	
	id - id gracza
	szKodSMS[] - tablica, do ktorej zwrocony zostanie kod SMS
	iLen - dlugosc tablicy
	
	Zwraca:...
*/
native ss_get_last_user_sms_code(id, szKodSMS[], iLen);

//Zwraca index gracza, ktorego kod SMS jest sprawdzany, 0 - brak kupujacego
native ss_get_buyer_id();

/*
	Ustawia index kupujacego
	
	id - index nowego kupujacego
	
	Zwraca:...
*/
native ss_set_buyer_id(id);

/*
	Ustawia dostep do uslugi
	
	iUsluga - index uslugi
	iDostep - 1: kazdy ma dostep do zakupu uslugi, 0: nikt nie ma dostepu do zakupu uslugi
	
	Zwraca:...
*/
native ss_set_access_to_service(iUsluga, iDostep)

/*
	Ustawia tresc SMS dla uslugi
	
	iUsluga - index uslugi
	szTrescSMS[] - tresc SMS jaka zostanie ustawiona
	
	Zwraca: ...
*/
native ss_set_service_sms_content(iUsluga, iJednostkaIlosci, szTrescSMS[]);

/*
	Ustawia numer SMS dla uslugi
	
	iUsluga - index uslugi
	jJednostkaIlosci - index jednostki ilosci
	szNumerSMS[] - numer SMS jaka zostanie ustawiony
	
	Zwraca: ...
*/
native ss_set_service_sms_number(iUsluga, iJednostkaIlosci, szNumerSMS[]);

/*
	Zwraca pelna nazwe uslugi
	
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	szNazwa[] - tablica, do ktorej zwrocona zostanie pelna nazwa uslugi
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_full_service_name(iUsluga, szNazwa[], iLen);

/*
	Zwraca krotka nazwe uslugi
	
	iUsluga - index uslugi
	szNazwa[] - tablica, do ktorej zwrocona zostanie krotka nazwa uslugi
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_short_service_name(iUsluga, szNazwa[], iLen);

/*
	Zwraca pelna cene uslugi
	
	iUsluga - index uslugi
	szNazwa[] - tablica, do ktorej zwrocona zostanie pelna cena uslugi
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_full_service_price(iUsluga, iJednostkaIlosci, szCena[], iLen);

/*
	Zwraca krotka cene uslugi
	
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	szNazwa[] - tablica, do ktorej zwrocona zostanie krotka cena uslugi
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_short_service_price(iUsluga, iJednostkaIlosci, szCena[], iLen);

/*
	Zwraca pelna jednostke ilosci uslugi
	
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	szJednostkaIlosci[] - tablica, do ktorej zwrocona zostanie pelna jednostka ilosci
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_full_service_qu(iUsluga, iJednostkaIlosci, szJednostkaIlosci[], iLen);

/*
	Zwraca krotka jednostke ilosci uslugi
	
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	szJednostkaIlosci[] - tablica, do ktorej zwrocona zostanie krotka jednostka ilosci
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_short_service_qu(iUsluga, iJednostkaIlosci, szJednostkaIlosci[], iLen);

/*
	Zwraca tresc SMS dla uslugi
	
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	szNazwa[] - tablica, do ktorej zwrocona zostanie tresc SMS uslugi
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_service_sms_content(iUsluga, iJednostkaIlosci, szTresc[], iLen);

/*
	Zwraca numer SMS dla uslugi
	
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	szNazwa[] - tablica, do ktorej zwrocony zostanie numer SMS uslugi
	iLen - dlugosc talbicy
	
	Zwraca: ...
*/
native ss_get_service_sms_number(iUsluga, iJednostkaIlosci, szNumer[], iLen);

/*
	Wywolwany tuz przed pojawienia sie okna z danymi do SMSa
	
	id - index kupujacego usluge
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	
	Zwroc SS_STOP aby zatrzymac kupowanie uslugi
*/
forward ss_buy_service_pre(id, iUsluga, iJednostkaIlosci);

/*
	Wywolywany po wklepaniu kodu zwrotnego z SMS
	
	id - index kupujacego usluge
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	szKod[] - kod zwrotny SMS
	
	Zwroc SS_STOP aby zatrzymac dalsze kupowanie uslugi
*/
forward ss_check_sms_code(id, iUsluga, iJednostkaIlosci, szKod[]);

/*
	Wywolany po sprawdzeniu czy kod SMS jest prawidlowy
	
	id - index kupujacego usluge
	iUsluga - index uslugi
	iJednostkaIlosci - index jednostki ilosci
	
	Zwrot nie wplywa na dzialanie forwardu
*/
forward ss_buy_service_post(id, iUsluga, iJednostkaIlosci);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
