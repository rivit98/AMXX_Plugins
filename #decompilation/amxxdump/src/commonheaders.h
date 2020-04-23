#if !defined(COMMONHEADERS_H)
#define COMMONHEADERS_H

#include "util.h"

#define FT_UNKNOWN		0
#define FT_AMXX			1
#define FT_SOURCEMOD	2

errorcode COMMON_LoadFile(const char *name);

/**
 * For AMX Mod X:
 *   custom1 = AMX_HEADER
 *   custom2 = AMX_DBG
 *
 * For SourceMod:
 *   custom1 = sp_plugin_t
 */
typedef struct commonheader_s
{
	dword 			 magic;				/* magic number */
	word	 		 version;			/* magic version */
	byte			 compression;		/* SM: compression algorithm */
	byte 			 sections;			/* how many plugins are in this package */
	byte 			 cellsize;			/* size of cells for this plugin, in bytes. */
	dword	 		 disksize;			/* compressed file size */
	dword 			 imagesize;			/* uncompressed file size */
	dword 			 memsize;			/* memory image size */
	dword			 stringtab;			/* SM: string table offset */
	dword			 sectionsize;		/* SM: size of the section header. */
	
	dword	 		 offs;				/* file offset */
	
	dword			 type;				/* File type (FT_AMXX, FT_SOURCEMOD) */
	dword			 headersize;		/* The size of this file header. */
	
	char			*data;				/* the uncompressed data after the initial header is read. */
	char			*section;			/* SM: Header for the sections. */
	void			*custom1;			/* Custom header for each file type. */
	void			*custom2;			/* Custom header for each file type. */

} commonheader_t;

extern commonheader_t header;

#define AMXXHDR	(*((AMX_HEADER 	*)(header.custom1)))
#define AMXXDBG	(*((AMX_DBG    	*)(header.custom2)))

#define SMHDR	(*((sp_plugin_t	*)(header.custom1)))



#endif
