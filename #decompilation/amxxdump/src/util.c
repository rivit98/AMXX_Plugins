#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"

errorcode Error;

const char *ErrorMessages[] = 
{
	"No error",
	"End of file",
	"Cannot open file for reading",
	"Invalid file",
	"Error uncompressing file.",
	"Unknown magic number.",
	"Pre-1.5 compiled AMX Mod X plugin.",
	"Bad header type",
	
};

errorcode read_qword(FILE *fp, qword *ret)
{
	if (feof(fp))
	{
		return ERR_EOF;
	}
	
	fread(ret,1,sizeof(qword),fp);
	
	return ERR_NONE;
}

errorcode read_dword(FILE *fp, dword *ret)
{
	if (feof(fp))
	{
		return ERR_EOF;
	}
	
	fread(ret,1,sizeof(dword),fp);
	
	return ERR_NONE;
}

errorcode read_word(FILE *fp, word *ret)
{
	if (feof(fp))
	{
		return ERR_EOF;
	}
	
	fread(ret,1,sizeof(word),fp);
	
	return ERR_NONE;
}

errorcode read_byte(FILE *fp, byte *ret)
{
	if (feof(fp))
	{
		return ERR_EOF;
	}
	
	fread(ret,1,sizeof(byte),fp);
	
	return ERR_NONE;
}

void throw_generic_error(const char *extra_msg)
{
	if (Error > ERR_NONE && Error < ERR_END_DONT_USE)
	{
		if (extra_msg!=NULL && *extra_msg!='\0')
		{
			fprintf(stderr,"Error: %s: %s\n",ErrorMessages[Error],extra_msg);
		}
		else
		{
			fprintf(stderr,"Error: %s\n",ErrorMessages[Error]);
		}
		fflush(stderr);
	}
}
