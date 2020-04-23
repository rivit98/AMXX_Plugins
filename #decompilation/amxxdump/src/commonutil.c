#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <ctype.h>

#include "smheaders.h"
#include "amxxheaders.h"
#include "commonheaders.h"
#include "commonutil.h"
#include "dbgutil.h"
#include "util.h"
#include "parser.h"
#include "opcodes.h"

static void memread(void *dest, char **src, size_t size);
static const char *ClipFileName(const char *inp);

static void memread(void *dest, char **src, size_t size) 
{
	void *ptr = *src;
	memcpy(dest, ptr, size);
	*src += size;
}

static const char *ClipFileName(const char *inp)
{
	static char buffer[256];
	size_t len = strlen(inp);
	const char *ptr = inp;
	size_t i;

	for (i=0; i<len; i++)
	{
		if ((inp[i] == '\\' || inp[i] == '/') && (i != len-1))
			ptr = inp + i + 1;
	}
	strcpy(buffer, ptr);

	return buffer;
}

void GetAmxString(void *address, char *output, size_t size)
{
	cell		*addr=(cell *)address;
	char		*szaddr=(char *)address;
	size_t		 count=size;
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			while (count-- && *addr)
			{
				*output++=(char)*addr++;
			}
			if (count)
			{
				*output='\0';
			}
			else
			{
				--output;
				*output='\0';
			}
			break;
		}
		case FT_SOURCEMOD:
		{
			strncpy(output,(char *)address,size);
			szaddr[size-1]='\0';
			break;
		}
	}
}

void dbg_LoadInfo(void *_amxdbg, void *dbg_addr)
{
	switch (header.type)
	{
		case FT_AMXX:
		{
			AMX_DBG *amxdbg=(AMX_DBG *)_amxdbg;
			AMX_DBG_HDR dbghdr;
			unsigned char *ptr;
			int index, dim;
			AMX_DBG_SYMDIM *symdim;


			char *addr = (char *)(dbg_addr);

			memset(&dbghdr, 0, sizeof(AMX_DBG_HDR));
			memread(&dbghdr, &addr, sizeof(AMX_DBG_HDR));

			if (dbghdr.magic != AMX_DBG_MAGIC)
			{
				printf("%x vs %x\n", dbghdr.magic, AMX_DBG_MAGIC);
				printf("dbg header mismatch\n");
				return;
			}

			/* allocate all memory */
			memset(amxdbg, 0, sizeof(AMX_DBG));
			amxdbg->hdr = (AMX_DBG_HDR *)malloc((size_t)dbghdr.size);
			if (dbghdr.files > 0)
				amxdbg->filetbl = (AMX_DBG_FILE **)malloc(dbghdr.files * sizeof(AMX_DBG_FILE *));
			if (dbghdr.symbols > 0)
				amxdbg->symboltbl = (AMX_DBG_SYMBOL **)malloc(dbghdr.symbols * sizeof(AMX_DBG_SYMBOL *));
			if (dbghdr.tags > 0)
				amxdbg->tagtbl = (AMX_DBG_TAG **)malloc(dbghdr.tags * sizeof(AMX_DBG_TAG *));
			if (dbghdr.automatons > 0)
				amxdbg->automatontbl = (AMX_DBG_MACHINE **)malloc(dbghdr.automatons * sizeof(AMX_DBG_MACHINE *));
			if (dbghdr.states > 0)
				amxdbg->statetbl = (AMX_DBG_STATE **)malloc(dbghdr.states * sizeof(AMX_DBG_STATE *));

			/* load the entire symbolic information block into memory */
			memcpy(amxdbg->hdr, &dbghdr, sizeof dbghdr);
			ptr = (unsigned char *)(amxdbg->hdr + 1);
			memread(ptr, &addr, (size_t)(dbghdr.size-sizeof(dbghdr)));

			/* file table */
			for (index = 0; index < dbghdr.files; index++) {
				amxdbg->filetbl[index] = (AMX_DBG_FILE *)ptr;
				for (ptr = ptr + sizeof(AMX_DBG_FILE); *ptr != '\0'; ptr++)
					/* nothing */;
				ptr++;							/* skip '\0' too */
			} /* for */

			for (index=0;index<amxdbg->hdr->files; index++)
			{
				strcpy((char *)amxdbg->filetbl[index]->name, ClipFileName(amxdbg->filetbl[index]->name));
			}

			/* line table */
			amxdbg->linetbl = (AMX_DBG_LINE*)ptr;
			ptr += dbghdr.lines * sizeof(AMX_DBG_LINE);

			/* symbol table (plus index tags) */
			for (index = 0; index < dbghdr.symbols; index++) {
				amxdbg->symboltbl[index] = (AMX_DBG_SYMBOL *)ptr;
				for (ptr = ptr + sizeof(AMX_DBG_SYMBOL); *ptr != '\0'; ptr++)
					/* nothing */;
				ptr++;							/* skip '\0' too */
				for (dim = 0; dim < amxdbg->symboltbl[index]->dim; dim++) {
					symdim = (AMX_DBG_SYMDIM *)ptr;
					ptr += sizeof(AMX_DBG_SYMDIM);
				} /* for */
			} /* for */

			/* tag name table */
			for (index = 0; index < dbghdr.tags; index++) {
				amxdbg->tagtbl[index] = (AMX_DBG_TAG *)ptr;
				for (ptr = ptr + sizeof(AMX_DBG_TAG) - 1; *ptr != '\0'; ptr++)
					/* nothing */;
				ptr++;							/* skip '\0' too */
			} /* for */

			/* automaton name table */
			for (index = 0; index < dbghdr.automatons; index++) {
				amxdbg->automatontbl[index] = (AMX_DBG_MACHINE *)ptr;
				for (ptr = ptr + sizeof(AMX_DBG_MACHINE) - 1; *ptr != '\0'; ptr++)
					/* nothing */;
				ptr++;							/* skip '\0' too */
			} /* for */

			/* state name table */
			for (index = 0; index < dbghdr.states; index++) {
				amxdbg->statetbl[index] = (AMX_DBG_STATE *)ptr;
				for (ptr = ptr + sizeof(AMX_DBG_STATE) - 1; *ptr != '\0'; ptr++)
					/* nothing */;
				ptr++;							/* skip '\0' too */
			} /* for */
			
			break;
		}
		case FT_SOURCEMOD:
		{
			break;
		}
	}
}
unsigned int GetCodOffset()
{
	switch(header.type)
	{
		case FT_AMXX:
		{
			return AMXXHDR.cod;
		}
	}
	
	return 0;
}
unsigned int GetCodSize()
{
	switch(header.type)
	{
		case FT_AMXX:
		{
			return AMXXHDR.dat - AMXXHDR.cod;
		}
		case FT_SOURCEMOD:
		{
			return SMHDR.pcode_size;
		}
	}
	
	return 0;
}

unsigned int GetDatOffset()
{
	switch(header.type)
	{
		case FT_AMXX:
		{
			return AMXXHDR.dat;
		}
	}
	
	return 0;
}
unsigned int GetDatSize()
{
	switch(header.type)
	{
		case FT_AMXX:
		{
			return AMXXHDR.hea-AMXXHDR.dat;
		}
	}
	
	return 0;
}
int IsInDat(ucell offs)
{
	if (offs >= 0 && offs <= GetDatSize())
	{
		return 1;
	}
	return 0;
}
int GetLikelyDatType(ucell offs)
{
	ucell 		*dat;
	ucell		 value;
	switch(header.type)
	{
		case FT_AMXX:
		{
			
			dat=(ucell *)((header.data + AMXXHDR.dat + offs));
			value=*dat;
			if  (value > 0 && value < 255 && 
				(isalnum(value) || isspace(value) || ispunct(value)))
			{
				/* Scan the next cell */
				dat++;
				value=*dat;
				
				if  (value > 0 && value < 255 && 
					(isalnum(value) || isspace(value) || ispunct(value)))
				{
					return 1;
				}
			}
			return 0;
		}
	}
	
	return 0;
}
void ReadDatString(ucell offs, char *output, size_t size)
{
	char			 buffer[4096];
	int				 i=0;
	char			*out;
	char			 temp[10];
	int				 j;
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			buffer[i++]='\"';
			
			out=output;
			GetAmxString(header.data + AMXXHDR.dat + offs,output,size);
			
			while (*output!='\0')
			{
				if (*output=='\n')
				{
					buffer[i++]='^';
					buffer[i++]='n';
				}
				else if (*output=='\t')
				{
					buffer[i++]='^';
					buffer[i++]='t';
				}
				else if (*output=='"')
				{
					buffer[i++]='^';
					buffer[i++]='"';
				}
				else if (*output > 0 && *output < 32)
				{
					buffer[i++]='^';
					buffer[i++]='x';
					snprintf(temp,9,"%02x",(int)*output);
					j=0;
					while (temp[j]!='\0')
					{
						buffer[i++]=temp[j++];
					}
					
				}
				else
				{
					buffer[i++]=*output;
				}
				
				++output;
			}
			buffer[i++]='\"';
			buffer[i++]=0;
			
			strncpy(out,buffer,size);
			return;
		}
	}
}
ucell ReadDatUCell(ucell offs)
{
	ucell		*dat;
	switch(header.type)
	{
		case FT_AMXX:
		{
			dat=(ucell *)((header.data + AMXXHDR.dat + offs));
			
			return *dat;
		}
	}
	
	return 0;
}
char *GetCodStart()
{
	switch(header.type)
	{
		case FT_AMXX:
		{
			return ((char *)header.data) + AMXXHDR.cod;
		}
		case FT_SOURCEMOD:
		{
			return (char *)SMHDR.pcode;
		}
	}
	
	return NULL;
}
int GetNewVariableDeclarations(ucell oldaddr,ucell addr,char *output,size_t size,int iter)
{
	int 			 max;
	AMX_DBG_SYMBOL	*sym;
	char			 buffer[1024];
	
	*output=0;
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			max=AMXXDBG.hdr->symbols-1;
			while (iter<max)
			{
				sym=AMXXDBG.symboltbl[iter];
				if (sym->ident!=iFUNCTN)
				{
					if (sym->codestart > oldaddr &&
						sym->codestart <= addr)
					{
						buffer[0]=0;
						if (sym->vclass==0) /* global variable */
						{
							strncat(output,"new ",size);
						}
						else if (sym->vclass==2) /* static */
						{
							strncat(output,"static ",size);
						}
						else
						{
							strncat(output,"new ",size);
						}
						/* Get the variable name */
						if (sym->vclass==1 /*local*/)
						{
							GetFullVariableName(iter,buffer,sizeof(buffer)-1);
						}
						else
						{
							GetFullVariableName(iter,buffer,sizeof(buffer)-1);
						}
						strncat(output,buffer,size);
						
						return ++iter;
					}
				}
				iter++;
			}
			
			return 0;
		}
	}
	
	return 0;
}
const char *GetSymbolScope(int type)
{
	switch(type)
	{
		case 0:
			return "global";
		case 1:
			return "local";
		case 2:
			return "static";
	}
	
	return "unknown";
}
