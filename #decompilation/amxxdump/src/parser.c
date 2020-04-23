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

void PARSER_ListFiles(void)
{
	unsigned int	 index=0;

	switch(header.type)
	{
		case FT_AMXX:
		{
			while (index < AMXXDBG.hdr->files) 
			{
				printf("file: %s\n",AMXXDBG.filetbl[index]->name);
				++index;
			}
			
			break;
		}
		case FT_SOURCEMOD:
		{
			while (index < SMHDR.debug.files_num)
			{
				printf("file: %s\n",SMHDR.debug.stringbase + SMHDR.debug.files[index].name);
				//printf("%s %d\n",SMHDR.debug.stringbase,SMHDR.debug.files[index].addr);
				
				++index;
			}
		}
	}

}
void PARSER_ListModules(void)
{
	char			*data;
	unsigned int	 numtags;
	unsigned int	 modulecount=0;
	char			 forcedloaded[2048];
	char			 expectedlib[2048];
	char			 expectedclass[2048];
	char			 defaultlib[2048];
	char			 requiredlib[2048];
	char			 requiredclass[2048];
	
	data=header.data;

	forcedloaded[0]='\0';
	expectedlib[0]='\0';
	expectedclass[0]='\0';
	defaultlib[0]='\0';
	requiredlib[0]='\0';
	requiredclass[0]='\0';
	switch(header.type)
	{
		case FT_AMXX:
		{
			/* Count of tags is nametableoffset-tagsoffset (so size of the tags portion) / defsize */
			numtags=(AMXXHDR.nametable-AMXXHDR.tags) / AMXXHDR.defsize;
			
			#define ADDTO(WHAT) if (WHAT [0] !='\0') { strncat(WHAT,", ",sizeof( WHAT )-1); } strncat(WHAT,data,sizeof( WHAT )-1); continue
			while (numtags--)
			{
				data=header.data + (unsigned int)AMXXHDR.tags + (unsigned int)(AMXXHDR.defsize * numtags);
				
				data=header.data + (unsigned int)(((AMX_FUNCSTUBNT*)data)->nameofs);
				
				if (*data=='?')
				{
					data++;
					
					if (*data=='f' && *(data+1)=='_') /* Forced module load */
					{
						data+=2; /* Move past the f and the underscore */
						ADDTO(forcedloaded);
					}
					else if (*data=='r') /* require */
					{
						data++;
						if (*data=='c') /*class*/
						{
							data+=2;
							ADDTO(requiredclass);
						}
						else if (*data=='l') /*library*/
						{
							data+=2;
							ADDTO(requiredlib);
						}
					}
					else if (*data=='e') /*expected*/
					{
						data++;
						if (*data=='c') /*class*/
						{
							data+=2;
							ADDTO(expectedclass);
						}
						else if (*data=='l')
						{
							data+=2;;
							ADDTO(expectedlib);
						}
					}
					else if (*data=='d' && *(data+1)=='_')
					{
						data+=2;
						ADDTO(defaultlib);
					}
				}
				
			}
			#undef ADDTO
			
			#define DISPLAY(WHAT,STRING) if (WHAT [0] !='\0') { modulecount++; printf("%22s: %s\n",STRING,WHAT); }
			
			DISPLAY(forcedloaded,"Forced loaded modules");
			DISPLAY(expectedlib,"Expected libraries");
			DISPLAY(expectedclass,"Expected classes");
			DISPLAY(requiredlib,"Required libraries");
			DISPLAY(requiredclass,"Required classes");
			DISPLAY(defaultlib,"Default libraries");
			
			#undef DISPLAY
			
			
			if (modulecount==0)
			{
				printf("No module data detected.\n");
			}
			fflush(stdout);
			
			break;
		}
		case FT_SOURCEMOD:
		{
			printf("Modules list is not implemented for SourceMod.\n");
			break;
		}
	}
}

void PARSER_ListNatives(void)
{
	char			*data;
	unsigned int	 numnatives;
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			/* Count of tags is librariesoffset-nativessoffset (so size of the natives portion) / defsize */
			numnatives=(AMXXHDR.libraries-AMXXHDR.natives) / AMXXHDR.defsize;
			
			while (numnatives--)
			{
				data=header.data + (unsigned int)AMXXHDR.natives + (unsigned int)(AMXXHDR.defsize * numnatives);
				
				data=header.data + (unsigned int)(((AMX_FUNCSTUBNT*)data)->nameofs);
				
				printf("native: %s\n",data);
			}
			
			fflush(stdout);
			
			break;
		}
		case FT_SOURCEMOD:
		{
			numnatives=(SMHDR.info.natives_num);
			
			while (numnatives--)
			{
				printf("native: %s\n",SMHDR.info.stringbase + SMHDR.info.natives[numnatives].name);
			}
			break;
		}
	}
}
void PARSER_ListFunctions(void)
{
	int			 index=0;
	char		 addr[64];
	char		 buff[512];

	switch(header.type)
	{
		case FT_AMXX:
		{

			while (index < AMXXDBG.hdr->symbols) 
			{
				if (AMXXDBG.symboltbl[index]->ident == iFUNCTN)
				{
					snprintf(addr,sizeof(addr)-1,"0x%08X",AMXXDBG.symboltbl[index]->address/*codestart*/);
					GetFullFunctionHeader(index,buff,sizeof(buff)-1);
					printf("%-10s %s\n",progopts.hideaddresses == 1 ? "" : addr,buff);
				}
				++index;
			}
			break;
		}
		case FT_SOURCEMOD:
		{
			while (index < SMHDR.debug.syms_num)
			{
				if (SMHDR.debug.symbols[index].codestart>SMHDR.pcode_size)
				{
					++index;
					continue;
				}
				printf("symbol %d:\n",index);
				printf("  addr=     0x%X\n",SMHDR.debug.symbols[index].addr);
				printf("  tagid=    %d\n",(int)SMHDR.debug.symbols[index].tagid);
				printf("  codestart=0x%X\n",SMHDR.debug.symbols[index].codestart);
				printf("  codeend=  0x%X\n",SMHDR.debug.symbols[index].codeend);
				printf("  ident=    %d\n",SMHDR.debug.symbols[index].ident);
				printf("  vclass=   %d\n",SMHDR.debug.symbols[index].vclass);
				printf("  dimcount= %d\n",SMHDR.debug.symbols[index].dimcount);
				printf("  name=     %X(%p)\n",SMHDR.debug.symbols[index].name,SMHDR.debug.stringbase);
				if (SMHDR.debug.symbols[index].ident == SP_SYM_FUNCTION)
				{
					snprintf(addr,sizeof(addr)-1,"0x%X",SMHDR.debug.symbols[index].addr);
					GetFullFunctionHeader(index,buff,sizeof(buff)-1);
					printf("%-10s %s\n",progopts.hideaddresses == 1 ? "" : addr,buff);
				}
				++index;
			}
		}
	}
}

void PARSER_ListGlobalVariables(void)
{
	int			 index=0;
	char		 buffer[1024];
	char		 addr[64];

	switch(header.type)
	{
		case FT_AMXX:
		{
			while (index<AMXXDBG.hdr->symbols)
			{
				if (AMXXDBG.symboltbl[index]->ident!=iFUNCTN)
				{
					if (AMXXDBG.symboltbl[index]->vclass==0/*global*/)
					{
						snprintf(addr,sizeof(addr)-1,"0x%08X",AMXXDBG.symboltbl[index]->address/*codestart*/);
						GetFullVariableName(index,buffer,sizeof(buffer)-1);
						printf("%-10s new %s\n",progopts.hideaddresses == 1 ? "" : addr,buffer);
					}
				}
				++index;
			}
			break;
		}
		
	}
	
}
void PARSER_ListAllSymbols(void)
{
	int			 index=0;
	char		 addr[64];
	char		 dimensions[128];

	switch(header.type)
	{
		case FT_AMXX:
		{
			printf("%-10s %-10s %-10s %-12s %s\n","codestart","codeend","address","type","name");
			while (index < AMXXDBG.hdr->symbols) 
			{
				snprintf(addr,sizeof(addr)-1,"0x%08X",AMXXDBG.symboltbl[index]->codestart);
				printf("%-10s ",addr);
				snprintf(addr,sizeof(addr)-1,"0x%08X",AMXXDBG.symboltbl[index]->codeend);
				printf("%-10s ",addr);
				
				snprintf(addr,sizeof(addr)-1,"0x%08X",AMXXDBG.symboltbl[index]->address/*codestart*/);
				
				switch(AMXXDBG.symboltbl[index]->ident)
				{
					case iARRAY:
					case iREFARRAY:
					{
						GetFullSymbolDim(index, dimensions, sizeof(dimensions)-1);
						printf("%-10s %-8s %-3s %s%s\n",addr,GetSymbolScope(AMXXDBG.symboltbl[index]->vclass),AMXXDBG.symboltbl[index]->ident == iARRAY ? "val" : "ref", AMXXDBG.symboltbl[index]->name,dimensions);
						break;
					}
					case iVARIABLE:  /* cell that has an address and that can be fetched directly (lvalue) */
					case iREFERENCE:  /* iVARIABLE, but must be dereferenced */
					{
						printf("%-10s %-8s %-3s %s\n",addr,GetSymbolScope(AMXXDBG.symboltbl[index]->vclass),AMXXDBG.symboltbl[index]->ident == iVARIABLE ? "val" : "ref",AMXXDBG.symboltbl[index]->name);
						break;
					}
					case iFUNCTN:
					{
						printf("%-10s %-12s %s\n",addr,IsFunctionPublic(AMXXDBG.symboltbl[index]->codestart) ? "public" : "stock", AMXXDBG.symboltbl[index]->name);
						break;
					}
				}
				++index;
			}
			
			break;
		}
	}
}
