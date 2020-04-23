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


#include "zlib/zlib.h"

commonheader_t header;

static errorcode COMMON_AnalyzeData(void)
{
	char				*addr;
	sp_file_hdr_t		*sphdr;
	char				*addr2;
	int				 	 sectioncount;
	char				*name;
	sp_file_section_t	*section;
	
	switch(header.type)
	{
		case FT_AMXX:
		{
			addr=header.data;
			
			header.custom1=malloc(sizeof(AMX_HEADER));
			memcpy(header.custom1,header.data,sizeof(AMX_HEADER));
			
			addr+=AMXXHDR.size;
			
			header.custom2=malloc(sizeof(AMX_DBG));
			
			memset(header.custom2,0x0,sizeof(AMX_DBG));
			
			dbg_LoadInfo(header.custom2,addr);
			
			break;

		}
		case FT_SOURCEMOD:
		{
			/* SourceMod changes the data layout to be:
			   sp_file_hdr_t + sectionheader + uncompressed data
			 */
			addr=malloc(header.imagesize);
			
			/* store beginning for later reference */
			addr2=addr;
			/* Because I use a custom header, I need to manually copy in fields of this header. */
			sphdr=(sp_file_hdr_t *)addr;
			sphdr->magic=header.magic;
			sphdr->version=header.version;
			sphdr->compression=header.compression;
			sphdr->disksize=header.disksize;
			sphdr->imagesize=header.imagesize;
			sphdr->sections=header.sections;
			sphdr->stringtab=header.stringtab;
			sphdr->dataoffs=header.offs;
			
			/* now move up addr past the size of the header. */
			addr+=header.headersize;
			
			/* now copy in the section header */
			memcpy(addr,header.section,header.sectionsize);
			
			/* move up past the section size */
			addr+=header.sectionsize;
			
			/* copy the uncompressed data */
			memcpy(addr,header.data,header.imagesize - (header.sectionsize + header.headersize));
			
			/* free the old data fields */
			free(header.data);
			free(header.section);
			
			
			header.data=addr;
			
			
			header.custom1=malloc(sizeof(sp_plugin_t));
			
			memset(header.custom1, 0x0, sizeof(sp_plugin_t));
			header.section=(((char *)addr2)+header.headersize);
			
			section=(sp_file_section_t *)header.section;
			
			
			SMHDR.base=(unsigned char *)addr2;
			
			sectioncount=0;
			while(sectioncount++ < header.sections)
			{
				
				
				name=(char *)(SMHDR.base + header.stringtab + section->nameoffs);
				
				if (!(SMHDR.pcode) && !strcmp(name, ".code"))
				{
					sp_file_code_t *cod = (sp_file_code_t *)(SMHDR.base + section->dataoffs);
					SMHDR.pcode = SMHDR.base + section->dataoffs + cod->code;
					SMHDR.pcode_size = cod->codesize;
					SMHDR.flags = cod->flags;
				}
				else if (!(SMHDR.data) && !strcmp(name, ".data"))
				{
					sp_file_data_t *dat = (sp_file_data_t *)(SMHDR.base + section->dataoffs);
					SMHDR.data = SMHDR.base + section->dataoffs + dat->data;
					SMHDR.data_size = dat->datasize;
					SMHDR.memory = dat->memsize;
				}
				else if (!(SMHDR.info.publics) && !strcmp(name, ".publics"))
				{
					SMHDR.info.publics_num = section->size / sizeof(sp_file_publics_t);
					SMHDR.info.publics = (sp_file_publics_t *)(SMHDR.base + section->dataoffs);
				}
				else if (!(SMHDR.info.pubvars) && !strcmp(name, ".pubvars"))
				{
					SMHDR.info.pubvars_num = section->size / sizeof(sp_file_pubvars_t);
					SMHDR.info.pubvars = (sp_file_pubvars_t *)(SMHDR.base + section->dataoffs);
				}
				else if (!(SMHDR.info.natives) && !strcmp(name, ".natives"))
				{
					SMHDR.info.natives_num = section->size / sizeof(sp_file_natives_t);
					SMHDR.info.natives = (sp_file_natives_t *)(SMHDR.base + section->dataoffs);
				}
				else if (!(SMHDR.info.stringbase) && !strcmp(name, ".names"))
				{
					SMHDR.info.stringbase = (const char *)(SMHDR.base + section->dataoffs);
				}
				else if (!(SMHDR.debug.files) && !strcmp(name, ".dbg.files"))
				{
					SMHDR.debug.files = (sp_fdbg_file_t *)(SMHDR.base + section->dataoffs);
				}
				else if (!(SMHDR.debug.lines) && !strcmp(name, ".dbg.lines"))
				{
					SMHDR.debug.lines = (sp_fdbg_line_t *)(SMHDR.base + section->dataoffs);
				}
				else if (!(SMHDR.debug.symbols) && !strcmp(name, ".dbg.symbols"))
				{
					SMHDR.debug.symbols = (sp_fdbg_symbol_t *)(SMHDR.base + section->dataoffs);
				}
				else if (!(SMHDR.debug.lines_num) && !strcmp(name, ".dbg.info"))
				{
					sp_fdbg_info_t *inf = (sp_fdbg_info_t *)(SMHDR.base + section->dataoffs);
					SMHDR.debug.files_num = inf->num_files;
					SMHDR.debug.lines_num = inf->num_lines;
					SMHDR.debug.syms_num = inf->num_syms;
				}
				else if (!(SMHDR.debug.stringbase) && !strcmp(name, ".dbg.strings"))
				{
					SMHDR.debug.stringbase = (const char *)(SMHDR.base + section->dataoffs);
				}
				else
				{
					printf("Stray header when loading SourceMod plugin: \"%s\"\n",name);
				}
				section++;
			}
		
			break;
		}
		default:
		{
			return ERR_BAD_TYPE;
		}
	};
	
	return ERR_NONE;
}

/**
 * Just a debug function to output the header data.
 */
#if !defined(NDEBUG)
static void COMMON_DumpHeaderData(void)
{
	printf("type            %s\n",header.type == FT_UNKNOWN ? "Unknown" : header.type == FT_AMXX ? "AMXX" : "SourceMod");
	printf("headersize      0x%X\n",(int)header.headersize);
	printf("magic           0x%X\n",(int)header.magic);
	printf("version         0x%X\n",(int)header.version);
	printf("compression     0x%X\n",(int)header.compression);
	printf("sections        0x%X\n",(int)header.sections);
	printf("cellsize        0x%X\n",(int)header.cellsize);
	printf("disksize        0x%X\n",(int)header.disksize);
	printf("imagesize       0x%X\n",(int)header.imagesize);
	printf("memsize         0x%X\n",(int)header.memsize);
	printf("stringtab       0x%X\n",(int)header.stringtab);
	printf("offs            0x%X\n",(int)header.offs);
}
#endif
/**
 * Generates a common header from the file pointer.  Unset fields will be set to 0.  Also calls the appropriate inflate routines.
 *
 * @param fp		FILE pointer of the plugin in question.
 */
static errorcode COMMON_ReadHeader(FILE *fp)
{

	memset(&header,0x0,sizeof(commonheader_t));
	rewind(fp);
	/* Universal first field is always the magic number as a dword. */
	READ_DWORD(fp,&(header.magic));
	

	switch(header.magic)
	{
		case 0x53504646:		/* SourceMod file. (Source Pawn File Format) */
		{
			READ_WORD(fp,&(header.version));
			READ_BYTE(fp,&(header.compression));
			READ_DWORD(fp,&(header.disksize));
			READ_DWORD(fp,&(header.imagesize));
			READ_BYTE(fp,&(header.sections));
			READ_DWORD(fp,&(header.stringtab));
			READ_DWORD(fp,&(header.offs));
			
			header.headersize= ftell(fp); 
			header.headersize=0x18;
			header.type=FT_SOURCEMOD;
			break;
		}
		case 0x414d5858:		/* AMX Mod X 1.5+ file */
		{
			READ_WORD(fp,&(header.version));
			READ_BYTE(fp,&(header.sections));
			READ_BYTE(fp,&(header.cellsize));
			READ_DWORD(fp,&(header.disksize));
			READ_DWORD(fp,&(header.imagesize));
			READ_DWORD(fp,&(header.memsize));
			READ_DWORD(fp,&(header.offs));
			
			header.headersize=ftell(fp);
			header.type=FT_AMXX;
			break;
		}
		case 0x414D5842:		/* AMX Mod X Pre-1.5 file. */
		{
			return ERR_OLD_AMXX_FILE;
		}

		default:
		{
			return ERR_UNKNOWN_MAGIC;
		}
	}
	
	/* It is assumed here that both amxmodx files AND sourcemod files are at the end of their header section. */
	/* Now load the actual plugin. */
	return ERR_NONE;
}
/**
 * Uncompresses the file (if applicable).
 * 
 * @param fp		FILE pointer to a file that just had it's header examined.
 */
static errorcode COMMON_UncompressFile(FILE *fp)
{
	void 			*Uncompressed;
	void			*Compressed;
	char			*Temp;
	size_t			 UncompressedSize;
	int				 Z_RES;
	size_t			 CompressedSize;
	

	/* Check if this needs to be decompressed. */
	if (header.type == FT_AMXX) /* AMXX Files are always compressed. */
	{
		/* This needs decompressed. (AMXX:gzip) */
		
		/* Allocate our two buffers. */
		CompressedSize=header.disksize+1;
		UncompressedSize=header.imagesize > header.memsize ? header.imagesize + 1 : header.memsize + 1;
		
		Compressed=malloc(CompressedSize);
		Uncompressed=malloc(UncompressedSize);
		
		
		
		/* Read compressed data. */
		fseek(fp,header.offs,SEEK_SET);
		fread(Compressed,CompressedSize,1,fp);
		
	
		fflush(stdout);
		/* Uncompress the data. */
		if ((Z_RES=uncompress((Bytef *)Uncompressed, (uLongf *)&UncompressedSize, (Bytef *)Compressed, CompressedSize))!=Z_OK)
		{
			/* Unexpected error. */
			fprintf(stderr,"Z_RES = %d!\n",Z_RES);
			fflush(stderr);
			
			return ERR_ZLIB;
		}
	
		/* Save uncompressed data. */
		header.data=Uncompressed;
		
		/* Free compressed data. */
		free(Compressed);
	}
	else if (header.type==FT_SOURCEMOD && header.compression == 1)
	{
		/* This needs decompressed. (SM:gzip) */
		/* Allocate our two buffers. */
		CompressedSize=header.disksize-header.offs;
		UncompressedSize=header.imagesize-header.offs;
		
		Compressed=malloc(CompressedSize);
		Uncompressed=malloc(UncompressedSize);
		
		/* Allocate our section header. */
		Temp=malloc(header.offs-header.headersize);
		header.sectionsize=(header.offs-header.headersize);
		
		/* Temp is the "section header" of the sourcepawn file. */
		/* fread the section header. */
		fread(Temp,header.offs-header.headersize,1,fp);
		
		/* Read compressed data. */
		fread(Compressed,CompressedSize,1,fp);
		
		
		/* Uncompress the data. */
		if ((Z_RES=uncompress((Bytef *)Uncompressed, (uLongf *)&UncompressedSize, (Bytef *)Compressed, CompressedSize))!=Z_OK)
		{
			/* Unexpected error. */
			fprintf(stderr,"Z_RES = %d!\n",Z_RES);
			fflush(stderr);
			
			return ERR_ZLIB;
		}
	
		/* Save uncompressed data. */
		header.data=Uncompressed;
		
		/* Save section header. */
		header.section=Temp;
		
		/* Free compressed data. */
		free(Compressed);
	}
	else
	{
		/* This does not need decompressed. */
	}
	
	return ERR_NONE;
}
errorcode COMMON_LoadFile(const char *name)
{
	FILE *fp=fopen(name,"rb");
	
	if (fp==NULL)
	{
		return ERR_FILEOPEN;
	}
	
	
	if ((Error=COMMON_ReadHeader(fp))!=ERR_NONE)
	{
		return Error;
	}
#if !defined(NDEBUG)
	COMMON_DumpHeaderData();
#endif
	
	if ((Error=COMMON_UncompressFile(fp))!=ERR_NONE)
	{
		return Error;
	}
	
	if ((Error=COMMON_AnalyzeData())!=ERR_NONE)
	{
		return Error;
	}

	
	fclose(fp);
	
	return ERR_NONE;
	
}
