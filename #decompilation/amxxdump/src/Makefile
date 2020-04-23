OPT_FLAGS = -O3 -funroll-loops -s -pipe -fomit-frame-pointer -fno-strict-aliasing -DNDEBUG

OPT_FLAGS_MINGW = -DNDEBUG -O3 -funroll-loops -s -pipe -fomit-frame-pointer -fno-strict-aliasing

DEBUG_FLAGS = -g -ggdb3
CC = gcc-4.1
# CC = gcc

OBJECTS = util.c main.c parser.c list.c opcodes.c commonutil.c dbgutil.c \
commonheaders.c headerreader.c stack.c \
zlib/adler32.c zlib/crc32.c zlib/gzio.c zlib/inffast.c zlib/inftrees.c zlib/uncompr.c \
zlib/compress.c zlib/deflate.c zlib/infback.c zlib/inflate.c zlib/trees.c zlib/zutil.c


INCLUDE = -I. 
LINK_FLAGS =

ifeq "$(MINGW)" "true"
	CC = mingw32-gcc
	INCLUDE += -IC:\MinGW\include
	ifeq "$(DEBUG)" "true"
		BIN_DIR = ../WinDebug
		CFLAGS = $(DEBUG_FLAGS)
	else
		BIN_DIR = ../WinRelease
		CFLAGS = $(OPT_FLAGS_MINGW)
	endif
else
	ifeq "$(DEBUG)" "true"
		BIN_DIR = ../Debug
		CFLAGS = $(DEBUG_FLAGS) -fPIC 
	else
		BIN_DIR = ../Release
		CFLAGS = $(OPT_FLAGS) -fPIC
	endif
endif

CFLAGS += -Wall -Werror

OPT_FLAGS += -march=i686

OBJ_FILES := $(OBJECTS:%.c=$(BIN_DIR)/%.o)

$(BIN_DIR)/%.o: %.c
	$(CC) $(INCLUDE) $(CFLAGS) -o $@ -c $<

all:
	mkdir -p $(BIN_DIR)/zlib
	$(MAKE) amxxdump

amxxdump: $(OBJ_FILES)
	$(CC) $(INCLUDE) $(CFLAGS) $(OBJ_FILES) $(LINK) -o $(BIN_DIR)/amxxdump

debug:	
	$(MAKE) all DEBUG=true

default:
	$(MAKE)all DEBUG=false SANE=true

optimized:
	$(MAKE) all DEBUG=false SANE=false

clean:
	rm -rf ../Release/
	rm -rf ../Debug/
	rm -rf ../WinDebug/
	rm -rf ../WinRelease/

