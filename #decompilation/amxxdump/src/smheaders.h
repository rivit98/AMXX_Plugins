#if !defined(SMHEADERS_H)
#define SMHEADERS_H

#include "types.h"

#if !defined(PACKED)
#	if defined(__GNUC__)
#		define PACKED __attribute__((packed))
#	else
#		define PACKED
#	endif
#endif

#if !defined(_FAR)
#	define _FAR
#endif

#define SPFILE_MAGIC	0x53504646		/**< Source Pawn File Format (SPFF) */
#define SPFILE_VERSION	0x0101			/**< Uncompressed bytecode */

//:TODO: better compiler/nix support
#if defined __linux__
	#pragma pack(1)         /* structures must be packed (byte-aligned) */
#else

	#pragma pack(push,1)
#endif


#define SPFILE_COMPRESSION_NONE		0		/**< No compression in file */
#define SPFILE_COMPRESSION_GZ		1		/**< GZ compression */

/**
 * @brief File section header format.
 */
typedef struct sp_file_section_s
{
	dword	nameoffs;	/**< Relative offset into global string table */
	dword	dataoffs;	/**< Offset into the data section of the file */
	dword	size;		/**< Size of the section's entry in the data section */
} sp_file_section_t;

/**
 * @brief File header format.  If compression is 0, then disksize may be 0 
 * to mean that only the imagesize is needed.
 */
typedef struct sp_file_hdr_s
{
	uint32_t	magic;		/**< Magic number */
	uint16_t	version;	/**< Version code */
	uint8_t		compression;/**< Compression algorithm */
	uint32_t	disksize;	/**< Size on disk */
	uint32_t	imagesize;	/**< Size in memory */
	uint8_t		sections;	/**< Number of sections */
	uint32_t	stringtab;	/**< Offset to string table */
	uint32_t	dataoffs;	/**< Offset to file proper (any compression starts here) */
} sp_file_hdr_t;

#define SP_FLAG_DEBUG	(1<<0)		/**< Debug information is present in the file */

/**
 * @brief File-encoded format of the ".code" section.
 */
typedef struct sp_file_code_s
{
	uint32_t	codesize;		/**< Codesize in bytes */
	uint8_t		cellsize;		/**< Cellsize in bytes */
	uint8_t		codeversion;	/**< Version of opcodes supported */
	uint16_t	flags;			/**< Flags */
	uint32_t	main;			/**< Address to "main," if any */
	uint32_t	code;			/**< Relative offset to code */
} sp_file_code_t;

/** 
 * @brief File-encoded format of the ".data" section.
 */
typedef struct sp_file_data_s
{
	uint32_t	datasize;		/**< Size of data section in memory */
	uint32_t	memsize;		/**< Total mem required (includes data) */
	uint32_t	data;			/**< File offset to data (helper) */
} sp_file_data_t;

/**
 * @brief File-encoded format of the ".publics" section.
 */
typedef struct sp_file_publics_s
{
	uint32_t	address;		/**< Address relative to code section */
	uint32_t	name;			/**< Index into nametable */
} sp_file_publics_t;

/**
 * @brief File-encoded format of the ".natives" section.
 */
typedef struct sp_file_natives_s
{
	uint32_t	name;			/**< Index into nametable */
} sp_file_natives_t;

/**
 * @brief File-encoded format of the ".pubvars" section.
 */
typedef struct sp_file_pubvars_s
{
	uint32_t	address;		/**< Address relative to the DAT section */
	uint32_t	name;			/**< Index into nametable */
} sp_file_pubvars_t;

#if defined __linux__
	#pragma pack()    /* reset default packing */
#else

	#pragma pack(pop) /* reset previous packing */
#endif


/**
 * @brief File-encoded debug information table.
 */
typedef struct sp_fdbg_info_s
{
	uint32_t	num_files;	/**< number of files */
	uint32_t	num_lines;	/**< number of lines */
	uint32_t	num_syms;	/**< number of symbols */
	uint32_t	num_arrays;	/**< number of symbols which are arrays */
} sp_fdbg_info_t;

/**
 * @brief File-encoded debug file table.
 */
typedef struct sp_fdbg_file_s
{
	uint32_t	addr;		/**< Address into code */
	uint32_t	name;		/**< Offset into debug nametable */
} sp_fdbg_file_t;

/**
 * @brief File-encoded debug line table.
 */
typedef struct sp_fdbg_line_s
{
	uint32_t	addr;		/**< Address into code */
	uint32_t	line;		/**< Line number */
} sp_fdbg_line_t;

#define SP_SYM_VARIABLE  1  /**< Cell that has an address and that can be fetched directly (lvalue) */
#define SP_SYM_REFERENCE 2  /**< VARIABLE, but must be dereferenced */
#define SP_SYM_ARRAY     3	/**< Symbol is an array */
#define SP_SYM_REFARRAY  4  /**< An array passed by reference (i.e. a pointer) */
#define SP_SYM_FUNCTION	 9  /**< Symbol is a function */

/**
 * @brief File-encoded debug symbol information.
 */
typedef struct sp_fdbg_symbol_s
{
	int32_t		addr;		/**< Address rel to DAT or stack frame */
	int16_t		tagid;		/**< Tag id */
	uint32_t	codestart;	/**< Start scope validity in code */
	uint32_t	codeend;	/**< End scope validity in code */
	uint8_t		ident;		/**< Variable type */
	uint8_t		vclass;		/**< Scope class (local vs global) */
	uint16_t	dimcount;	/**< Dimension count (for arrays) */
	uint32_t	name;		/**< Offset into debug nametable */
} sp_fdbg_symbol_t;

/**
 * @brief File-encoded debug symbol array dimension info.
 */
typedef struct sp_fdbg_arraydim_s
{
	int16_t		tagid;		/**< Tag id */
	uint32_t	size;		/**< Size of dimension */
} sp_fdbg_arraydim_t;

/** Typedef for .names table */
typedef char * sp_file_nametab_t;


/**
 * @brief Information about the core plugin tables.  These may or may not be present!
 */
typedef struct sp_plugin_infotab_s
{
	const char *stringbase;		/**< base of string table */
	uint32_t	publics_num;	/**< number of publics */
	sp_file_publics_t *publics;	/**< public table */
	uint32_t	natives_num;	/**< number of natives */
	sp_file_natives_t *natives; /**< native table */
	uint32_t	pubvars_num;	/**< number of pubvars */
	sp_file_pubvars_t *pubvars;	/**< pubvars table */
} sp_plugin_infotab_t;

/**
 * @brief Information about the plugin's debug tables.  These are all present if one is present.
 */
typedef struct sp_plugin_debug_s
{
	const char *stringbase;		/**< base of string table */
	uint32_t	files_num;		/**< number of files */
	sp_fdbg_file_t *files;		/**< files table */
	uint32_t	lines_num;		/**< number of lines */
	sp_fdbg_line_t *lines;		/**< lines table */
	uint32_t	syms_num;		/**< number of symbols */
	sp_fdbg_symbol_t *symbols;	/**< symbol table */
} sp_plugin_debug_t;

#define SP_FA_SELF_EXTERNAL		(1<<0)		/**< Allocation of structure is external */
#define SP_FA_BASE_EXTERNAL		(1<<1)		/**< Allocation of base is external */

/**
 * @brief The rebased memory format of a plugin.  This differs from the on-disk structure 
 * to ensure that the format is properly read.
 */
typedef struct sp_plugin_s
{
	uint8_t		*base;			/**< Base of memory for this plugin. */
	uint8_t		*pcode;			/**< P-Code of plugin */
	uint32_t	pcode_size;		/**< Size of p-code */
	uint8_t		*data;			/**< Data/memory layout */
	uint32_t	data_size;		/**< Size of data */
	uint32_t	memory;			/**< Required memory space */
	uint16_t	flags;			/**< Code flags */
	uint32_t	allocflags;		/**< Allocation flags */
	sp_plugin_infotab_t info;	/**< Base info table */
	sp_plugin_debug_t   debug;	/**< Debug info table */
} sp_plugin_t;




#endif
