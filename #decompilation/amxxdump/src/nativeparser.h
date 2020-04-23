#if !defined(NATIVEPARSER_H)
#define NATIVEPARSER_H

/* "Unknown" will be displayed as an integer. */
#define TAG_UNKNOWN		0
#define TAG_INT			1
#define TAG_FLOAT		2
#define TAG_BOOL		3
#define TAG_STRING		4


/* An array parameter.  They are ALWAYS passed byref. */
typedef struct param_array_s
{
	int			tag;
	int			dims[3];
} param_array_t;
typedef struct param_s
{
	int			tag;
	int			byref;
} param_t;
typedef struct nativeparams_s
{
};

#endif
