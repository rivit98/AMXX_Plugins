#if !defined(AMXHEADERS_H)
#define AMXHEADERS_H

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


typedef struct tagAMX_HEADER 
{
  dword 	size          PACKED; /* size of the "file" */
  word 		magic         PACKED; /* signature */
  byte		file_version;         /* file format version */
  byte		amx_version;          /* required version of the AMX */
  word		flags         PACKED;
  word		defsize       PACKED; /* size of a definition record */
  dword		cod           PACKED; /* initial value of COD - code block */
  dword		dat           PACKED; /* initial value of DAT - data block */
  dword		hea           PACKED; /* initial value of HEA - start of the heap */
  dword		stp           PACKED; /* initial value of STP - stack top */
  dword		cip           PACKED; /* initial value of CIP - the instruction pointer */
  dword		publics       PACKED; /* offset to the "public functions" table */
  dword		natives       PACKED; /* offset to the "native functions" table */
  dword		libraries     PACKED; /* offset to the table of libraries */
  dword		pubvars       PACKED; /* the "public variables" table */
  dword		tags          PACKED; /* the "public tagnames" table */
  dword		nametable     PACKED; /* name table */
} PACKED AMX_HEADER;

typedef struct tagFUNCSTUBNT {
  ucell address      PACKED;
  ucell nameofs      PACKED;
} PACKED AMX_FUNCSTUBNT;


typedef struct tagAMX_DBG_HDR {
  int32_t size          PACKED; /* size of the debug information chunk */
  uint16_t magic        PACKED; /* signature, must be 0xf1ef */
  char    file_version;         /* file format version */
  char    amx_version;          /* required version of the AMX */
  int16_t flags         PACKED; /* currently unused */
  int16_t files         PACKED; /* number of entries in the "file" table */
  int16_t lines         PACKED; /* number of entries in the "line" table */
  int16_t symbols       PACKED; /* number of entries in the "symbol" table */
  int16_t tags          PACKED; /* number of entries in the "tag" table */
  int16_t automatons    PACKED; /* number of entries in the "automaton" table */
  int16_t states        PACKED; /* number of entries in the "state" table */
} PACKED AMX_DBG_HDR;
#define AMX_DBG_MAGIC   0xf1ef

typedef struct tagAMX_DBG_FILE {
  ucell   address       PACKED; /* address in the code segment where generated code (for this file) starts */
  const char name[1];           /* ASCII string, zero-terminated */
} PACKED AMX_DBG_FILE;

typedef struct tagAMX_DBG_LINE {
  ucell   address       PACKED; /* address in the code segment where generated code (for this line) starts */
  int32_t line          PACKED; /* line number */
} PACKED AMX_DBG_LINE;

typedef struct tagAMX_DBG_SYMBOL {
  ucell   address       PACKED; /* address in the data segment or relative to the frame */
  int16_t tag           PACKED; /* tag for the symbol */
  ucell   codestart     PACKED; /* address in the code segment from which this symbol is valid (in scope) */
  ucell   codeend       PACKED; /* address in the code segment until which this symbol is valid (in scope) */
  char    ident;                /* kind of symbol (function/variable) */
  char    vclass;               /* class of symbol (global/local) */
  int16_t dim           PACKED; /* number of dimensions */
  const char name[1];           /* ASCII string, zero-terminated */
} PACKED AMX_DBG_SYMBOL;

typedef struct tagAMX_DBG_SYMDIM {
  int16_t tag           PACKED; /* tag for the array dimension */
  ucell   size          PACKED; /* size of the array dimension */
} PACKED AMX_DBG_SYMDIM;

typedef struct tagAMX_DBG_TAG {
  int16_t tag           PACKED; /* tag id */
  const char name[1];           /* ASCII string, zero-terminated */
} PACKED AMX_DBG_TAG;

typedef struct tagAMX_DBG_MACHINE {
  int16_t automaton     PACKED; /* automaton id */
  ucell address         PACKED; /* address of state variable */
  const char name[1];           /* ASCII string, zero-terminated */
} PACKED AMX_DBG_MACHINE;

typedef struct tagAMX_DBG_STATE {
  int16_t state         PACKED; /* state id */
  int16_t automaton     PACKED; /* automaton id */
  const char name[1];           /* ASCII string, zero-terminated */
} PACKED AMX_DBG_STATE;

typedef struct tagAMX_DBG {
  AMX_DBG_HDR     _FAR *hdr         PACKED; /* points to the AMX_DBG header */
  AMX_DBG_FILE    _FAR **filetbl    PACKED;
  AMX_DBG_LINE    _FAR *linetbl     PACKED;
  AMX_DBG_SYMBOL  _FAR **symboltbl  PACKED;
  AMX_DBG_TAG     _FAR **tagtbl     PACKED;
  AMX_DBG_MACHINE _FAR **automatontbl PACKED;
  AMX_DBG_STATE   _FAR **statetbl   PACKED;
} PACKED AMX_DBG;


#define USENAMETABLE(hdr) \
                        ((hdr)->defsize==sizeof(AMX_FUNCSTUBNT))
#define NUMENTRIES(hdr,field,nextfield) \
                        (unsigned)(((hdr)->nextfield - (hdr)->field) / (hdr)->defsize)
#define GETENTRY(hdr,table,index) \
                        (AMX_FUNCSTUB *)((unsigned char*)(hdr) + (unsigned)(hdr)->table + (unsigned)index*(hdr)->defsize)
#define GETENTRYNAME(hdr,entry) \
                        ( USENAMETABLE(hdr) \
                           ? (char *)((unsigned char*)(hdr) + (unsigned)((AMX_FUNCSTUBNT*)(entry))->nameofs) \
                           : ((AMX_FUNCSTUB*)(entry))->name )

#if !defined iVARIABLE
  #define iVARIABLE  1  /* cell that has an address and that can be fetched directly (lvalue) */
  #define iREFERENCE 2  /* iVARIABLE, but must be dereferenced */
  #define iARRAY     3
  #define iREFARRAY  4  /* an array passed by reference (i.e. a pointer) */
  #define iFUNCTN    9
#endif


typedef enum {
  OP_NONE,              /* invalid opcode */
  OP_LOAD_PRI,
  OP_LOAD_ALT,
  OP_LOAD_S_PRI,
  OP_LOAD_S_ALT,
  OP_LREF_PRI,
  OP_LREF_ALT,
  OP_LREF_S_PRI,
  OP_LREF_S_ALT,
  OP_LOAD_I,
  OP_LODB_I,
  OP_CONST_PRI,
  OP_CONST_ALT,
  OP_ADDR_PRI,
  OP_ADDR_ALT,
  OP_STOR_PRI,
  OP_STOR_ALT,
  OP_STOR_S_PRI,
  OP_STOR_S_ALT,
  OP_SREF_PRI,
  OP_SREF_ALT,
  OP_SREF_S_PRI,
  OP_SREF_S_ALT,
  OP_STOR_I,
  OP_STRB_I,
  OP_LIDX,
  OP_LIDX_B,
  OP_IDXADDR,
  OP_IDXADDR_B,
  OP_ALIGN_PRI,
  OP_ALIGN_ALT,
  OP_LCTRL,
  OP_SCTRL,
  OP_MOVE_PRI,
  OP_MOVE_ALT,
  OP_XCHG,
  OP_PUSH_PRI,
  OP_PUSH_ALT,
  OP_PUSH_R,
  OP_PUSH_C,
  OP_PUSH,
  OP_PUSH_S,
  OP_POP_PRI,
  OP_POP_ALT,
  OP_STACK,
  OP_HEAP,
  OP_PROC,
  OP_RET,
  OP_RETN,
  OP_CALL,
  OP_CALL_PRI,
  OP_JUMP,
  OP_JREL,
  OP_JZER,
  OP_JNZ,
  OP_JEQ,
  OP_JNEQ,
  OP_JLESS,
  OP_JLEQ,
  OP_JGRTR,
  OP_JGEQ,
  OP_JSLESS,
  OP_JSLEQ,
  OP_JSGRTR,
  OP_JSGEQ,
  OP_SHL,
  OP_SHR,
  OP_SSHR,
  OP_SHL_C_PRI,
  OP_SHL_C_ALT,
  OP_SHR_C_PRI,
  OP_SHR_C_ALT,
  OP_SMUL,
  OP_SDIV,
  OP_SDIV_ALT,
  OP_UMUL,
  OP_UDIV,
  OP_UDIV_ALT,
  OP_ADD,
  OP_SUB,
  OP_SUB_ALT,
  OP_AND,
  OP_OR,
  OP_XOR,
  OP_NOT,
  OP_NEG,
  OP_INVERT,
  OP_ADD_C,
  OP_SMUL_C,
  OP_ZERO_PRI,
  OP_ZERO_ALT,
  OP_ZERO,
  OP_ZERO_S,
  OP_SIGN_PRI,
  OP_SIGN_ALT,
  OP_EQ,
  OP_NEQ,
  OP_LESS,
  OP_LEQ,
  OP_GRTR,
  OP_GEQ,
  OP_SLESS,
  OP_SLEQ,
  OP_SGRTR,
  OP_SGEQ,
  OP_EQ_C_PRI,
  OP_EQ_C_ALT,
  OP_INC_PRI,
  OP_INC_ALT,
  OP_INC,
  OP_INC_S,
  OP_INC_I,
  OP_DEC_PRI,
  OP_DEC_ALT,
  OP_DEC,
  OP_DEC_S,
  OP_DEC_I,
  OP_MOVS,
  OP_CMPS,
  OP_FILL,
  OP_HALT,
  OP_BOUNDS,
  OP_SYSREQ_PRI,
  OP_SYSREQ_C,
  OP_FILE,    /* obsolete */
  OP_LINE,    /* obsolete */
  OP_SYMBOL,  /* obsolete */
  OP_SRANGE,  /* obsolete */
  OP_JUMP_PRI,
  OP_SWITCH,
  OP_CASETBL,
  OP_SWAP_PRI,
  OP_SWAP_ALT,
  OP_PUSHADDR,
  OP_NOP,
  OP_SYSREQ_D, /* OP_SYSREQ_N on SourceMod */
  OP_SYMTAG,  /* obsolete */
  OP_BREAK, /* End of AMXX op codes */
  OP_PUSH2_C,
  OP_PUSH2,
  OP_PUSH2_S,
  OP_PUSH2_ADR,
  OP_PUSH3_C,
  OP_PUSH3,
  OP_PUSH3_S,
  OP_PUSH3_ADR,
  OP_PUSH4_C,
  OP_PUSH4,
  OP_PUSH4_S,
  OP_PUSH4_ADR,
  OP_PUSH5_C,
  OP_PUSH5,
  OP_PUSH5_S,
  OP_PUSH5_ADR,
  OP_LOAD_BOTH,
  OP_LOAD_S_BOTH,
  OP_CONST,
  OP_CONST_S,
  /* ----- */
  OP_SYSREQ_D_SM,
  OP_SYSREQ_ND,
  /* ----- */
  OP_TRACKER_PUSH_C ,
  OP_TRACKER_POP_SETHEAP,
  OP_GENARRAY,
  OP_GENARRAY_Z,
  OP_STRADJUST_PRI,
  OP_NUM_OPCODES
} OPCODE;


#endif
