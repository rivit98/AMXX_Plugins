#include amxmodx
#include csx
 
public plugin_init()
{
	register_plugin("Prefixai", "1.0", "RiviT")
 
	register_message(get_user_msgid("SayText"), "handleSayText");
}
 
public handleSayText(msgId,msgDest,msgEnt){	
 
    new id = get_msg_arg_int(1);
    
    if(!is_user_connected(id)) return PLUGIN_CONTINUE;
    
    new szTmp[192], szTmp2[192], izStats[8], izBody[8], iRankPos, szPrefix[64], szPlayerName[64];
	iRankPos = get_user_stats(id, izStats, izBody);
    get_msg_arg_string(2, szTmp, charsmax(szTmp));
    szPrefix[0] = '^4';
 
    if(iRankPos <= 15){
    	format(szPrefix, 63, "%s[TOP%i]", szPrefix, iRankPos);
    }

    if(get_user_flags(id) & ADMIN_LEVEL_G){
    	format(szPrefix, 63, "%s[SVIP]", szPrefix);
    }
    
    if(strlen(szPrefix) < 2) return 0;
    
    if(!equal(szTmp,"#Cstrike_Chat_All")){
        add(szTmp2, charsmax(szTmp2), "^x01");
        add(szTmp2, charsmax(szTmp2), szPrefix);
        add(szTmp2, charsmax(szTmp2), " ");
        add(szTmp2, charsmax(szTmp2), szTmp);
    }
    else{
        get_user_name(id, szPlayerName, charsmax(szPlayerName));
        
        get_msg_arg_string(4, szTmp, charsmax(szTmp)); //4. argument zawiera treść wysłanej wiadomości
        set_msg_arg_string(4, ""); //Musimy go wyzerować, gdyż gra wykorzysta wiadomość podwójnie co może skutkować crash'em 191+ znaków.
    
        add(szTmp2, charsmax(szTmp2), "^x01");
        add(szTmp2, charsmax(szTmp2), szPrefix);
        add(szTmp2, charsmax(szTmp2), "^x03 ");
        add(szTmp2, charsmax(szTmp2), szPlayerName);
        add(szTmp2, charsmax(szTmp2), "^x01 :  ");
        add(szTmp2, charsmax(szTmp2), szTmp)
    }
    
    set_msg_arg_string(2, szTmp2);
    
    return PLUGIN_CONTINUE;
}