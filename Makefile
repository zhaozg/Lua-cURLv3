include .config

T=lcurl

UNAME            ?= $(shell uname)
DESTDIR          ?= /
PKG_CONFIG       ?= pkg-config
INSTALL          ?= install
RM               ?= rm
LUA_IMPL         ?= luajit
CC               ?= $(MAC_ENV) gcc

ifneq (,$(TARGET_SYS))
UNAME := $(TARGET_SYS)
endif

LIB_OPTION      ?= -shared
CC              := $(CROSS)$(CC)
AR              := $(CROSS)$(AR)
LD              := $(CROSS)$(LD)

LUA_VERSION       = $(shell $(PKG_CONFIG) --print-provides --silence-errors $(LUA_IMPL))
ifeq ($(LUA_VERSION),)
LUA_CMOD         ?= /usr/lib/lua/5.1
LUA_LMOD         ?= /usr/share/lua/5.1
LIBDIR           ?= /usr/lib
LUA_INC          ?= /usr/include
CURL_LIBS         = -L/usr/lib -lcurl
else
LUA_CMOD         ?= $(shell $(PKG_CONFIG) --variable INSTALL_CMOD $(LUA_IMPL))
LUA_LMOD         ?= $(shell $(PKG_CONFIG) --variable INSTALL_LMOD $(LUA_IMPL))
LIBDIR           ?= $(shell $(PKG_CONFIG) --variable libdir $(LUA_IMPL))
LUA_INC          ?= $(shell $(PKG_CONFIG) --variable includedir $(LUA_IMPL))
LUA_LIBS          = $(shell $(PKG_CONFIG) --libs $(LUA_IMPL))
CURL_CFLAGS       = $(shell $(PKG_CONFIG) --cflags libcurl)
CURL_LIBS         = $(shell $(PKG_CONFIG) --libs libcurl)
endif

LIBS              = $(CURL_LIBS)
ifeq ($(UNAME), Linux)
OS_FLAGS         ?= -shared
LIBS              = -lrt -ldl $(CURL_LIBS)
endif
ifeq ($(UNAME), Darwin)
MAC_ENV          ?= env MACOSX_DEPLOYMENT_TARGET='10.3'
LIBS              = -undefined dynamic_lookup -ldl $(CURL_LIBS)
endif
ifeq ($(UNAME), iOS)
OS_FLAGS         ?= $(TARGET_FLAGS)
MAC_ENV          ?= env MACOSX_DEPLOYMENT_TARGET='10.3'
LIBS              = -undefined dynamic_lookup -ldl $(CURL_LIBS) $(TARGET_FLAGS)
endif
ifeq ($(findstring MINGW, $(UNAME)), MINGW)
CURL_LIBS         = $(shell $(PKG_CONFIG) --static --libs libcurl)
LIBS              = $(LUA_LIBS) $(CURL_LIBS)
endif

ifneq ($(DEBUG),)
DBG               = -ggdb
endif

ifeq ($(DEV),)
WARN              = -Wall -Wno-unused-value
else
WARN              = -Wall -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic
endif

INCLUDES          = -I$(LUA_INC) $(CURL_CFLAGS)
DEFINES           =

COMMONFLAGS       = -O2 -g -pipe -fPIC $(OS_FLAGS) $(DBG)
LF                = $(LIBS) $(LDFLAGS)
CF                = $(INCLUDES) $(DEFINES) $(COMMONFLAGS) $(WARN) -DPTHREADS $(CFLAGS)

SCR               = src/lua/*.lua src/lua/cURL/*.lua src/lua/cURL/impl/*.lua
SRCS              = src/*.c
OBJS              = $(subst src/,,$(subst .c,.o,$(SRCS)))

BIN               = $(T).so
STATIC_LIB        = $(T).a

all: $(BIN) lib$T.a

$(BIN): $(OBJS)
	$(CC) -shared $(CF) -o $@ $^ $(LF)
.c.o:
	$(CC) $(CF) -c -o $@ $?

lib$T.a: $(OBJS)
	$(AR) rcs $@ $^

$(OBJS): $(SRCS)
	$(CC) $(CF) -c $^

$(STATIC_LIB): $(OBJS)
	ar rcs $@ $^

install: all
	$(INSTALL) -d $(DESTDIR)$(LUA_CMOD) $(DESTDIR)$(LUA_LMOD)/cURL/impl
	$(INSTALL) $(BIN) $(DESTDIR)$(LUA_CMOD)
	$(INSTALL) src/lua/cURL.lua $(DESTDIR)$(LUA_LMOD)
	$(INSTALL) src/lua/cURL/safe.lua $(DESTDIR)$(LUA_LMOD)/cURL
	$(INSTALL) src/lua/cURL/utils.lua $(DESTDIR)$(LUA_LMOD)/cURL
	$(INSTALL) src/lua/cURL/impl/cURL.lua $(DESTDIR)$(LUA_LMOD)/cURL/impl

clean:
	$(RM) -f $(BIN) $(OBJS) $(STATIC_LIB)
