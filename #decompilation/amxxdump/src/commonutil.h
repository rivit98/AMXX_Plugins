#if !defined(COMMONUTIL_H)
#define COMMONUTIL_H

void GetAmxString(void *address, char *output, size_t size);
void dbg_LoadInfo(void *_amxdbg, void *dbg_addr);
unsigned int GetCodOffset();
unsigned int GetCodSize();
unsigned int GetDatOffset();
char *GetCodStart();
ucell ReadDatUCell(ucell offs);
void ReadDatString(ucell offs, char *output, size_t size);
int GetLikelyDatType(ucell offs);
int IsInDat(ucell offs);
unsigned int GetDatSize();
int GetNewVariableDeclarations(ucell oldaddr,ucell addr,char *output,size_t size,int iter);
const char *GetSymbolScope(int type);
#endif
