#if !defined(TYPES_H)
#define TYPES_H

#include <sys/types.h>
#if defined __GNUC__
#include <stdint.h>
#else
typedef unsigned int			uint32_t;
typedef unsigned long long		uint64_t;
typedef unsigned short int		uint16_t;
typedef unsigned char			uint8_t;

typedef int						int32_t;
typedef long long				int64_t;
typedef short					int16_t;
typedef char					int8_t;

#define snprintf _snprintf
#define strncat _strncat
#define strncpy _strncpy
#define strcpy _strcpy
#endif


typedef uint32_t		dword;
typedef uint64_t		qword;
typedef uint16_t		word;
typedef uint8_t			byte;

typedef int32_t			cell;
typedef uint32_t		ucell;


#endif
