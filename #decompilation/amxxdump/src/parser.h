#if !defined(PARSER_H)
#define PARSER_H

#include "util.h"

AMXXDUMP_DECL void PARSER_ListModules(void);
AMXXDUMP_DECL void PARSER_ListFunctions(void);
AMXXDUMP_DECL void PARSER_ListNatives(void);
AMXXDUMP_DECL void PARSER_ListAllSymbols(void);
AMXXDUMP_DECL void PARSER_ListFiles(void);
void PARSER_ListGlobalVariables(void);

#endif

