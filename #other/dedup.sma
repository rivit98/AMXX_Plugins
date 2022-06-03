#include <amxmodx>

print_arr(const arr[], arr_size){
	static buf[512];
	for(new i = 0; i < arr_size; i++){
		add(buf, charsmax(buf), fmt("%d, ", arr[i]))
	}
	log_amx(buf);
}

public plugin_init() {
	#define MAX_NUM 0x20
	new arr[MAX_NUM] = {2,4,1,2,1,1,1,1,1,5,6,7,2,2,1,3,2,5,8,6,4,8,3,2,6,3,2,1};
	new Trie:set = TrieCreate();
	new v;
	for(new i=0; i < sizeof(arr); i++){
		v = arr[i];
		TrieSetCell(set, fmt("%d", v), v);
	}

	new deduped[MAX_NUM];
	new TrieIter:iter = TrieIterCreate(set);
	new elements_num = TrieIterGetSize(iter);
	new idx=0;
	while(!TrieIterEnded(iter)){
		TrieIterGetCell(iter, v);
		deduped[idx++] = v;
		TrieIterNext(iter);
	}

	print_arr(deduped, elements_num);
	TrieIterDestroy(iter);
	TrieDestroy(set);
}
