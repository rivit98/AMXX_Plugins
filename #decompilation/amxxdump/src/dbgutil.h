#if !defined(DBGUTIL_H)
#define DBGUTIL_H




void GetFullFunctionHeader(int index, char *output, size_t size);
int GetFunctionIndexByAddress(ucell addr);
int GetNativeIndexByName(const char *name);
void GetNativeNameByIndex(int index, char *output, size_t size);
void GetVariableNameByAddress(ucell addr, char *output, size_t size);
void GetShortVariableNameByAddress(ucell addr, char *output, size_t size);
void GetVariableNameByFrameOffset(ucell addr, ucell offset, char *output, size_t size);
void GetShortVariableNameByFrameOffset(ucell addr, ucell offset, char *output, size_t size);
void GetAllVariablesInFrameOffset(ucell addr, ucell offset, ucell offsize, char *output, size_t size);
ucell LookupFunctionByName(const char *name, ucell *codestart, ucell *codeend);
void GetTagName(int index, char *output, size_t size);
void GetFullSymbolDim(int index, char *output, size_t size);
int GetSymbolScopeByIndex(int index);
void GetFullVariableName(int index, char *output, size_t size);
int IsFunctionPublic(ucell addr);
int IsVariablePublic(ucell addr);
void GetLineComment(ucell addr, char *output, size_t size);
ucell LookupVariableAddressByName(const char *name);
#endif
