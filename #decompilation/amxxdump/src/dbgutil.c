#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>

#include "smheaders.h"
#include "amxxheaders.h"
#include "commonheaders.h"
#include "commonutil.h"
#include "dbgutil.h"
#include "util.h"
#include "parser.h"
#include "opcodes.h"

/**
 * Looks up a native index according to the name.  The index is the param after the SYSREQ.C
 *
 * @param name		Name of the native to search for.
 * @return			Index of the native, -1 on failure.
 */
int GetNativeIndexByName(const char *name)
{
	char			*data;		/**< Temporary pointer to our public function data. */
	unsigned int	 numfuncs;	/**< Total number of natives. */
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			/* Count of publicfuncs is nativesoffset-publicsoffset (so size of the publics portion) / defsize */
			numfuncs=(AMXXHDR.libraries-AMXXHDR.natives) / AMXXHDR.defsize;

			while (numfuncs--)
			{
				data=header.data + (unsigned int)AMXXHDR.natives + (unsigned int)(AMXXHDR.defsize * numfuncs);
				data=header.data + (unsigned int)(((AMX_FUNCSTUBNT*)data)->nameofs);
				
				if (strcmp(name,data)==0)
				{
					return numfuncs;
				}
			}

			return -1;
		}
		case FT_SOURCEMOD:
		{
			numfuncs=SMHDR.info.natives_num;
			while (numfuncs--)
			{
				if (strcmp(name,SMHDR.info.stringbase + SMHDR.info.natives[numfuncs].name)==0)
				{
					return numfuncs;
				}
			}

			return -1;
		}
	}
	
	return -1;
}
/**
 * Looks up a native according to the index (param after SYSREQ.C).
 *
 * @param index		Index to lookup.
 * @param output	Name of the native.
 * @param size		Size of the buffer for the name.
 */
void GetNativeNameByIndex(int index, char *output, size_t size)
{
	char			*data;		/**< Temporary pointer to our public function data. */
	unsigned int	 numfuncs;	/**< Total number of natives. */

	switch(header.type)
	{
		case FT_AMXX:
		{
			
			/* Count of publicfuncs is nativesoffset-publicsoffset (so size of the publics portion) / defsize */
			numfuncs=(AMXXHDR.libraries-AMXXHDR.natives) / AMXXHDR.defsize;
			
			if (index>=0 && index<=numfuncs)
			{
				data=header.data + (unsigned int)AMXXHDR.natives + (unsigned int)(AMXXHDR.defsize * index);
				data=header.data + (unsigned int)(((AMX_FUNCSTUBNT*)data)->nameofs);
				
				strncpy(output,data,size);
			}
			
			break;
		}
		case FT_SOURCEMOD:
		{
			if (index>=0 && index<=SMHDR.info.natives_num)
			{
				strncpy(output,SMHDR.info.stringbase + SMHDR.info.natives[index].name,size);
			}
			
			break;

		}
	}
}
/**
 * Formats a full function heading.
 *
 * @param index		Index of the function symbol.
 * @param output	Output buffer.  Needs to be big enough to hold the full function.
 * @param size		Size of the buffer.
 */
void GetFullFunctionHeader(int index, char *output, size_t size)
{
	int 			 count=0;			/**< The number of symbols that are scoped in this function. */
	int	 			 i=0;				/**< symboltbl iterator. */
	int 			 symbollist[256];	/**< list of symbol indexes that are scoped in this function. -1 = terminator */
	ucell			 codestart;			/**< start of this function scope. */
	ucell			 codeend;			/**< end of this function scope. */
	AMX_DBG_SYMBOL	*sym;				/**< pointer to the symbol that's being examined. */
	int				 offset;			/**< to display which offset to be looking for now. */
	char			 varname[256];		/**< temporary buffer for the variable names. */
	
	
	*output='\0';

	switch(header.type)
	{
		case FT_AMXX:
		{
			memset(symbollist,0xFF,sizeof(symbollist));
			
			*output='\0';
			
			if (IsFunctionPublic(AMXXDBG.symboltbl[index]->address))
			{
				strncat(output,"public ",size);
			}
			else
			{
				strncat(output,"stock ",size);
			}
			
			if (AMXXDBG.symboltbl[index]->tag!=0)
			{
				GetTagName(AMXXDBG.symboltbl[index]->tag,varname,sizeof(varname)-1);
				strncat(output,varname,size);
				strncat(output,":",size);
			}

			strncat(output,AMXXDBG.symboltbl[index]->name,size);
			
			strncat(output,"(",size);
			
			codestart=AMXXDBG.symboltbl[index]->codestart;
			codeend=AMXXDBG.symboltbl[index]->codeend;
			
			/* Get how many symbols are valid in this function. */
			i=0;
			
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->codestart == codestart && AMXXDBG.symboltbl[i]->codeend == codeend)
				{
					/* This symbol is in the scope.  Make sure it's not the function itself. */
					if (i!=index)
					{
						symbollist[count++]=i;
					}
				}
				++i;
			}
			/* For some reason the parameters passed start at 0xC.. (I thought it was SIZE,PARAM1,PARAM2,PARAM3...), apparently there's 8 bytes I'm missing. */
			
			i=0;
			
			offset=0xC;
			while (i<count)
			{
				sym=AMXXDBG.symboltbl[symbollist[i]];
				
				/* Don't look at symbols in the heap. */
				if (!(sym->address & (1<<31)))
				{
					if (sym->address==offset)
					{
						if (offset!=0xC)
						{
							strncat(output,",",size);
						}
						GetFullVariableName(symbollist[i],varname,sizeof(varname)-1);
						strncat(output,varname,size);
						
						offset+=0x4;
						i=0;
						continue;
					}
				}
				
				++i;
			}
			
			
			
			strncat(output,")",size);
			
			break;
		}
	}
}

/**
 * Returns the function's symboltbl index according to it's address.
 *
 * @param addr		The address to poll.  This can be anywhere within a function's scope.
 * @return			symboltbl index of the function.  -1 on failure.
 */
int GetFunctionIndexByAddress(ucell addr)
{
	int i=0;
	

	switch (header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident==iFUNCTN)
				{
					if (AMXXDBG.symboltbl[i]->codestart <=addr && AMXXDBG.symboltbl[i]->codeend > addr)
					{
						return i;
					}
				}
				++i;
			}
			
			return -1;
		}
		case FT_SOURCEMOD:
		{
			/* TODO: This */
		}
	}
	return -1;
}




/**
 * Looks up the full variable name, including tag and dimensions, according to it's address.  It must be an exact address; not a scope.
 *
 * @param addr		Exact address of the variable.
 * @param output	Output buffer.
 * @param size		Size of the output buffer.
 */
void GetVariableNameByAddress(ucell addr, char *output, size_t size)
{
	int i=0;
	
	*output='\0';

	switch(header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident != iFUNCTN)
				{
					if (AMXXDBG.symboltbl[i]->address == addr)
					{
						GetFullVariableName(i,output,size);
						
						return;
					}
				}
				++i;
				
			}
			
			break;
		}
	}

}
void GetShortVariableNameByAddress(ucell addr, char *output, size_t size)
{
	int i=0;
	
	*output='\0';

	switch(header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident != iFUNCTN)
				{
					if (AMXXDBG.symboltbl[i]->address == addr)
					{
						strncpy(output,AMXXDBG.symboltbl[i]->name,size);
						
						return;
					}
				}
				++i;
				
			}
			
			break;
		}
	}

}
/**
 * Gets the file:line comment for a specific address.
 *
 * @param addr		The address to look up.
 * @param output	The output buffer.
 * @param size		The size of the output buffer.
 */
void GetLineComment(ucell addr, char *output, size_t size)
{
	int i=0;
	int line=0;
	
	*output='\0';

	switch(header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->lines)
			{
				if (AMXXDBG.linetbl[i].address>=addr)
				{
					line=AMXXDBG.linetbl[i].line;
					break;
				}
				++i;
			}
			i=0;
			while (i<AMXXDBG.hdr->files)
			{
				if (AMXXDBG.filetbl[i]->address>addr)
				{
					break;
				}
				++i;
			}
			if (i>=AMXXDBG.hdr->files)
			{
				i=AMXXDBG.hdr->files - 1;
			}
			snprintf(output,size,"%s:%d",AMXXDBG.filetbl[i]->name != NULL ? AMXXDBG.filetbl[i]->name : "",line);
			break;
		}
		
		case FT_SOURCEMOD:
		{
			i=0;
			while (i < SMHDR.debug.lines_num)
			{
				if (SMHDR.debug.lines[i].addr>=addr)
				{
					line=SMHDR.debug.lines[i].line;
					break;
				}
				++i;
			}
			i=0;
			while (i < SMHDR.debug.files_num)
			{
				if (SMHDR.debug.files[i].addr>addr)
				{
					i--;
					break;
				}
				++i;
			}
			if (i>=SMHDR.debug.files_num)
			{
				i=SMHDR.debug.files_num-1;
			}
			snprintf(output,size,"%s:%d",SMHDR.debug.stringbase + SMHDR.debug.files[i].name,line);
			break;
		}
	}
}
/**
 * Scans for the variable name of a variable at a specific frame offset of a specific address scope.
 *
 * @param addr		The address to check scope of.
 * @param offset	Offset from the frame pointer.
 * @param output	Output buffer.
 * @param size		Size of the output buffer.
 */
void GetVariableNameByFrameOffset(ucell addr, ucell offset, char *output, size_t size)
{
	int i=0;
	
	*output='\0';
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident != iFUNCTN)
				{
					if (AMXXDBG.symboltbl[i]->codestart <=addr && AMXXDBG.symboltbl[i]->codeend > addr)
					{
						/* This symbol is in the scope.  Check offset vs address. */
						if (AMXXDBG.symboltbl[i]->address == offset)
						{
							GetFullVariableName(i,output,size);
							
							return;
						}
					}
				}
				++i;
			}
		}
	}

}
void GetShortVariableNameByFrameOffset(ucell addr, ucell offset, char *output, size_t size)
{
	int i=0;
	
	*output='\0';
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident != iFUNCTN)
				{
					if (AMXXDBG.symboltbl[i]->codestart <=addr && AMXXDBG.symboltbl[i]->codeend > addr)
					{
						/* This symbol is in the scope.  Check offset vs address. */
						if (AMXXDBG.symboltbl[i]->address == offset)
						{
							strncpy(output,AMXXDBG.symboltbl[i]->name,size);
							
							return;
						}
					}
				}
				++i;
			}
		}
	}

}
/**
 * Scans for the variable name of a variable at a specific frame offset of a specific address scope.
 *
 * @param addr		The address to check scope of.
 * @param offset	Offset from the frame pointer.
 * @param output	Output buffer.
 * @param size		Size of the output buffer.
 */
void GetAllVariablesInFrameOffset(ucell addr, ucell offset, ucell offsize, char *output, size_t size)
{
	int i=0;
	char buff[1024];
	int count=0;
	
	*output='\0';
	
	offsize--;
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident != iFUNCTN)
				{
					if (AMXXDBG.symboltbl[i]->codestart <=addr && AMXXDBG.symboltbl[i]->codeend > addr)
					{
						/* This symbol is in the scope.  Check offset vs address. */
						if (AMXXDBG.symboltbl[i]->address >= offset && (unsigned)AMXXDBG.symboltbl[i]->address <= (unsigned)offset+offsize)
						{
							GetFullVariableName(i,buff,sizeof(buff)-1);
							if (count==0)
							{
								strncat(output,"new ",size);
							}
							else
							{
								strncat(output,", ",size);
							}
							strncat(output,buff,size);
							count++;
							
							
						}
					}
				}
				++i;
			}
			break;
		}
	}
	fflush(stdout);

}
/**
 * Looks up a function (case sensitive), returns the exact address of it, and byrefs the scope.
 *
 * @param name		The name to search for.
 * @param codestart	The start of the scope, byref
 * @param codeend	The end of the scope, byref.
 * @return			The address of the beginning of the function.
 */
ucell LookupFunctionByName(const char *name, ucell *codestart, ucell *codeend)
{
	int i=0;
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident==iFUNCTN)
				{
					if (strcmp(name,AMXXDBG.symboltbl[i]->name)==0)
					{
						*codestart=AMXXDBG.symboltbl[i]->codestart;
						*codeend=AMXXDBG.symboltbl[i]->codeend;
						return AMXXDBG.symboltbl[i]->address;
					}
				}
				++i;
			}
			
			break;
		}
	}
	return 0xFFFFFFFF;

}

/**
 * Copies the tag name of the symbol to the output buffer.
 *
 * @param index		Symbol index.
 * @param output	Output buffer.
 * @param size		Size of the buffer.
 */
void GetTagName(int index, char *output, size_t size)
{
	int			 count=0;

	*output='\0';

	switch(header.type)
	{
		case FT_AMXX:
		{
			count=(int)AMXXDBG.hdr->tags;
			while (count--)
			{
				if (AMXXDBG.tagtbl[count]->tag==index)
				{
					strncpy(output,AMXXDBG.tagtbl[count]->name,size);
					return;
				}
			}
		}
	}

}
/**
 * Gets the symbol dimension value.  Addr must be the address of a symbol that is an array/refarray.
 * This function copies the entire symbol dimensions to an output buffer.
 *
 * @param index		Index of this symbol in the symboltbl.
 * @param output	Pointer to a string for output.  Size needs to be big enough to hold it all (128 chars should be more than enough)
 * @param size		Size of the output buffer.
 */
void GetFullSymbolDim(int index, char *output, size_t size)
{
	char		*data=NULL;			/**< Temporary pointer to scan past the name. */
	int			 count=0;			/**< How many dimensions this symbol has. */
	char		 tempbuffer[64];	/**< Temporary buffer for strcating the output with. */
	
	*output='\0';
	switch(header.type)
	{
		case FT_AMXX:
		{
			if (AMXXDBG.symboltbl[index]->ident==iARRAY || AMXXDBG.symboltbl[index]->ident==iREFARRAY)
			{
				/* This is a match.  Scan past the name to the SYMDIM object. */
				data=(char *)AMXXDBG.symboltbl[index]->name;
				
				while (*data++!='\0') /*do nothing*/;
			
				/* Mark down number of dimensions. */
				count=AMXXDBG.symboltbl[index]->dim;
				
				while (count--)
				{
					snprintf(tempbuffer,sizeof(tempbuffer)-1,"[%u]",((AMX_DBG_SYMDIM *)data)->size);
					
					strncat(output,tempbuffer,size);
					
					/* Go to the next dimension. */
					data+=sizeof(AMX_DBG_SYMDIM);
				}
			}
			break;
		}
	}
}

/**
 * Gets symbol scope by symbol index.
 *
 * @param index		The symtbl index of the symbol.
 * @return			1 on local, 0 on global
 */
int GetSymbolScopeByIndex(int index)
{
	switch(header.type)
	{
		case FT_AMXX:
		{
			/*if (AMXXDBG.symboltbl[index]->vclass == 0) *//* global */
			return AMXXDBG.symboltbl[index]->vclass == 1 ? 1 : 0;
		}
	}
	
	return 0;

}

void GetFullVariableName(int index, char *output, size_t size)
{
	char		*data=NULL;			/**< Temporary pointer to scan past the name. */
	int			 count=0;			/**< How many dimensions this symbol has. */
	char		 tempbuffer[64];	/**< Temporary buffer for strcating the output with. */
	
	memset(tempbuffer,0x0,sizeof(tempbuffer));

	*output='\0';
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			if (AMXXDBG.symboltbl[index]->tag!=0)
			{
				GetTagName(AMXXDBG.symboltbl[index]->tag,tempbuffer,sizeof(tempbuffer)-1);
				strncat(output,tempbuffer,size);
				strncat(output,":",size);
			}
			strncat(output,AMXXDBG.symboltbl[index]->name,size);
			if (AMXXDBG.symboltbl[index]->ident==iARRAY || AMXXDBG.symboltbl[index]->ident==iREFARRAY)
			{
				/* This is a match.  Scan past the name to the SYMDIM object. */
				data=(char *)AMXXDBG.symboltbl[index]->name;
				
				while (*data++!='\0') /*do nothing*/;
			
				/* Mark down number of dimensions. */
				count=AMXXDBG.symboltbl[index]->dim;
				
				while (count--)
				{
					if (((AMX_DBG_SYMDIM *)data)->size==0)
					{
						snprintf(tempbuffer,sizeof(tempbuffer)-1,"[]");
					}
					else
					{
						snprintf(tempbuffer,sizeof(tempbuffer)-1,"[%u]",((AMX_DBG_SYMDIM *)data)->size);
					}
					strncat(output,tempbuffer,size);
					
					/* Go to the next dimension. */
					data+=sizeof(AMX_DBG_SYMDIM);
				}
			}
			
			break;
		}
	}
}
/**
 * Tells if this function is a public function or not.
 *
 * @param addr		The address of the start of the function.
 * @return			1 if this function is public, 0 otherwise.
 */
int IsFunctionPublic(ucell addr)
{
	char			*data;		/**< Temporary pointer to our public function data. */
	unsigned int	 numfuncs;	/**< Total number of public functions. */
	

	switch(header.type)
	{
		case FT_AMXX:
		{
			/* Count of publicfuncs is nativesoffset-publicsoffset (so size of the publics portion) / defsize */
			numfuncs=(AMXXHDR.natives-AMXXHDR.publics) / AMXXHDR.defsize;
			
			while (numfuncs--)
			{
				/* Find the nametable of this public function, located at base + header.publics + (header.defsize * numfuncs) */
				data=header.data + (unsigned int)AMXXHDR.publics + (unsigned int)(AMXXHDR.defsize * numfuncs);
				
				/* Compare addresses. */
				if ((unsigned int)addr == (unsigned int)(((AMX_FUNCSTUBNT*)data)->address))
				{
					return 1; /* Match. */
				}
			}

			return 0;
		}
	}
	
	return 0;
}
/**
 * Tells if this variable is a public variable or not.
 *
 * @param addr		The address of the variable.
 * @return			1 if this variable is public, 0 otherwise.
 */
int IsVariablePublic(ucell addr)
{
	char			*data;		/**< Temporary pointer to our public variable data. */
	unsigned int	 numfuncs;	/**< Total number of public variables. */
	

	switch(header.type)
	{
		case FT_AMXX:
		{
			/* Count of publicfuncs is nativesoffset-publicsoffset (so size of the publics portion) / defsize */
			numfuncs=(AMXXHDR.tags-AMXXHDR.pubvars) / AMXXHDR.defsize;
			
			while (numfuncs--)
			{
				/* Find the nametable of this public function, located at base + header.publics + (header.defsize * numfuncs) */
				data=header.data + (unsigned int)AMXXHDR.pubvars + (unsigned int)(AMXXHDR.defsize * numfuncs);
				
				/* Compare addresses. */
				if ((unsigned int)addr == (unsigned int)(((AMX_FUNCSTUBNT*)data)->address))
				{
					return 1; /* Match. */
				}
			}

			return 0;
		}
	}
	
	return 0;
}

ucell LookupVariableAddressByName(const char *name)
{
	int		i=0;
	switch (header.type)
	{
		case FT_AMXX:
		{
			while (i<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[i]->ident!=iFUNCTN)
				{
					if (strcmp(name,AMXXDBG.symboltbl[i]->name)==0)
					{
						return AMXXDBG.symboltbl[i]->address;
					}
				}
				i++;
			}
			return 0;
		}
	}
	return 0;
}


