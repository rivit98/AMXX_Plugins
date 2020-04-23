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
#include "list.h"
#include "stack.h"
#include "headerreader.h"


list_t *jumplist=NULL;
stack_t *pstack=NULL;
stack_t *tstack=NULL;

#define LABEL_JUMP		0
#define LABEL_CASE		1
#define LABEL_SWITCH	2
#define LABEL_ENDCASE	3

#define PRINT_OPCODE_LENGTH	32
#define PRINT_COMMENT_START	44
#define PRINT_PARAM_LENGTH	12

typedef struct jumplabel_s
{
	ucell			addr;
	ucell			insertedat;
	unsigned int	jumpnumber;
	unsigned int	prefix;
	unsigned int	prefixnum;
	int				isdefault;
} jumplabel_t;

unsigned int jumpnumber;
unsigned int casecount;
unsigned int switchcount;

void endl();
void PrintOpCode(const char *OpCode);
void PrintComment(const char *Comment);

static int check_label(void *data, void *match);
static void make_label(ucell addr, unsigned int type, unsigned int num, int isdefault, ucell insertedat);
char LabelBuffer[256];

/**
 * Creates a pseudo label name out of the given address, and adds it to the jump list.
 *
 * @param addr		The address of the jump target.
 * @param type		The LABEL_* type of label this is for.
 * @param num		On LABEL_CASE, this is the case number for the statement.
 */
static void make_label(ucell addr, unsigned int type, unsigned int num, int isdefault, ucell insertedat)
{
	if (type==LABEL_ENDCASE)
	{
		casecount++;
		
		return;
	}
	jumplabel_t *ret=(jumplabel_t *)malloc(sizeof(jumplabel_t));
	
	ret->addr=addr;
	
	ret->prefix=type;
	ret->insertedat=insertedat;
	
	switch(type)
	{
		case LABEL_JUMP:
		{
			ret->jumpnumber=jumpnumber++;
			break;
		}
		case LABEL_CASE:
		{
			ret->jumpnumber=num;
			ret->prefixnum=casecount;
			ret->isdefault=isdefault;
			break;
		}
		case LABEL_SWITCH:
		{
			ret->jumpnumber=switchcount++;
			break;
		}
		default:
		{
			fprintf(stderr,"Error: Invalid type (%d) in make_label.\n",type);
			fflush(stderr);
			exit(1);
		}
	}
	
	list_add((void *)ret,jumplist);
}
static int check_label(void *data, void *match)
{
	if (((jumplabel_t *)data)->insertedat==*((ucell *)match))
	{
		switch (((jumplabel_t *)data)->prefix)
		{
			case LABEL_JUMP:
			{
				snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"jump_%u",((jumplabel_t *)data)->jumpnumber);
				break;
			}
			case LABEL_CASE:
			{
				if (((jumplabel_t *)data)->isdefault)
				{
					snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"case_%u_default",((jumplabel_t *)data)->prefixnum);
				}
				else
				{
					snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"case_%u_%u",((jumplabel_t *)data)->prefixnum,((jumplabel_t *)data)->jumpnumber);
				}
				break;
			}
			case LABEL_SWITCH:
			{
				snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"switch_%u",((jumplabel_t *)data)->jumpnumber);
				break;
			}
			default:
			{
				fprintf(stderr,"Error: Invalid prefix (%d) in check_label.\n",((jumplabel_t *)data)->prefix);
				fflush(stderr);
				exit(1);
			}
		}
		PrintComment(LabelBuffer);
	}
	return 0;
}
static int check_target(void *data, void *match)
{
	if (((jumplabel_t *)data)->addr==*((ucell *)match))
	{
		switch (((jumplabel_t *)data)->prefix)
		{
			case LABEL_JUMP:
			{
				snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"target:jump_%u",((jumplabel_t *)data)->jumpnumber);
				break;
			}
			case LABEL_CASE:
			{
				if (((jumplabel_t *)data)->isdefault)
				{
					snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"target:case_%u_default",((jumplabel_t *)data)->prefixnum);
				}
				else
				{
					snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"target:case_%u_%u",((jumplabel_t *)data)->prefixnum,((jumplabel_t *)data)->jumpnumber);
				}
				break;
			}
			case LABEL_SWITCH:
			{
				snprintf(LabelBuffer,sizeof(LabelBuffer)-1,"target:switch_%u",((jumplabel_t *)data)->jumpnumber);
				break;
			}
			default:
			{
				fprintf(stderr,"Error: Invalid prefix (%d) in check_target.\n",((jumplabel_t *)data)->prefix);
				fflush(stderr);
				exit(1);
			}
		}
		PrintComment(LabelBuffer);
	}
	return 0;
}
int printdata=0;
ucell SearchForNative=0xFFFFFFFF;
ucell SearchForProc=0xFFFFFFFF;
int labeljumps=0;

char CurrentFunction[512];

char *loc;
ucell _start;
ucell _end;
ucell _addr;
unsigned int currentspaces=0;

void endl();
void PrintOpCode(const char *OpCode);
void PrintComment(const char *Comment);


void PrintOpCode(const char *OpCode)
{
	char		 saddr[64];
	
	if (!printdata)
	{
		return;
	}
	
	snprintf(saddr,sizeof(saddr)-1,"0x%X",_addr-4);
	
	printf("%-10s %20s ",progopts.hideaddresses == 1 ? "" : saddr,OpCode);
	
	currentspaces=PRINT_OPCODE_LENGTH;
	
}

void PrintComment(const char *Comment)
{
	char temp[64];

	if (!printdata || progopts.hidecomments)
	{
		return;
	}

	if (currentspaces > PRINT_COMMENT_START)
	{
		endl();
		currentspaces=0;
	}
	if (currentspaces < PRINT_COMMENT_START)
	{
		snprintf(temp,sizeof(temp)-1,"%%-%ds",PRINT_COMMENT_START - currentspaces);
		
		printf(temp,"");
		
		currentspaces=PRINT_COMMENT_START;
	}
	printf(" ; %s",Comment);
	currentspaces=PRINT_COMMENT_START+1;
}
void PrintParamString(const char *Data)
{
	if (!printdata)
	{
		return;
	}

	currentspaces+=2 + strlen(Data);
	printf(" %s ",Data);
}
void PrintParamUCell(const ucell Data)
{
	char		paramdata[64];

	if (!printdata)
	{
		return;
	}

	snprintf(paramdata,sizeof(paramdata)," %%-%du ",PRINT_PARAM_LENGTH-2);

	currentspaces+=PRINT_PARAM_LENGTH;
	printf(paramdata,Data);
}
void PrintParamCell(const cell Data)
{
	char 	paramdata[64];
	
	if (!printdata)
	{
		return;
	}
	
	snprintf(paramdata,sizeof(paramdata)," %%-%dd ",PRINT_PARAM_LENGTH-2);

	currentspaces+=PRINT_PARAM_LENGTH;
	printf(paramdata,Data);
}
void PrintParamHex(const ucell Data)
{
	char		buffer[64];
	char		paramdata[64];
	
	if (!printdata)
	{
		return;
	}

	snprintf(buffer,sizeof(buffer)-1,"0x%X",Data);
	
	snprintf(paramdata,sizeof(paramdata)," %%-%ds ",PRINT_PARAM_LENGTH-2);

	currentspaces+=PRINT_PARAM_LENGTH;
	printf(paramdata,progopts.hideparams ? "" : buffer);
}


ucell GetOp()
{
	/*_addr+=1;
	return *loc++;
	*/
	_addr+=4;
	ucell ret=*((cell *)loc);
	
	loc+=4;
	return ret;

}
ucell PeekOp()
{
	ucell ret=*((cell *)loc);
	
	return ret;

}

ucell GetParam()
{
	_addr+=4;
	cell ret=*((ucell *)loc);
	stack_push(tstack,(void *)ret);
	
	loc+=4;
	return ret;
}

cell GetSParam()
{
	_addr+=4;
	ucell ret=*((cell *)loc);
	stack_push(tstack,(void *)ret);
	
	loc+=4;
	return ret;
}


void endl()
{
	if (!printdata)
	{
		return;
	}
	printf("\n");
	fflush(stdout);
	
	currentspaces=0;
}

void DisplayOpCodes(ucell start, ucell end)
{
	
	ucell 		 op;
	ucell		 param;
	ucell		 paramb;
	ucell		 paramc;
	ucell		 paramd=0;
	ucell		 parame;
	char 		 Comment[1024];
	char		 Comment2[1024];
	char		 buff[64];
	ucell		 oldaddr=0xFFFFFFFF;
	int 		 variablecount=0;
	int			 variableiter=0;

	
	CurrentFunction[0]='\0';
	
	_addr=start;

	loc=GetCodStart();
	loc+=start;
	
	/* Stop some warnings for now. */
	paramd=parame=paramc=paramd;

	/* If labeljumps is 1, then we are scanning through the op codes an extra time.
	 * the first time, we're collecting and pseudo labelling jumps.
	 * The second time (which is when the labels get displayed), we're outputting
	 * the name of the jumps as comments
	 */
	if (labeljumps)
	{
		jumplist=list_create();
		jumpnumber=0;
		casecount=0;
		switchcount=0;
	}
	
	/* For S/LCTRL */
	static const char *registers[7] = { "COD", "DAT", "HEA", "STP", "STK", "FRM", "CIP" };
	
	tstack=stack_create(32);
	pstack=stack_create(32);
	
	while (_addr<end)
	{
	
		if (jumplist!=NULL)
		{
			list_iterate(jumplist,check_target,&oldaddr);
		}
		
		if (Comment[0]!=0)
		{
			/* New variable declaration here. */
			//PrintCommentOnNewLine(Comment);
		}
		oldaddr=_addr;
		op=GetOp();
		endl();
		currentspaces=0;

		/* Scan to see if there are any variables with a scope start at the old address. */
		/* Send the duration of the oldaddr (from opcode through all params) to make sure I get everything.*/
		
		variablecount=0;
		variableiter=0;
		
		/* This spams on PROC ops (global vars), so ignore it on them. */
		if (op!=OP_PROC)
		{
			while ((variableiter=GetNewVariableDeclarations(oldaddr-4,_addr-4,Comment,sizeof(Comment)-1,variableiter))!=0)
			{
				PrintComment(Comment);
				endl();
				
				variablecount++;
			}
		}

		
		while (!stack_isempty(tstack))
		{
			stack_push(pstack,stack_pop(tstack));
		}
		if (op==OP_BREAK || op==OP_RETN)
		{
			stack_destroy(pstack);
			pstack=stack_create(32);
		}
		else
		{
			stack_push(tstack,(void *)op);
		}
		switch(op)
		{
			/* Load address into PRI. */
			case OP_LOAD_PRI:
			{
				PrintOpCode("LOAD.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* Load address into ALT. */
			case OP_LOAD_ALT:
			{
				PrintOpCode("LOAD.alt");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* Load stack offset into PRI. */
			case OP_LOAD_S_PRI:
			{
				PrintOpCode("LOAD.S.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* Load stack offset into ALT. */
			case OP_LOAD_S_ALT:
			{
				PrintOpCode("LOAD.S.alt");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* Load address ref into PRI. */
			case OP_LREF_PRI:
			{
				PrintOpCode("LREF.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* Load address ref into ALT. */
			case OP_LREF_ALT:
			{
				PrintOpCode("LREF.alt");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* Load stack offset ref into PRI. */
			case OP_LREF_S_PRI:
			{
				PrintOpCode("LREF.S.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* Load stack offset ref into ALT. */
			case OP_LREF_S_ALT:
			{
				PrintOpCode("LREF.S.alt");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* PRI = [PRI] */
			case OP_LOAD_I:
			{
				PrintOpCode("LOAD.I");
				
				break;
			}
			/* PRI = [PRI + Param bytes] */
			case OP_LODB_I:
			{
				PrintOpCode("LOBD.I");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI = value */
			case OP_CONST_PRI:
			{
				PrintOpCode("CONST.pri");
				param=GetParam();
				PrintParamHex(param);
				if (progopts.showdata)
				{
					char Temp[1024];
					
					GetVariableNameByAddress(param,Comment,sizeof(Temp)-1);
					
					if (IsInDat(param))
					{
						switch(GetLikelyDatType(param))
						{
							case 0: /* integer */
							{
								snprintf(Temp,sizeof(Temp),"0x%X (%0.5f)",ReadDatUCell(param),(float)ReadDatUCell(param));
								if (Comment[0]!=0)
								{
									strncat(Comment,"=",sizeof(Comment)-1);
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								else
								{
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								break;
							}
							case 1: /* string */
							{
								ReadDatString(param,Temp,sizeof(Temp)-1);
								if (Comment[0]!=0)
								{
									strncat(Comment,"={",sizeof(Comment)-1);
									strncat(Comment,Temp,sizeof(Comment)-1);
									strncat(Comment,"}",sizeof(Comment)-1);
								}
								else
								{
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								break;
							}
							
							default:
							{
							}
						}
					}
					if (Comment[0]!=0)
					{
						PrintComment(Comment);
					}
					else
					{
						snprintf(Comment,sizeof(Comment)-1,"signed=%d float=%f\n",*(int *)&param,*(float *)&param);
						PrintComment(Comment);
					}
				}
				break;
			}
			/* ALT = value */
			case OP_CONST_ALT:
			{
				PrintOpCode("CONST.alt");
				param=GetParam();
				PrintParamHex(param);
				
				if (progopts.showdata)
				{
					char Temp[1024];
					
					GetVariableNameByAddress(param,Comment,sizeof(Temp)-1);
					
					if (IsInDat(param))
					{
						switch(GetLikelyDatType(param))
						{
							case 0: /* integer */
							{
								snprintf(Temp,sizeof(Temp),"0x%X (%0.5f)",ReadDatUCell(param),(float)ReadDatUCell(param));
								if (Comment[0]!=0)
								{
									strncat(Comment,"=",sizeof(Comment)-1);
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								else
								{
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								break;
							}
							case 1: /* string */
							{
								ReadDatString(param,Comment,sizeof(Comment)-1);
								if (Comment[0]!=0)
								{
									strncat(Comment,"={",sizeof(Comment)-1);
									strncat(Comment,Temp,sizeof(Comment)-1);
									strncat(Comment,"}",sizeof(Comment)-1);
								}
								else
								{
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								break;
							}
							
							default:
							{
							}
						}
					}
					if (Comment[0]!=0)
					{
						PrintComment(Comment);
					}
				}

				
				break;
			}
			/* PRI = FRM + offs */
			case OP_ADDR_PRI:
			{
				PrintOpCode("ADDR.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* ALT = FRM + offs */
			case OP_ADDR_ALT:
			{
				PrintOpCode("ADDR.alt");
				
				param=GetParam();
				PrintParamHex(param);

#if 0				
				paramb=PeekOp();
				if (paramb==OP_FILL) /* New array declaration, check for multiple variables in one declaration. */
				{
					paramb=*((ucell *)((loc + 4)));
					
					/* Paramb is how much we're filling with. */
					
					GetAllVariablesInFrameOffset(_addr-4,param,paramb,Comment,sizeof(Comment)-1);
				}
				else
				{
					GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				}
				
				PrintComment(Comment);
#endif			
				break;
			}
			/* [ Param ] = PRI */
			case OP_STOR_PRI:
			{
				PrintOpCode("STOR.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [ Param ] = ALT */
			case OP_STOR_ALT:
			{
				PrintOpCode("STOR.alt");

				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [ Stack + Param ] = PRI */
			case OP_STOR_S_PRI:
			{
				PrintOpCode("STOR.S.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [ Stack + Param ] = ALT */
			case OP_STOR_S_ALT:
			{
				PrintOpCode("STOR.S.alt");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [ [ Param ] ] = PRI */
			case OP_SREF_PRI:
			{
				PrintOpCode("SREF.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* [ [ Param ] ] = ALT */
			case OP_SREF_ALT:
			{
				PrintOpCode("SREF.alt");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* [ [ Stack + Param ] ] = PRI */
			case OP_SREF_S_PRI:
			{
				PrintOpCode("SREF.S.pri");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* [ [ Stack + Param ] ] = ALT */
			case OP_SREF_S_ALT:
			{
				PrintOpCode("SREF.S.alt");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				break;
			}
			/* [ ALT ] = PRI */
			case OP_STOR_I:
			{
				PrintOpCode("STOR.I");
				
				break;
			}
			/* [ ALT ] = PRI (Param = number of bytes written) */
			case OP_STRB_I:
			{
				PrintOpCode("STRB.I");
				PrintParamHex(GetParam());
				
				break;
			}
			
			/* PRI = [ ALT + (PRI * sizeof(cell)) ] */
			case OP_LIDX:
			{
				PrintOpCode("LIDX");
				
				break;
			}
			/* PRI = [ ALT + (PRI << param)] */
			case OP_LIDX_B:
			{
				PrintOpCode("LIDX.B");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI = ALT + (PRI * sizeof(cell)) */
			case OP_IDXADDR:
			{
				PrintOpCode("IDXADDR");
				
				break;
			}
			/* PRI = ALT + (PRI << param) */
			case OP_IDXADDR_B:
			{
				PrintOpCode("IDXADDR.B");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI ^= cellsize - param */
			case OP_ALIGN_PRI:
			{
				PrintOpCode("ALIGN.pri");
				PrintParamHex(GetParam());
				
				break;
			}
			/* ALT ^= cellsize - param */
			case OP_ALIGN_ALT:
			{
				PrintOpCode("ALIGN.alt");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI is set to special register value. */
			case OP_LCTRL:
			{
				PrintOpCode("LCTRL");
				
				param=GetParam();
				
				PrintParamHex(param);
				
				if (param >= 0 && param <= 6)
				{
					PrintComment(registers[param]);
				}
				
				break;
			}
			/* the special register is set to PRI */
			case OP_SCTRL:
			{
				PrintOpCode("SCTRL");
				
				param=GetParam();
				
				PrintParamHex(param);
				
				if (param >= 0 && param <= 6)
				{
					PrintComment(registers[param]);
				}
				
				break;
			}
			/* PRI = ALT */
			case OP_MOVE_PRI:
			{
				PrintOpCode("MOVE.pri");
				
				break;
			}
			/* ALT = PRI */
			case OP_MOVE_ALT:
			{
				PrintOpCode("MOVE.alt");
				
				break;
			}
			/* Exchange alt and pri */
			case OP_XCHG:
			{
				PrintOpCode("XCHG");
				
				break;
			}
			/* [STK] = PRI; STK -= sizeof(cell) */
			case OP_PUSH_PRI:
			{
				PrintOpCode("PUSH.pri");
				
				break;
			}
			/* [STK] = ALT; STK -= sizeof(cell) */
			case OP_PUSH_ALT:
			{
				PrintOpCode("PUSH.alt");
				
				break;
			}
			/* obsolete */
			case OP_PUSH_R:
			{
				PrintOpCode("PUSH.R");
				PrintParamHex(GetParam());
				
				break;
			}
			/* [STK] = param; STK -= sizeof(cell) */
			case OP_PUSH_C:
			{
				PrintOpCode("PUSH.C");
				paramd=GetParam();
				PrintParamHex(paramd);
				
				/* If the next op is CALL, CALL.pri, SYSREQ.C or SYSREQ.pri then don't print data */
				/* Because this is the PUSH <param number> instruction, not actual data. */
				if (PeekOp()==OP_SYSREQ_C || PeekOp()==OP_SYSREQ_PRI ||
					PeekOp()==OP_CALL || PeekOp()==OP_CALL_PRI)
				{
					break;
				}
				
				if (progopts.showdata)
				{
					GetVariableNameByAddress(paramd,Comment,sizeof(Comment)-1);
					if (IsInDat(paramd))
					{
						switch(GetLikelyDatType(paramd))
						{
							case 0: /* integer */
							{
								snprintf(Comment2,sizeof(Comment2),"0x%X",ReadDatUCell(paramd));
								if (Comment[0]!=0)
								{
									strncat(Comment," ",sizeof(Comment)-1);
								}
								strncat(Comment,Comment2,sizeof(Comment)-1);
								break;
							}
							case 1: /* string */
							{
								ReadDatString(paramd,Comment2,sizeof(Comment2)-1);
								if (Comment[0]!=0)
								{
									strncat(Comment," ",sizeof(Comment)-1);
								}
								strncat(Comment,Comment2,sizeof(Comment)-1);
								break;
							}
							
							default:
							{
							}
						}
					}
					if (Comment[0]!=0)
					{
						PrintComment(Comment);
					}
					else
					{
						snprintf(Comment,sizeof(Comment)-1,"signed=%d float=%f\n",*(int *)&paramd,*(float *)&paramd);
						PrintComment(Comment);
					}
					
				}
				
				break;
			}
			/* [STK] = [PARAM]; STK -= sizeof(cell) */
			case OP_PUSH:
			{
				PrintOpCode("PUSH");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [STK] = [FRM + param]; STK -= sizeof(cell) */
			case OP_PUSH_S:
			{
				PrintOpCode("PUSH.S");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4, param, Comment, sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* STK += sizeof(cell) ; PRI = [STK] */
			case OP_POP_PRI:
			{
				PrintOpCode("POP.pri");
				
				break;
			}
			/* STK += sizeof(cell) ; ALT = [STK] */
			case OP_POP_ALT:
			{
				PrintOpCode("POP.alt");
				
				break;
			}
			/* ALT = STK; STK += param */
			case OP_STACK:
			{
				PrintOpCode("STACK");
				param=GetParam();
				PrintParamHex(param);
				
				if (param & (1<<31))
				{
					snprintf(Comment,sizeof(Comment)-1,"allocate %d cells",(-1*((cell)param))/4);
				}
				else
				{
					snprintf(Comment,sizeof(Comment)-1,"free %d cells",param/4);
				}
				PrintComment(Comment);
				
				break;
			}
			/* ALT = HEA; HEA += param */
			case OP_HEAP:
			{
				PrintOpCode("HEAP");
				PrintParamHex(GetParam());
				
				break;
			}
			/* [STK] = FRM; STK -= sizeof(cell); FRM = [STK] */
			case OP_PROC:
			{
				PrintOpCode("PROC");
				
				int  index;
				
				index=GetFunctionIndexByAddress(_addr-4);
				GetFullFunctionHeader(index,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				strncpy(CurrentFunction,Comment,sizeof(CurrentFunction)-1);
				break;
			}
			/* STK += cellsize; FRM = [STK]; STK += cellsize; CIP = [STK] */
			case OP_RET:
			{
				PrintOpCode("RET");
				
				break;
			}
			/* STK += cellsize; FRM = [STK]; STK += cellsize; CIP = [STK]; STK += [STK] */
			case OP_RETN:
			{
				PrintOpCode("RETN");
				
				break;
			}
			/* [STK] = CIP + 5; STK = STK - cellsize; CIP = param */
			case OP_CALL:
			{
				PrintOpCode("CALL");
				param=GetParam();
				PrintParamHex(param);
				
				paramb=GetFunctionIndexByAddress(param);
				GetFullFunctionHeader(paramb,Comment,sizeof(Comment)-1);
				
				PrintComment(Comment);
				
				/* If we're searching for a PROC, then check this. */
				/* SearchForProc is the PROC addr. */
				if (SearchForProc!=0xFFFFFFFF)
				{
					if (SearchForProc==param)
					{
						snprintf(buff,sizeof(buff)-1,"0x%X",_addr-8);
						printf("%-10s %s\n",progopts.hideaddresses == 1 ? "" : buff, CurrentFunction[0] == '\0' ? "Unknown" : CurrentFunction);
					}
				}
				
				break;
			}
			/* [STK] = CIP + 1; STK -= cellsize; CIP = pri */
			case OP_CALL_PRI:
			{
				PrintOpCode("CALL.pri");
				
				break;
			}
			/* CIP = param */
			case OP_JUMP:
			{
				PrintOpCode("JUMP");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}

				
				break;
			}
			
			/* CIP += param */
			case OP_JREL:
			{
				PrintOpCode("JREL");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if (PRI==0) CIP = [CIP + 1] */
			case OP_JZER:
			{
				PrintOpCode("JZER");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if (PRI!=0) CIP = [ CIP + 1 ] */
			case OP_JNZ:
			{
				PrintOpCode("JNZ");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if PRI==ALT CIP = [ CIP + 1 ] */
			case OP_JEQ:
			{
				PrintOpCode("JEQ");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if PRI!=ALT CIP = [ CIP + 1 ] */
			case OP_JNEQ:
			{
				PrintOpCode("JNEQ");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if PRI<ALT CIP = [ CIP + 1 ] */
			case OP_JLESS:
			{
				PrintOpCode("JLESS");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if PRI<=ALT CIP = [ CIP + 1 ] */
			case OP_JLEQ:
			{
				PrintOpCode("JLEQ");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if PRI>ALT CIP = [ CIP + 1 ] */
			case OP_JGRTR:
			{
				PrintOpCode("JGRTR");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if PRI>=ALT CIP = [ CIP + 1 ] */
			case OP_JGEQ:
			{
				PrintOpCode("JGEQ");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if (SIGNED) PRI<ALT CIP = [ CIP + 1 ] */
			case OP_JSLESS:
			{
				PrintOpCode("JSLESS");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if SIGNED PRI<=ALT CIP = [ CIP + 1 ] */
			case OP_JSLEQ:
			{
				PrintOpCode("JSLEQ");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if SIGNED PRI>ALT CIP = [ CIP + 1 ] */
			case OP_JSGRTR:
			{
				PrintOpCode("JSGRTR");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* if SIGNED PRI>=ALT CIP = [ CIP + 1 ] */
			case OP_JSGEQ:
			{
				PrintOpCode("JSGEQ");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_JUMP,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			/* PRI = PRI << ALT */
			case OP_SHL:
			{
				PrintOpCode("SHL");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI = PRI >> ALT */
			case OP_SHR:
			{
				PrintOpCode("SHR");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI = PRI >> ALT SIGNED */
			case OP_SSHR:
			{
				PrintOpCode("SSHR");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI = PRI << param */
			case OP_SHL_C_PRI:
			{
				PrintOpCode("SHL.C.pri");
				PrintParamHex(GetParam());
				
				break;
			}
			/* ALT = ALT << param */
			case OP_SHL_C_ALT:
			{
				PrintOpCode("SHL.C.alt");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI = PRI >> param */
			case OP_SHR_C_PRI:
			{
				PrintOpCode("SHR.C.pri");
				PrintParamHex(GetParam());
				
				break;
			}
			/* ALT = ALT >> param */
			case OP_SHR_C_ALT:
			{
				PrintOpCode("SHR.C.alt");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI *= ALT SIGNED */
			case OP_SMUL:
			{
				PrintOpCode("SMUL");
				
				break;
			}
			/* PRI = PRI / ALT SIGNED (ALT = PRI mod ALT) */
			case OP_SDIV:
			{
				PrintOpCode("SDIV");
				
				break;
			}
			/* PRI = ALT / PRI SIGNED (ALT = PRI mod ALT) */
			case OP_SDIV_ALT:
			{
				PrintOpCode("SDIV.alt");
				
				break;
			}
			/* PRI *= ALT UNSIGNED */
			case OP_UMUL:
			{
				PrintOpCode("UMUL");
				
				break;
			}
			/* PRI = PRI / ALT UNSIGNED (ALT = PRI mod ALT) */
			case OP_UDIV:
			{
				PrintOpCode("UDIV");
				
				break;
			}
			/* PRI = ALT / PRI UNSIGNED (ALT = PRI mod ALT) */
			case OP_UDIV_ALT:
			{
				PrintOpCode("UDIV.alt");
				
				break;
			}
			/* PRI += ALT */
			case OP_ADD:
			{
				PrintOpCode("ADD");
				
				break;
			}
			/* PRI -= ALT */
			case OP_SUB:
			{
				PrintOpCode("SUB");
				
				break;
			}
			/* PRI = ALT - PRI */
			case OP_SUB_ALT:
			{
				PrintOpCode("SUB.alt");
				
				break;
			}
			/* PRI &= ALT */
			case OP_AND:
			{
				PrintOpCode("AND");
				
				break;
			}
			/* PRI |= ALT */
			case OP_OR:
			{
				PrintOpCode("OR");
				
				break;
			}
			/* PRI ^= ALT */
			case OP_XOR:
			{
				PrintOpCode("XOR");
				
				break;
			}
			/* PRI = !ALT */
			case OP_NOT:
			{
				PrintOpCode("NOT");
				
				break;
			}
			/* PRI = -PRI */
			case OP_NEG:
			{
				PrintOpCode("NEG");
				
				break;
			}
			/* PRI = ~PRI */
			case OP_INVERT:
			{
				PrintOpCode("INVERT");
				
				break;
			}
			/* PRI += param */
			case OP_ADD_C:
			{
				PrintOpCode("ADD.C");
				param=GetParam();
				PrintParamHex(param);
				snprintf(Comment,sizeof(Comment)-1,"signed:  %d",*(int *)&param);
				PrintComment(Comment);
				
				break;
			}
			/* PRI *= param */
			case OP_SMUL_C:
			{
				PrintOpCode("SMUL.C");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI=0 */
			case OP_ZERO_PRI:
			{
				PrintOpCode("ZERO.pri");
				
				break;
			}
			/* ALT=0 */
			case OP_ZERO_ALT:
			{
				PrintOpCode("ZERO.alt");
				
				break;
			}
			/* [ param ] = 0 */
			case OP_ZERO:
			{
				PrintOpCode("ZERO");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [ FRM + param ] = 0 */
			case OP_ZERO_S:
			{
				PrintOpCode("ZERO.S");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/*sign extent the byte in PRI or ALT to a cell*/
			case OP_SIGN_PRI:
			{
				PrintOpCode("SIGN.pri");
				
				break;
			}
			/*sign extent the byte in PRI or ALT to a cell*/
			case OP_SIGN_ALT:
			{
				PrintOpCode("SIGN.alt");
				
				break;
			}
			/* PRI = PRI == ALT ? 1 : 0 */
			case OP_EQ:
			{
				PrintOpCode("EQ");
				
				break;
			}
			/* PRI = PRI != ALT ? 1 : 0 */
			case OP_NEQ:
			{
				PrintOpCode("NEQ");
				
				break;
			}
			/* PRI = PRI < ALT ? 1 : 0 */
			case OP_LESS:
			{
				PrintOpCode("LESS");
				
				break;
			}
			/* PRI = PRI <= ALT ? 1 : 0 */
			case OP_LEQ:
			{
				PrintOpCode("LEQ");
				
				break;
			}
			/* PRI = PRI > ALT ? 1 : 0 */
			case OP_GRTR:
			{
				PrintOpCode("GRTR");
				
				break;
			}
			/* PRI = PRI >= ALT ? 1 : 0 */
			case OP_GEQ:
			{
				PrintOpCode("GEQ");
				
				break;
			}
			/* PRI = PRI < ALT ? 1 : 0 */
			case OP_SLESS:
			{
				PrintOpCode("SLESS");
				
				break;
			}
			/* PRI = PRI <= ALT ? 1 : 0 */
			case OP_SLEQ:
			{
				PrintOpCode("SLEQ");
				
				break;
			}
			/* PRI = PRI > ALT ? 1 : 0 */
			case OP_SGRTR:
			{
				PrintOpCode("SGRTR");
				
				break;
			}
			/* PRI = PRI >= ALT ? 1 : 0 */
			case OP_SGEQ:
			{
				PrintOpCode("SGEQ");
				
				break;
			}
			/* PRI = PRI == param ? 1 : 0 */
			case OP_EQ_C_PRI:
			{
				PrintOpCode("EQ.C.pri");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI = ALT == param ? 1 : 0 */
			case OP_EQ_C_ALT:
			{
				PrintOpCode("EQ.C.alt");
				PrintParamHex(GetParam());
				
				break;
			}
			/* PRI++ */
			case OP_INC_PRI:
			{
				PrintOpCode("INC.pri");
				
				break;
			}
			/* ALT++ */
			case OP_INC_ALT:
			{
				PrintOpCode("INC.alt");
				
				break;
			}
			/* [ param ] ++ */
			case OP_INC:
			{
				PrintOpCode("INC");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [ FRM + param ] ++ */
			case OP_INC_S:
			{
				PrintOpCode("INC.S");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [PRI]++ */
			case OP_INC_I:
			{
				PrintOpCode("INC.I");
				
				break;
			}
			/* PRI-- */
			case OP_DEC_PRI:
			{
				PrintOpCode("DEC.pri");
				
				break;
			}
			/* ALT-- */
			case OP_DEC_ALT:
			{
				PrintOpCode("DEC.alt");
				
				break;
			}
			/* [ param ] -- */
			case OP_DEC:
			{
				PrintOpCode("DEC");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByAddress(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [ FRM + param ] -- */
			case OP_DEC_S:
			{
				PrintOpCode("DEC.S");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* [PRI]-- */
			case OP_DEC_I:
			{
				PrintOpCode("DEC.I");
				
				break;
			}
			/* [ALT] = [PRI] (param is # of bytes) */
			case OP_MOVS:
			{
				PrintOpCode("MOVS");
				PrintParamHex(GetParam());
				
				break;
			}
			/* compare [ALT] to [PRI] (param is # of bytes) */
			case OP_CMPS:
			{
				PrintOpCode("CMPS");
				PrintParamHex(GetParam());
				
				break;
			}
			/* Fill memory at [ALT] with value at [PRI], param is # of bytes */
			case OP_FILL:
			{
				PrintOpCode("FILL");
				param=GetParam();
				
				PrintParamHex(param);
				
				snprintf(Comment,sizeof(Comment)-1,"%u cells",param / sizeof(cell));
				
				PrintComment(Comment);
				break;
			}
			/* Halt operation. */
			case OP_HALT:
			{
				PrintOpCode("HALT");
				PrintParamHex(GetParam());
				
				break;
			}
			/* Aborts if PRI > param or PRI < 0 */
			case OP_BOUNDS:
			{
				PrintOpCode("BOUNDS");
				PrintParamHex(GetParam());
				
				break;
			}
			/* native, native id is in PRI */
			case OP_SYSREQ_PRI:
			{
				PrintOpCode("SYSREQ.pri");
				
				break;
			}
			/* native, id is param. */
			case OP_SYSREQ_C:
			{
				PrintOpCode("SYSREQ.C");
				
				param=GetParam();
				PrintParamHex(param);

				GetNativeNameByIndex(param,Comment,sizeof(Comment)-1);
				
				if (progopts.nativesyntax)
				{
					ucell		 oldop;
					ucell		 paramcount;
					ucell		 oldparam;
					native_t	*n;
					stack_t		*ps;
					parameter_t	*p;
					char		 Temp[1024];
					
					
					oldop=(ucell)stack_pop(pstack);
					if (oldop!=OP_PUSH_C)
					{
						continue;
					}
					
					n=HEADER_FindNativeByName(Comment);
					
					if (!n)
					{
						goto not_displaying;
					}
					ps=stack_copy(n->params);
					stack_reverse(ps);
					paramcount=(ucell)stack_pop(pstack);
					
					paramcount /= sizeof(cell);
					
					snprintf(Comment,sizeof(Comment)-1,"%s%s(",n->tag==PARAM_FLOAT ? "Float:" : "",n->name);
					while (paramcount--)
					{
						oldop=(ucell)stack_pop(pstack);
						switch(oldop)
						{
							case OP_PUSH_C:
							{
								p=stack_pop_safe(ps);
								oldparam=(ucell)stack_pop(pstack);
								if (p==NULL)
								{
									goto not_displaying;
								}
								if (p==NULL || p->type==PARAM_BYVAL) /* Constant number. */
								{
									if (p->tag==PARAM_FLOAT)
									{
										snprintf(Temp,sizeof(Temp)-1,"%f",*(float *)&oldparam);
									}
									else
									{
										snprintf(Temp,sizeof(Temp)-1,"%d",oldparam);
									}
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								else if (p->dimensions > 0) /* Array in the DAT section, PROBABLY a string */
								{
									GetShortVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
									if (progopts.cleannatives && Temp[0]!=0)
									{
										strncat(Comment,Temp,sizeof(Comment)-1);
									}
									else
									{
										GetVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
										if (Temp[0]!=0)
										{
											strncat(Comment,Temp,sizeof(Comment)-1);
											
											if (IsInDat(oldparam))
											{
												ReadDatString(oldparam,Temp,sizeof(Temp)-1);
												
												if (Temp[0]!=0)
												{
													strncat(Comment,"={",sizeof(Comment)-1);
													strncat(Comment,Temp,sizeof(Comment)-1);
													strncat(Comment,"}",sizeof(Comment)-1);
												}
											}
										}
										else if (IsInDat(oldparam))
										{
											ReadDatString(oldparam,Temp,sizeof(Temp)-1);
											strncat(Comment,Temp,sizeof(Comment)-1);
										}
									}
								}
								else if (p->type==PARAM_BYREF)
								{
									GetShortVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
									if (progopts.cleannatives && Temp[0]!=0)
									{
										strncat(Comment,Temp,sizeof(Comment)-1);
									}
									else
									{
										GetVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
										if (Temp[0]!=0)
										{
											strncat(Comment,Temp,sizeof(Comment)-1);
											if (IsInDat(oldparam))
											{
												snprintf(Temp,sizeof(Temp)-1,"%d",ReadDatUCell(oldparam));
												strncat(Comment,"=",sizeof(Comment)-1);
												strncat(Comment,Temp,sizeof(Comment)-1);
											}
										}
										else if (IsInDat(oldparam))
										{
											snprintf(Temp,sizeof(Temp)-1,"%d",ReadDatUCell(oldparam));
											strncat(Comment,Temp,sizeof(Comment)-1);
										}
									}
								}
								else if (p->type==PARAM_VARARG)
								{
									GetShortVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
									if (progopts.cleannatives && Temp[0]!=0)
									{
										strncat(Comment,Temp,sizeof(Comment)-1);
									}
									else
									{
										GetVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
										/*printf("vararg! temp[0]=%d isindat=%d\n",Temp[0],IsInDat(oldparam));*/
										if (Temp[0]!=0)
										{
											strncat(Comment,Temp,sizeof(Comment)-1);
											if (IsInDat(oldparam))
											{
												ReadDatString(oldparam,Temp,sizeof(Temp)-1);
												
												if (Temp[0]!=0)
												{
													strncat(Comment,"={",sizeof(Comment)-1);
													strncat(Comment,Temp,sizeof(Comment)-1);
													strncat(Comment,"}",sizeof(Comment)-1);
												}
											}
										}
										else if (IsInDat(oldparam))
										{
											ReadDatString(oldparam,Temp,sizeof(Temp)-1);
											strncat(Comment,Temp,sizeof(Comment)-1);
										}
									}
								}
								break;
							}
							
							case OP_PUSH_S:
							{
								p=stack_pop_safe(ps);
								oldparam=(ucell)stack_pop(pstack);
								/* This is a variable on the call stack */
								GetShortVariableNameByFrameOffset(_addr-4,oldparam,Temp,sizeof(Temp)-1);
								if (progopts.cleannatives && Temp[0]!=0)
								{
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								else
								{
									GetVariableNameByFrameOffset(_addr-4,oldparam,Temp,sizeof(Temp)-1);
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								
								break;
							}
							case OP_PUSHADDR:
							{
								p=stack_pop_safe(ps);
								oldparam=(ucell)stack_pop(pstack);
								/* This is a variable on the stack */
								GetShortVariableNameByFrameOffset(_addr-4,oldparam,Temp,sizeof(Temp)-1);
								if (progopts.cleannatives && Temp[0]!=0)
								{
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								else
								{
									GetVariableNameByFrameOffset(_addr-4,oldparam,Temp,sizeof(Temp)-1);
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								
								break;
							}
							case OP_PUSH:
							{
								p=stack_pop_safe(ps);
								oldparam=(ucell)stack_pop(pstack);
								/* This is a variable in the dat section. */
								GetShortVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
								if (progopts.cleannatives && Temp[0]!=0)
								{
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								else
								{
									GetVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
									strncat(Comment,Temp,sizeof(Comment)-1);
								}
								
								break;
							}
							/*
0x11B0                CONST.pri  0x1DDAC
0x11B8                     HEAP  0x4
0x11C0                     MOVS  0x4
0x11C8                 PUSH.alt
							 */
							/* Copy the stack and scan it to see if the syntax looks similar to above.
							 * Looking for:
							 * OP_PUSH_ALT (checked here)
							 * OP_MOVS 0x4
							 * OP_HEAP 0x4
							 * OP_CONST_PRI <addr>
							 */
							case OP_PUSH_ALT:
							{
								p=stack_pop_safe(ps);
								stack_t *pstackcopy=stack_copy(pstack);
								ucell    stackcopyop;
								
								if ((ucell)stack_pop(pstackcopy)!=OP_MOVS)
								{
									goto not_displaying;
								}
								if ((ucell)stack_pop(pstackcopy)!=0x4)
								{
									goto not_displaying;
								}
								if ((ucell)stack_pop(pstackcopy)!=OP_HEAP)
								{
									goto not_displaying;
								}
								if ((ucell)stack_pop(pstackcopy)!=0x4)
								{
									goto not_displaying;
								}
								if ((ucell)stack_pop(pstackcopy)!=OP_CONST_PRI)
								{
									goto not_displaying;
								}
								
								/* This is recognized. */
								
								/* Pop the original stack a few times to align it. */
								stack_pop(ps);
								stack_pop(ps);

								stack_pop(ps);
								stack_pop(ps);

								stack_pop(ps);
								stack_pop(ps);
								
								stackcopyop=(ucell)stack_pop(pstackcopy);
								
								
								
								stack_destroy(pstackcopy);
								
								if (p->dimensions > 0) /* Array in the DAT section, PROBABLY a string */
								{
									GetShortVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
									if (progopts.cleannatives && Temp[0]!=0)
									{
										strncat(Comment,Temp,sizeof(Comment)-1);
									}
									else
									{
										GetVariableNameByAddress(stackcopyop,Temp,sizeof(Temp)-1);
										if (Temp[0]!=0)
										{
											strncat(Comment,Temp,sizeof(Comment)-1);
											if (IsInDat(stackcopyop))
											{
												ReadDatString(stackcopyop,Temp,sizeof(Temp)-1);
												
												if (Temp[0]!=0)
												{
													strncat(Comment,"={",sizeof(Comment)-1);
													strncat(Comment,Temp,sizeof(Comment)-1);
													strncat(Comment,"}",sizeof(Comment)-1);
												}
											}
										}
										else if (IsInDat(stackcopyop))
										{
											ReadDatString(stackcopyop,Temp,sizeof(Temp)-1);
											strncat(Comment,Temp,sizeof(Comment)-1);
										}
									}
								}
								else if (p->type==PARAM_BYREF)
								{
									GetShortVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
									if (progopts.cleannatives && Temp[0]!=0)
									{
										strncat(Comment,Temp,sizeof(Comment)-1);
									}
									else
									{
										GetVariableNameByAddress(stackcopyop,Temp,sizeof(Temp)-1);
										if (Temp[0]!=0)
										{
											strncat(Comment,Temp,sizeof(Comment)-1);
											if (IsInDat(stackcopyop))
											{
												snprintf(Temp,sizeof(Temp)-1,"%d",ReadDatUCell(stackcopyop));
												strncat(Comment,"=",sizeof(Comment)-1);
												strncat(Comment,Temp,sizeof(Comment)-1);
											}
										}
										else if (IsInDat(stackcopyop))
										{
											snprintf(Temp,sizeof(Temp)-1,"%d",ReadDatUCell(stackcopyop));
											strncat(Comment,Temp,sizeof(Comment)-1);
										}
									}
								}
								else if (p->type==PARAM_VARARG)
								{
									GetShortVariableNameByAddress(oldparam,Temp,sizeof(Temp)-1);
									if (progopts.cleannatives && Temp[0]!=0)
									{
										strncat(Comment,Temp,sizeof(Comment)-1);
									}
									else
									{
										GetVariableNameByAddress(stackcopyop,Temp,sizeof(Temp)-1);
										if (Temp[0]!=0)
										{
											strncat(Comment,Temp,sizeof(Comment)-1);
											if (IsInDat(stackcopyop))
											{
												ReadDatString(stackcopyop,Temp,sizeof(Temp)-1);
												
												if (Temp[0]!=0)
												{
													strncat(Comment,"={",sizeof(Comment)-1);
													strncat(Comment,Temp,sizeof(Comment)-1);
													strncat(Comment,"}",sizeof(Comment)-1);
												}
											}
										}
										else if (IsInDat(stackcopyop))
										{
											ReadDatString(stackcopyop,Temp,sizeof(Temp)-1);
											strncat(Comment,Temp,sizeof(Comment)-1);
										}
									}
								}
								
								break;
							}
							
						
							default:
							{
								goto not_displaying;
							}
						}
						if (paramcount!=0)
						{
							strncat(Comment,",",sizeof(Comment)-1);
						}
					}
					strncat(Comment,")",sizeof(Comment)-1);
					
				}
				PrintComment(Comment);
				goto already_displayed;
				
				
			/* If we jumped here, then there was an unrecoverable issue with displaying the native info.  Just show the normal native. */
			not_displaying:
				GetNativeNameByIndex(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
			/* If we jump here, then we have displayed the full native info already. */
			already_displayed:

				/* If we're searching for a native, then check this. */
				/* SearchForNative is the native index. */
				if (SearchForNative!=0xFFFFFFFF)
				{
					if (SearchForNative==param)
					{
						snprintf(buff,sizeof(buff)-1,"0x%X",_addr-8);
						printf("%-10s %s\n",progopts.hideaddresses == 1 ? "" : buff, CurrentFunction[0] == '\0' ? "Unknown" : CurrentFunction);
					}
				}
				break;
			}
			/* CIP = pri */
			case OP_JUMP_PRI:
			{
				PrintOpCode("JUMP.pri");
				
				break;
			}
			/* Compare PRI to the value of the passed casetbl, jump accordingly. */
			case OP_SWITCH:
			{
				PrintOpCode("SWITCH");
				param=GetParam();
				PrintParamHex(param);
				
				if (labeljumps)
				{
					make_label(param,LABEL_SWITCH,0,0,_addr-8);
				}
				else if (jumplist!=NULL)
				{
					_addr-=8;
					list_iterate(jumplist,check_label,&_addr);
					_addr+=8;
				}
				
				break;
			}
			case OP_CASETBL:
			{
				PrintOpCode("CASETBL");
				/*
				Every record in a case table, except the first, contains a case value and a jump
address, in that order. The first record keeps the number of subsequent records
in the case table in its first cell and the “none-matched” jump address in its
second cell. If none of the case values of the subsequent records matches pri, the
switch instruction jumps to this “none-matched” address. Note again that the
first record is excluded in the “number of records” field in the first record.
The records in the case table are sorted on their value. An abstract machine may
take advantage of this lay-out to search through the table with a binary search.
				*/
				
				cell NumberOfJumps=GetParam();
				cell NoneFound=GetParam();
				cell CaseValue;
				cell CaseJump;
				/* CASETBL is special for the target labels because it iterates it's own made up
				 * op code list (CASE{,NONE,JUMP}).  So handle label targets here for CASETBL
				 */
				if (jumplist!=NULL)
				{
					list_iterate(jumplist,check_target,&oldaddr);
				}
				oldaddr++; /* Make it pretend it's not on CASETBL exactly for the next oldaddr check */

				endl();
				PrintOpCode("CASENONE");
				PrintParamHex(NoneFound);
				PrintComment("default");
				
				if (labeljumps)
				{
					make_label(NoneFound,LABEL_CASE,0xFFFFFFFF,1,_addr);
				}
				else if (jumplist!=NULL)
				{
					list_iterate(jumplist,check_label,&_addr);
				}
				
				endl();
				while (NumberOfJumps--)
				{
					CaseValue=GetParam();
					
					PrintOpCode("CASE");
					PrintParamHex(CaseValue);
					endl();
					
					CaseJump=GetParam();
					PrintOpCode("CASEJUMP");
					PrintParamHex(CaseJump);
					if (labeljumps)
					{
						make_label(CaseJump,LABEL_CASE,CaseValue,0,_addr);
					}
					else if (jumplist!=NULL)
					{
						list_iterate(jumplist,check_label,&_addr);
					}
				
					endl();
					
				}
				_addr-=4;
				PrintComment("End of CASETBL");
				make_label(_addr,LABEL_ENDCASE,0,0,_addr);
				_addr+=4;
				
				break;
				
			}
			
			/* [STK] = PRI; PRI = old [STK] */
			case OP_SWAP_PRI:
			{
				PrintOpCode("SWAP.pri");
				
				break;
			}
			/* [STK] = ALT; ALT = old [STK] */
			case OP_SWAP_ALT:
			{
				PrintOpCode("SWAP.alt");
				
				break;
			}
			/* [STK] = FRM + param; STK-=sizeofcell; */
			case OP_PUSHADDR:
			{
				PrintOpCode("PUSH.ADR");
				
				param=GetParam();
				PrintParamHex(param);
				
				GetVariableNameByFrameOffset(_addr-4,param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				break;
			}
			/* No Operation */
			case OP_NOP:
			{
				PrintOpCode("NOP");
				
				break;
			}
			/* Breakpoint */
			case OP_BREAK:
			{
				PrintOpCode("BREAK");
				
				if (progopts.showlines)
				{
					GetLineComment(_addr-4,Comment,sizeof(Comment)-1);
					PrintComment(Comment);
				}
				break;
			}
			/* 2 PUSH.Cs */
			/* TODO: Symbols? */
			case OP_PUSH2_C:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH2.C");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
				
			}
			/* 2 PUSHs */
			/* TODO: Symbols? */
			case OP_PUSH2:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH2");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 2 PUSH.Ss */
			/* TODO: Symbols? */
			case OP_PUSH2_S:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH2.S");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 2 PUSH.ADRs */
			/* TODO: Symbols? */
			case OP_PUSH2_ADR:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH2.ADDR");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());

				break;
			}
			/* 3 PUSH.Cs */
			/* TODO: Symbols? */
			case OP_PUSH3_C:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH3.C");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 3 PUSHs */
			/* TODO: Symbols? */
			case OP_PUSH3:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH3");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 3 PUSH.Ss */
			/* TODO: Symbols? */
			case OP_PUSH3_S:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH3.S");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 3 PUSH.ADRs */
			/* TODO: Symbols? */
			case OP_PUSH3_ADR:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH3.ADDR");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());

				break;
			}
			/* 4 PUSH.Cs */
			/* TODO: Symbols? */
			case OP_PUSH4_C:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH4.C");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 4 PUSHs */
			/* TODO: Symbols? */
			case OP_PUSH4:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH4");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 4 PUSH.Ss */
			/* TODO: Symbols? */
			case OP_PUSH4_S:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH4.S");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 4 PUSH.ADRs */
			/* TODO: Symbols? */
			case OP_PUSH4_ADR:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH4.ADDR");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());

				break;
			}
			/* 5 PUSH.Cs */
			/* TODO: Symbols? */
			case OP_PUSH5_C:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH5.C");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 5 PUSHs */
			/* TODO: Symbols? */
			case OP_PUSH5:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH5");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 5 PUSH.Ss */
			/* TODO: Symbols? */
			case OP_PUSH5_S:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH5.S");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				
				break;
			}
			/* 5 PUSH.ADRs */
			/* TODO: Symbols? */
			case OP_PUSH5_ADR:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("PUSH5.ADDR");
				
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());
				PrintParamHex(GetParam());

				break;
			}

			/* SYSREQ.N addr num 
			 * PUSH.C num
			 * SYSREQ.C ADDR
			 * STACK num+4
			 */
			/* TODO: Symbols */
			case OP_SYSREQ_D: /* This is SYSREQ.N on SourceMod */
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				
				PrintOpCode("SYSREQ.N");
				
				param=GetParam();
				PrintParamHex(param);
				PrintParamHex(GetParam());

				GetNativeNameByIndex(param,Comment,sizeof(Comment)-1);
				PrintComment(Comment);
				
				/* If we're searching for a native, then check this. */
				/* SearchForNative is the native index. */
				if (SearchForNative!=0xFFFFFFFF)
				{
					if (SearchForNative==param)
					{
						snprintf(buff,sizeof(buff)-1,"0x%X",_addr-8);
						printf("%-10s %s\n",progopts.hideaddresses == 1 ? "" : buff, CurrentFunction[0] == '\0' ? "Unknown" : CurrentFunction);
					}
				}
				
				break;
			}
			/* pri=[addr1] alt=[addr2] */
			/* todo: symbols*/
			case OP_LOAD_BOTH:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("LOAD.both");
				param=GetParam();
				paramb=GetParam();
				
				PrintParamHex(param);
				PrintParamHex(paramb);
				
				
				break;
			}
			/* pri=[frm+addr1] alt=[frm+addr2] */
			/* todo: symbols*/
			case OP_LOAD_S_BOTH:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("LOAD.S.both");
				param=GetParam();
				paramb=GetParam();
				
				PrintParamHex(param);
				PrintParamHex(paramb);
				
				
				break;
			}
			/* [param]=paramb */
			/* todo: symbols */
			case OP_CONST:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("CONST");
				param=GetParam();
				paramb=GetParam();
				PrintParamHex(param);
				PrintParamHex(paramb);
				
				break;
			}
			/* [frm + param]=paramb */
			/* todo: symbols */
			case OP_CONST_S:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("CONST.S");
				param=GetParam();
				paramb=GetParam();
				PrintParamHex(param);
				PrintParamHex(paramb);
				
				break;
			}
			/*
			  OP_TRACKER_PUSH_C,
  OP_TRACKER_POP_SETHEAP,
  OP_GENARRAY,
  OP_GENARRAY_Z,
			*/
			
			/* [TRACKER] = val, TRACKER++ */
			case OP_TRACKER_PUSH_C:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("TRACKER.PUSH.C");
				PrintParamHex(GetParam());
				
				break;
			}
			/* TRACKER--, HEA -= [TRACKER] */
			case OP_TRACKER_POP_SETHEAP:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("TRACKER.POP.SETHEAP");
				
				break;
			}
			/* param=dimensions */
			case OP_GENARRAY:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("GENARRAY");
				PrintParamHex(GetParam());
				
				break;
			}
			case OP_GENARRAY_Z:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("GENARRAY.Z");
				PrintParamHex(GetParam());
				
				break;
			}
			/* (PRI+4)>>2 */
			case OP_STRADJUST_PRI:
			{
				switch(header.type)
				{
					case FT_AMXX:
					{
						goto unknown_op;
					}
				}
				PrintOpCode("STRADJUST.pri");
				
				break;
			}
unknown_op:
			default:
			{
				char tempstr[128];
				
				snprintf(tempstr,sizeof(tempstr)-1,"UNKNOWN OP CODE: 0x%X",(int)op);
				PrintOpCode(tempstr);
			}
			
		}
	
	}
	
	endl();
}
