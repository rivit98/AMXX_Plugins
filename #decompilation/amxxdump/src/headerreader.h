#if !defined(HEADERREADER_H)
#define HEADERREADER_H

#include "list.h"
#include "stack.h"

#define PARAM_BYVAL		0
#define PARAM_BYREF		1
#define PARAM_VARARG	2

#define PARAM_UNKNOWN	0	/* Treat it as an integer */
#define PARAM_INT		1
#define PARAM_FLOAT		2

typedef struct parameter_s
{
	int			 tag;
	int			 type;
	int			 dimensions;
	int			 dimsizes[3];
	char		 name[64];
} parameter_t;

typedef struct native_s
{
	int			 tag;
	int			 vararg;
	int			 paramcount;
	stack_t		*params;
	char		 name[64];
	
} native_t;

extern list_t		*natives;

void LoadAMXXIncludes(char *path);
native_t *HEADER_FindNativeByName(const char *name);

#endif
