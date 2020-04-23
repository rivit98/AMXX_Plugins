#include <amxmodx> 
#include <colorchat>


#define LOSOWANIE_VIP_OD 5
#define LOSOWANIE_W_KTOREJ_RUNDZIE 3
#define ILE_VIPOW_LOSOWAC 3
#define FLAGA_VIP ADMIN_LEVEL_H


new runda = 0;
new Float:hudpos = 0.4;
new const prefix[] = "[DARMOWY VIP]"

public plugin_init(){
	register_plugin("Losowanie X vipów", "1.0", "RiviT");

	register_logevent("Poczatek_Rundy", 2, "1=Round_Start")  
	set_task(120.0, "advert", _, _, _, "b")
}

public advert(){
	ColorChat(0, GREEN, "%s^x01 Zawsze w %d rundzie bedzie losowany^x03 VIP.^x01 Na serwerze musi byc conajmniej %d graczy, by losowanie sie odbylo!", prefix, LOSOWANIE_W_KTOREJ_RUNDZIE, LOSOWANIE_VIP_OD);
}

public Poczatek_Rundy(){   
	runda++
	if(runda == LOSOWANIE_W_KTOREJ_RUNDZIE){
		ColorChat(0, GREEN, "%s^x01 Uwaga! za moment zostanie rozlosowany^x03 darmowy vip^x01 na ta mape!", prefix);
		if(get_playersnum() >= LOSOWANIE_VIP_OD){
			LosujVipy();
		}else{
			ColorChat(0, GREEN, "%s^x01 Niestety, na serwerze nie bylo %d osob! Losowanie nie odbedzie sie", prefix, LOSOWANIE_VIP_OD);
		}
	}
}

public LosujVipy() 
{
	new Array:players = ArrayCreate(1, 32);
	for(new id = 1; id <= get_maxplayers(); id++){
		if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)){ //pomin niepolaczonych, botow, hltv
			continue;
		}

		if(get_user_flags(id) & FLAGA_VIP){ //pomin jak ktos juz ma vipa
			continue;
		}

		ArrayPushCell(players, id);
	}


	new ile_losowac = ILE_VIPOW_LOSOWAC, wybrany_idx, target;
	while(ile_losowac > 0 && ArraySize(players) > 0){
		wybrany_idx = random(ArraySize(players));
		target = ArrayGetCell(players, wybrany_idx);
		ArrayDeleteItem(players, wybrany_idx);
		przyznajVipa(target)
		ile_losowac--;
	}

	ArrayDestroy(players)
}

public przyznajVipa(id){
	new Name[33];
	get_user_name(id, Name, charsmax(Name))
	set_user_flags(id, FLAGA_VIP);
	ColorChat(0, TEAM_COLOR, "^x04%s^x01 Gratulacje dla gracza ^x03 %s, ktory uzyskal w wyniku losowania darmowego VIPA na tej mapie!", prefix, Name);
	set_hudmessage(255, 125, 0, -1.0, hudpos)
	show_hudmessage(0, "Gratulacje dla gracza %s, ktory uzyskal w wyniku losowania darmowego VIPA na tej mapie!", Name);
	hudpos += 0.05; // zeby sie nie nakladaly hudmessage
}