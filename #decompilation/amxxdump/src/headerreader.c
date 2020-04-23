#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>

#include "list.h"
#include "stack.h"

#include "headerreader.h"

stack_t		*filestoread;
stack_t		*filesread;
list_t		*natives;
int 		 inquotes=0;
int 		 incomment=0;
char 		*rawbuffer;
static void StripLeadingWhiteSpace(char **c);
static void StripTrailingWhiteSpace(char *c);
char		*gfile;
int			 line;

char *amxx_headers[] = 
{
	"amxmodx.inc",
	"core.inc",
	"csstats.inc",
	"cstrike.inc",
	"csx.inc",
	"dbi.inc",
	"dodfun.inc",
	"dodstats.inc",
	"dodx.inc",
	"engine.inc",
	"esf.inc",
	"fakemeta.inc",
	"file.inc",
	"float.inc",
	"fun.inc",
	"geoip.inc",
	"lang.inc",
	"messages.inc",
	"ns.inc",
	"nvault.inc",
	"regex.inc",
	"sockets.inc",
	"sorting.inc",
	"sqlx.inc",
	"string.inc",
	"tfcx.inc",
	"time.inc",
	"tsfun.inc",
	"tsx.inc",
	"vault.inc",
	"vector.inc",
	"tsstats.inc",
	NULL
};
#if !defined(NDEBUG)
void PrintNativeData(native_t *n)
{
	printf("       name: %s\n",n->name);
	printf("        tag: %d\n",n->tag);
	printf("param count: %d\n",n->paramcount);
	printf("     vararg: %d\n",n->vararg);
	
	stack_t *s=stack_copy(n->params);
	
	parameter_t *p;
	while (!stack_isempty(s))
	{
		p=stack_pop(s);
		printf(" param %s:\n",p->name);
		printf("            tag: %d\n",p->tag);
		printf("           type: %d\n",p->type);
		printf("           dims: %d\n",p->dimensions);
		printf("      dim sizes: {%d,%d,%d}\n",p->dimsizes[0],p->dimsizes[1],p->dimsizes[2]);
	}
}
#endif

#define GT_SET(VALUE) do { stack_push(gtstack,gt); gt=&&VALUE; } while(0)
#define GT_RESTORE() 				\
do									\
{									\
	if (stack_isempty(gtstack))		\
	{								\
		gt=&&jump_readnormal;		\
	}								\
	else							\
	{								\
		gt=stack_pop(gtstack);		\
	}								\
} while(0)


#define sWARNING	0
#define sERROR		1
#define sFATAL		2
static void ExpectedError(const char *a, const char *b, int severity)
{
	fprintf(stderr,"%s:%d: %s: expected %s; got %s\n",gfile,line,severity==sWARNING ? "Warning" : severity==sERROR ? "Error:" : "Fatal Error", a,b);
	fflush(stderr);
	
	if (severity != sWARNING && severity != sERROR)
	{
		fprintf(stderr,"%s:%d: Fatal error, cannot continue.\n",gfile,line);
		fflush(stderr);
		exit(1);
	}
}
static void StripLeadingWhiteSpace(char **c)
{
	char		*currentposition=*c;
	
	while (	*currentposition=='\t' ||
			*currentposition==' ')
	{
		++currentposition;
	}
	*c=currentposition;
}
static void StripTrailingWhiteSpace(char *c)
{
	char		*start=c;
	c+=strlen(c);
	
	while ((*c=='\t'	||
			*c==' '		||
			*c=='\n'	||
			*c=='\r')	&&
			c>=start)
	{
		*c='\0';
		c--;
	}
}

void ParseParamData(parameter_t *p, const char *t)
{
	char 		*cur=p->name;
	int 		 size=0;
	char		 name[64];
	
	p->tag=PARAM_UNKNOWN;
	if (strcmp(t,"Float")==0)
	{
		p->tag=PARAM_FLOAT;
	}
	
	if (strncmp(p->name,"...",3)==0)
	{
		p->type=PARAM_VARARG;
		return;
	}
	while (*cur!='\0')
	{
		/* At the start of a dimension. */
		if (*cur=='[')
		{
			cur++;
			size=atoi(cur);
			
			if (p->dimensions>=3)
			{
				fprintf(stderr,"%s:%d: Over 3 dimensions in variable %s\n",gfile,line,p->name);
				fflush(stderr);
				exit(1);
			}
			p->dimsizes[p->dimensions++]=size;
		
		}
		
		cur++;
	}
	
	p->type=PARAM_BYVAL;
	if (p->name[0]=='&')
	{
		strncpy(name,(p->name) + 1,sizeof(name)-1);
		strncpy(p->name,name,sizeof(p->name)-1);
		p->type=PARAM_BYREF;
	}
	if (p->dimensions > 0)
	{
		p->type=PARAM_BYREF;
	}
	
}
void ParseStrippedData(const char *file)
{
	FILE			*input;
	char			 buffer[8192];
	char			*c;
	char			*start;
	char			*a;
	char			 tag[128];
	char			 ptag[128];
	char			 name[128];
	native_t		*curnative;
	parameter_t		*curparam;
	int				 endnow;
	int				 isequal;
	
	gfile=(char *)file;
	line=0;
	
	input=fopen(file,"r");
	
	if (!input)
	{
		fprintf(stderr,"Cannot open %s for reading.\n",file);
		fflush(stderr);
		exit(1);
	}
	
	while (!feof(input))
	{
		if (feof(input))
		{
			break;
		}
		
		buffer[0]=0;
		fgets(buffer,sizeof(buffer)-1,input);
		
		c=&buffer[0];

		StripLeadingWhiteSpace(&c);
		StripTrailingWhiteSpace(c);
		
		if (strncmp(c,"native",6/*strlen("native")*/)==0)
		{
			c+=7/*strlen("native ")*/;
			
			goto jump_readnative;
		}
		if (*c=='#')
		{
			goto jump_readdirective;
		}
		/* Don't care about this line */
		continue;
jump_readnative:	

		tag[0]=0;
		name[0]=0;
		StripLeadingWhiteSpace(&c);
		
		start=c;
		
		/* Scan up until the ( */
		while (*c!='\0'&&*c!='(')
		{
			c++;
		}
		
		if (*c=='\0')
		{
			ExpectedError("(","-end of line-",sFATAL);
		}
		
		a=start;

		/* Extract tag name, if appicable. */
		while (a<c)
		{
			if (*a==':')
			{
				*a='\0';
				strncpy(tag,start,sizeof(tag)-1);
				start=a+1;
				break;
			}
			a++;
		}
		
		StripLeadingWhiteSpace(&start);
		
		/* Allocate our native struct for this. */
		curnative=(native_t *)malloc(sizeof(native_t));
		memset(curnative,0x0,sizeof(native_t));
		
		*c='\0';
		c++;
		/* Get the native name. */
		strncpy(curnative->name,start,sizeof(curnative->name)-1);

		if (strcmp(tag,"Float")==0)
		{
			curnative->tag=PARAM_FLOAT;
		}
	
		/* Create our parameter stack. */
		curnative->params=stack_create(8);
	
		endnow=0;
		while (!endnow)
		{
			start=c;
	
			int multitag=0;
			isequal=0;

			/* Scan up to the end of the parameter name */
			while (*c!=',' && *c!='\0' && *c!=')' && *c!='=' && *c!='{')
			{
				c++;
			}
			if (*c=='\0')
			{
				ExpectedError(")", "-end of line-",sFATAL);
			}
			if (*c=='{')
			{
				multitag=1;
				while (*c!=':' && *c)
				{
					c++;
				}
				c++;
				start=c;
				
				while (*c!='\0' && *c!=',' && *c!='=' && *c!=')')
				{
					c++;
				}
				if (*c=='\0')
				{
					ExpectedError(")","-end of line-",sFATAL);
				}
			}
			if (*c==')')
			{
				endnow=1;
			}
			if (*c=='=')
			{
				isequal=1;
			}
			*c='\0';
			
			
			
			StripLeadingWhiteSpace(&start);
			
			/* There are no parameters! */
			if (strlen(start)<1)
			{
				break;
			}
			
			if (strncmp(start,"const ",6)==0)
			{
				start+=6;
				StripLeadingWhiteSpace(&c);
			}
			
			curparam=(parameter_t *)malloc(sizeof(parameter_t));
			memset(curparam,0x0,sizeof(parameter_t));
			
			a=start;
			ptag[0]=0;
			
			/* Get the tag */
			while (a<c)
			{
				if (*a==':')
				{
					*a++='\0';
					strncpy(ptag,start,sizeof(ptag)-1);
					start=a;
					break;
				}
				a++;
			}
			
			/* Get the name */
			*c='\0';
			
			strncpy(curparam->name,start,sizeof(curparam->name)-1);
			
			ParseParamData(curparam,ptag);
			
			if (strncmp(start,"...",3)==0)
			{
				curnative->vararg=1;
			}
			c++;
			
			/* If this parameter has a default value after it, skip over the value. */
			if (isequal)
			{
				while (*c!='\0' && *c!=',' && *c!=')')
				{
					c++;
				}
				
				if (*c=='\0')
				{
					ExpectedError(")","-end of file-",sFATAL);
				}
				if (*c==')')
				{
					endnow=1;
				}
				c++;
			}
			
			stack_push(curnative->params,curparam);
			curnative->paramcount++;
		}
		list_add(curnative,natives);
		
		
jump_readdirective:
		continue;
	}
	
}

void ParseFile(const char *file)
{
	FILE 			*input;
	FILE			*output;
	char			*outputfilename;
	size_t			 namesize;
	char			 buffer[8192];
	char			*c;
	int				*gt=&&jump_readnormal;
	stack_t			*gtstack;
	
	
	gfile=(char *)file;
	line=0;
	
	gtstack=stack_create(32);
	
	namesize=strlen(file)+strlen(".temp")+2;
	
	outputfilename=(char *)malloc(namesize);
	
	namesize--;
	
	snprintf(outputfilename,namesize,"%s.temp",file);
	
	input=fopen(file,"r");
	output=fopen(outputfilename,"w");
	
	if (!input)
	{
		fprintf(stderr,"Cannot open file \"%s\" for reading.\n",file);
		fflush(stderr);
		
		if (output)
		{
			fclose(output);
		}
		
		free(outputfilename);
		
		exit(1);
	}
	if (!output)
	{
		fprintf(stderr,"Cannot open file \"%s\" for writing.\n",outputfilename);
		fflush(stderr);
		
		free(outputfilename);
		
		if (input)
		{
			fclose(input);
		}
		
		
		
		exit(1);
	}
	
	
	/* Strip all comments out of the file. */
	while (!feof(input))
	{
jump_reread:
		if (feof(input))
		{
			break;
		}
		buffer[0]=0;
		fgets(buffer,sizeof(buffer)-1,input);
		line++;
		c=&buffer[0];
		StripTrailingWhiteSpace(c);
		StripLeadingWhiteSpace(&c);
		
		goto *gt;
jump_readnormal:

		while (*c!='\0')
		{
			if (*c=='\'')
			{
				c++;
				goto jump_readapost;
			}
			else if (*c=='"')
			{
				c++;
				goto jump_readquote;
			}
			else if (*c=='/')
			{
				if (*(c+1)=='*')
				{
					*c++=' ';
					*c++=' ';
					
					GT_SET(jump_readcomment);
					goto jump_readcomment;
				}
				else if (*(c+1)=='/')
				{
					*c='\0';
					goto jump_write;
				}
			}
			c++;
		}
		goto jump_write;
		continue;
		
jump_readcomment:
		while (*c!='\0')
		{
			if (*c=='*')
			{
				if (*(c+1)=='/')
				{
					*c++=' ';
					*c++=' ';
					GT_RESTORE();
					goto *gt;
				}
			}
			*c++=' ';
		}
		continue;
		
jump_readapost:
		while (*c!='\0')
		{
			if (*c=='^')
			{
				c++;
				
				if (*c=='\0')
				{
					ExpectedError("-trailing apostrophe-","-end of line-",sFATAL);
				}
				c++;
			}
			if (*c=='\'')
			{
				c++;
				goto jump_readnormal;
			}
			
			c++;
			
		}
		ExpectedError("-trailing apostrophe-","-end of line-",sFATAL);
		continue;
		
jump_readquote:
		while (*c!='\0')
		{
			if (*c=='^')
			{
				c++;
				
				if (*c=='\0')
				{
					ExpectedError("-trailing quote-","-end of line-",sFATAL);
				}
				c++;
			}
			if (*c=='"')
			{
				c++;
				goto jump_readnormal;
			}
			
			c++;
			
		}
		ExpectedError("-trailing quote-","-end of line-",sFATAL);
		continue;
jump_write:
		c=&buffer[0];
		StripLeadingWhiteSpace(&c);
		StripTrailingWhiteSpace(c);
		
		if (strlen(c)>1)
		{
			fputs(c,output);
		}
		goto jump_reread;
	}
	
	fclose(output);
	
	fclose(input);
	
	stack_destroy(gtstack);
	
	ParseStrippedData(outputfilename);
	
	unlink(outputfilename);
	
	free(outputfilename);
	
}
int CheckNative(void *a, void *b)
{
	if (strcmp(((native_t *)a)->name,(char *)b)==0)
	{
		return 1;
	}
	return 0;
}
void LoadAMXXIncludes(char *path)
{
	int i=0;
	char buff[4096];
	char dir[2048];
	char *c;
	
	/* Get the path this binary was invoked from */
	c=path+strlen(path);
	while (c>path)
	{
		if (*c=='\\' || *c=='/')
		{
			break;
		}
		c--;
	}

	if (c==path)
	{
		strncpy(dir,".\\",sizeof(dir)-1);
	}
	else
	{
		strncpy(dir,path,c-path);
	}
	
	while(amxx_headers[i]!=NULL)
	{
#if defined __linux__
		snprintf(buff,sizeof(buff)-1,"%s/includes/amxmodx/%s",dir,amxx_headers[i++]);
#else
		snprintf(buff,sizeof(buff)-1,"%s\\includes\\amxmodx\\%s",dir,amxx_headers[i++]);
#endif
		ParseFile(buff);
	}
	
#if !defined(NDEBUG)
	native_t *native;
	
#define DEBUGNATIVE(NATIVE) if ((native=HEADER_FindNativeByName( NATIVE ))!=NULL) PrintNativeData(native)
	DEBUGNATIVE("register_plugin");
	DEBUGNATIVE("random_num");
	DEBUGNATIVE("random_float");
	DEBUGNATIVE("write_byte");
	DEBUGNATIVE("get_concmdsnum");
	DEBUGNATIVE("equali");
#endif
	
}
native_t *HEADER_FindNativeByName(const char *name)
{
	return list_iterate(natives,CheckNative,(void *)name);
}
