#if !defined(UTIL_H)
#define UTIL_H

#include "types.h"

typedef struct ProgramOptions_s
{
	int			 showmodules;
	int			 showsymbols;
	int			 showlines;
	int			 listfiles;
	int			 listfunctions;
	int			 hideaddresses;
	int			 listnatives;
	int			 labeljumps;
	int			 hidecomments;
	char		*lookupfunction;
	char		*filename;
	char		*referencefunction;
	char		*referencenative;
	int			 disassemblefull;
	char		*datavalue;
	char		*datavaluestring;
	char		*datavaluefloat;
	int			 showdata;
	int			 nativesyntax;
	int			 listglobals;
	int			 hideparams;
	char		*dumparray;
	int			 cleannatives;
} progopts_t;

extern progopts_t progopts;

typedef enum ErrorCodes_e
{
	ERR_NONE = 0,
	ERR_EOF,
	ERR_FILEOPEN,
	ERR_INVALID_FILE,
	ERR_ZLIB,
	ERR_UNKNOWN_MAGIC,
	ERR_OLD_AMXX_FILE,
	ERR_BAD_TYPE,
	
	ERR_END_DONT_USE
} errorcode;

extern const char *ErrorMessages[];

#if defined __cplusplus
#	define AMXXDUMP_DECL extern "C"
#else
#	define AMXXDUMP_DECL
#endif

extern errorcode Error;

AMXXDUMP_DECL errorcode read_dword	(FILE *fp,	dword *output);
AMXXDUMP_DECL errorcode read_qword	(FILE *fp,	qword *output);
AMXXDUMP_DECL errorcode read_word	(FILE *fp,	word  *output);
AMXXDUMP_DECL errorcode read_byte	(FILE *fp,	byte  *output);
AMXXDUMP_DECL void throw_generic_error(const char *extra_msg);

#define READ_DWORD(_MYFILE, __OUTPUT) if ((Error=read_dword(_MYFILE,__OUTPUT))!=ERR_NONE) return Error;
#define READ_QWORD(_MYFILE, __OUTPUT) if ((Error=read_qword(_MYFILE,__OUTPUT))!=ERR_NONE) return Error;
#define READ_WORD(_MYFILE, __OUTPUT)  if ((Error=read_word (_MYFILE,__OUTPUT))!=ERR_NONE) return Error;
#define READ_BYTE(_MYFILE, __OUTPUT)  if ((Error=read_byte (_MYFILE,__OUTPUT))!=ERR_NONE) return Error;

#endif
