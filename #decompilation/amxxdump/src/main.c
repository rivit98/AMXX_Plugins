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
#include "headerreader.h"

#define VERSION		"1.5"

char 		*commandname=NULL; /* Command this program was invoked with. */

progopts_t progopts;

int main(int argc, char **argv)
{
	int 			 c=0;
	ucell 			 address;
	ucell			 codestart;
	ucell			 codeend;
	
	opterr=0;

	memset(&progopts,0x0,sizeof(progopts));
	
	while ((c=getopt(argc,argv,"NA:hgEecjlfF:v:V:mldD:sxnar:R:?!"))!=-1)
	{
		switch(c)
		{
			case 'N':
			{
				progopts.cleannatives=1;
				progopts.nativesyntax=1;
				break;
			}
			case 'A':
			{
				progopts.dumparray=optarg;
				break;
			}
			case 'h':
			{
				progopts.hideparams=1;
				progopts.hideaddresses=1;
				break;
			}
			case 'g':
			{
				progopts.listglobals=1;
				break;
			}
			case 'E':
			{
				progopts.nativesyntax=1;
				break;
			}
			case 'e':
			{
				progopts.showdata=1;
				break;
			}
			case 'c':
			{
				progopts.hidecomments=1;
				break;
			}
			case 'j':
			{
				progopts.labeljumps=1;
				break;
			}
			case 'l':
			{
				progopts.showlines=1;
				break;
			}
			case 'f':
			{
				progopts.listfiles=1;
				break;
			}
			case 'F':
			{
				progopts.datavaluefloat=optarg;
				break;
			}
			case 'v':
			{
				progopts.datavalue=optarg;
				break;
			}
			case 'V':
			{
				progopts.datavaluestring=optarg;
				break;
			}
			case 'r':
			{
				progopts.referencefunction=optarg;
				break;
			}
			case 'R':
			{
				progopts.referencenative=optarg;
				break;
			}
			case 'a':
			{
				progopts.hideaddresses=1;
				break;
			}
			case 'm':
			{
				progopts.showmodules=1;
				break;
			}
			case 'd':
			{
				progopts.disassemblefull=1;
				break;
			}
			case 'D':
			{
				progopts.lookupfunction=optarg;
				break;
			}
			case 's':
			{
				progopts.showsymbols=1;
				break;
			}
			case 'x':
			{
				progopts.listfunctions=1;
				break;
			}
			case 'n':
			{
				progopts.listnatives=1;
				break;
			}
			case '?':
			{
				printf("amxxdump v%s built on %s (c) 2007 steve dudenhoeffer\n",VERSION,__DATE__);
				printf("This program is provided as-is with no warranty of any kind.\n");
				printf("Run with \'-!\' for more details.\n");
				printf("usage: %s [params] file.amxx\n",argv[0]);
				printf("\n");
				printf("\t Optional parameters:\n");
				printf("\t   -a        Suppress address locations in most places.\n"); /* done */
				printf("\t   -c        Suppress all comments from disassembly.\n");
				printf("\t   -x        List all public and stock functions and their parameters.\n"); /* done */
				printf("\t   -n        List all natives used by the plugin.\n"); /* done */
				printf("\t   -D <name> Disassemble the provided function.\n"); /* done */
				printf("\t   -d        Disassemble the entire code section of the script.\n"); /* done */
				printf("\t   -s        Show all symbols.\n"); /* done */
				printf("\t   -m        Show required modules.\n"); /* done */
				printf("\t   -r <name> Search for all references to the named function.\n"); /* done */
				printf("\t   -R <name> Search for all references to the named native.\n"); /* done */
				printf("\t   -v <val>  Display the value of an address in the data section.\n"); /* done */
				printf("\t   -A <size> In addition to -v, this dumps <size> many cells as an output.\n"); /* done */
				printf("\t   -V <val>  Display the value of an address in the data section as a string.\n"); /* done */
				printf("\t   -F <val>  Display the value of an address in the data section as a float.\n"); /* done */
				printf("\t   -f        Output the name of every file that included code (stocks).\n"); /* done */
				printf("\t   -l        Output line number and filename as comment on BREAK ops.\n"); /* done */
				printf("\t   -j        Output jump labels as comments for jumps, switches and case tables.\n"); /* done */
				printf("\t   -e        Attempt to estimate some data from push.c/const.pri ops. Do not read data literally.\n"); /* done */
				printf("\t   -E        Attempt to list parameters of standard native calls.  Not all will work, requires include files.\n"); /* done */
				printf("\t   -N        Suppresses the variable dimensions, tags, and default values in the native guesser output.  Implies -E\n"); /* done */
				printf("\t   -g        List all global variables.  A pawn compiler bug will make not-used stock variables display as well.\n"); /* done */
				printf("\t   -h        Hide parameter numbers and addresses, useful for comparing with diffs.\n"); /*done*/
				printf("\n");
				printf("\t   -!        Display this program's license.\n"); /* done */
				printf("\n");
				printf("\t   -?        This help screen.\n"); /*done*/
				

				exit(0);
				break;
				
			}
			case '!':
			{
				printf("amxxdump v%s built on %s\n",VERSION,__DATE__);
				printf("\n");
				printf(" (c) 2007 steve dudenhoeffer\n");
				printf("\n");
				printf("\n");
				printf("  This program is free software; you can redistribute it and/or modify it\n");
				printf("  under the terms of the GNU General Public License as published by the\n");
				printf("  Free Software Foundation; either version 2 of the License, or (at\n");
				printf("  your option) any later version.\n");
				printf("\n");
				printf("  This program is distributed in the hope that it will be useful, but\n");
				printf("  WITHOUT ANY WARRANTY; without even the implied warranty of\n");
				printf("  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU\n");
				printf("  General Public License for more details.\n");
				printf("\n");
				printf("  You should have received a copy of the GNU General Public License\n");
				printf("  along with this program; if not, write to the Free Software Foundation,\n");
				printf("  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA\n");
				printf("\n");
				exit(0);
				break;
			}
			default:
			{
				fprintf(stderr,"Invalid option.");
				fflush(stderr);
				return 1;
			}
		}
	}
	
	c=optind;
	
	if (c<argc)
	{
		progopts.filename=argv[c];
	}
	
	
	memset(&(header),0x0,sizeof(commonheader_t));
	
	if ((Error=COMMON_LoadFile(progopts.filename))!=ERR_NONE)
	{
		throw_generic_error(progopts.filename);
		return Error;
	}
	

	if (progopts.showmodules)
	{
		PARSER_ListModules();
	}
	
	if (progopts.listnatives)
	{
		PARSER_ListNatives();
	}
	
	if (progopts.listfunctions)
	{
		PARSER_ListFunctions();
	}
	if (progopts.showsymbols)
	{
		PARSER_ListAllSymbols();
	}
	natives=list_create();
	if (progopts.nativesyntax)
	{
		LoadAMXXIncludes(argv[0]);
	}
	if (progopts.listglobals)
	{
		PARSER_ListGlobalVariables();
	}
	if (progopts.lookupfunction!=NULL)
	{
		address=LookupFunctionByName(progopts.lookupfunction,&codestart,&codeend);
		
		if (address!=0xFFFFFFFF)
		{
			if (progopts.labeljumps)
			{
				printdata=0;
				labeljumps=1;
				DisplayOpCodes(codestart,codeend);
				labeljumps=0;
			}
			printdata=1;
			DisplayOpCodes(codestart,codeend);
			printdata=0;
		}
		else
		{
			printf("Function \"%s\" not found.  Use -x to list functions.",progopts.lookupfunction);
		}
	}
	if (progopts.disassemblefull)
	{
		int CodeOffsetStart;
		
		switch(header.type)
		{
			case FT_AMXX:
			{
				CodeOffsetStart=0x8;
				break;
			}
			case FT_SOURCEMOD:
			{
				CodeOffsetStart=0x8;
				break;
			}
			default:
			{
				CodeOffsetStart=0x8;
				break;
			}
		}
		if (progopts.labeljumps)
		{
			printdata=0;
			labeljumps=1;
			DisplayOpCodes(CodeOffsetStart,GetCodSize());
			labeljumps=0;
		}
		printdata=1;
		DisplayOpCodes(CodeOffsetStart,GetCodSize());
		printdata=0;
	}
	if (progopts.referencefunction!=NULL)
	{
		address=LookupFunctionByName(progopts.referencefunction,&codestart,&codeend);
		
		if (address!=0xFFFFFFFF)
		{
			printdata=0;
			SearchForProc=address;
			printf("Searching for function \"%s\"\n",progopts.referencefunction);
			switch(header.type)
			{
				case FT_AMXX:
				{
					DisplayOpCodes(0,AMXXHDR.dat - AMXXHDR.cod);
					break;
				}
			}
			SearchForProc=0xFFFFFFFF;
		}
		else
		{
			printf("Function \"%s\" not found.  Use -x to list functions.",progopts.referencefunction);
		}
	}
	if (progopts.referencenative!=NULL)
	{
		int index=GetNativeIndexByName(progopts.referencenative);
		
		if (index!=-1)
		{
			printdata=0;
			SearchForNative=index;
			printf("Searching for native \"%s\"\n",progopts.referencenative);
			switch(header.type)
			{
				case FT_AMXX:
				{
					DisplayOpCodes(0,AMXXHDR.dat - AMXXHDR.cod);
					break;
				}
			}
			SearchForNative=0xFFFFFFFF;
		}
		else
		{
			printf("Native \"%s\" not found.  Use -n to list natives.",progopts.referencefunction);
		}
	}
	if (progopts.datavaluestring!=NULL)
	{
		/* Get the value of the parameter first */
		ucell		 offs;
		char		*addr=NULL;
		char		 buffer[1024];
		char		*endptr;
		ucell		 datsize=0;
		
		offs=strtoul(progopts.datavaluestring,&endptr,0);
		
		/* Check to see if we were given a name */
		if (offs==0)
		{
			if (!isdigit((int)(*(progopts.datavaluestring))))
			{
				/* Yes, try to find it */
				offs=LookupVariableAddressByName(progopts.datavaluestring);
			}
		}
		
		/* Verify that the offset is within the DAT section */
		switch(header.type)
		{
			case FT_AMXX:
			{
				datsize=AMXXHDR.hea - AMXXHDR.dat;
				break;
			}
		}
		
		if (offs >= datsize)
		{
			printf("0x%X is out of the DAT bounds.  High bound is 0x%X.\n",offs,datsize-1);
		}
		else
		{
			switch(header.type)
			{
				case FT_AMXX:
				{
					addr=header.data + AMXXHDR.dat;
					break;
				}
			}
			addr+=offs;
			GetAmxString(addr,buffer,sizeof(buffer)-1);
			/*printf("Value of 0x%X as a string: %s\n",offs,buffer);*/
			printf("%s\n",buffer);
		}
		
	}
	if (progopts.datavalue!=NULL)
	{
		/* Get the value of the parameter first */
		ucell		 offs;
		char		*addr;
		char		*endptr;
		ucell		 datsize;

		offs=strtoul(progopts.datavalue,&endptr,0);
		
		
		/* Check to see if we were given a name */
		if (offs==0)
		{
			if (!isdigit((int)(*(progopts.datavalue))))
			{
				/* Yes, try to find it */
				offs=LookupVariableAddressByName(progopts.datavalue);
			}
		}

		if (progopts.dumparray!=NULL) /* dump an array instead of a single cell */
		{
			ucell size=strtoul(progopts.dumparray,&endptr,0);
			ucell count=0;
			ucell val;
			/* Verify that the offset is within the DAT section */
			datsize=AMXXHDR.hea - AMXXHDR.dat;
			
			if (offs >= datsize)
			{
				printf("0x%X is out of the DAT bounds.  High bound is 0x%X.\n",offs,datsize-1);
			}
			else
			{
				addr=header.data + AMXXHDR.dat;
				addr+=offs;
				while (size--)
				{
					/*printf("Value of 0x%X: 0x%X\n",offs,*((cell *)addr));*/
					val=*((ucell *)addr);
					if (val < 128 && val > 31)
					{
						printf(" '%c'",val);
					}
					else
					{
						printf(" 0x%08X",val);
					}
					
					if (size!=0)
					{
						printf(",");
					}
					count++;
					
					if (count==10)
					{
						printf("\n");
						count=0;
					}
					addr+=4;
				}
			}
			
			
		}
		else
		{
			/* Verify that the offset is within the DAT section */
			datsize=AMXXHDR.hea - AMXXHDR.dat;
			
			if (offs >= datsize)
			{
				printf("0x%X is out of the DAT bounds.  High bound is 0x%X.\n",offs,datsize-1);
			}
			else
			{
				addr=header.data + AMXXHDR.dat;
				addr+=offs;
				/*printf("Value of 0x%X: 0x%X\n",offs,*((cell *)addr));*/
				printf("0x%X\n",*((cell *)addr));
			}
		}
		
	}
	if (progopts.datavaluefloat!=NULL)
	{
		/* Get the value of the parameter first */
		ucell		 offs;
		char		*addr;
		char		*endptr;
		ucell		 datsize;
		
		offs=strtoul(progopts.datavaluefloat,&endptr,0);
		
		/* Verify that the offset is within the DAT section */
		datsize=AMXXHDR.hea - AMXXHDR.dat;
		
		if (offs >= datsize)
		{
			printf("0x%X is out of the DAT bounds.  High bound is 0x%X.\n",offs,datsize-1);
		}
		else
		{
			addr=header.data + AMXXHDR.dat;
			addr+=offs;
			/*printf("Value of 0x%X: %f\n",offs,*((float *)addr));*/
			printf("%f\n",*((float *)addr));
		}
		
	}
	if (progopts.listfiles)
	{
		PARSER_ListFiles();
	}
	
	

	free(header.data);
	return 0;
}
