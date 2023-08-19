.PHONY: check restart start stop reload status

all: check

LUA_CLIB_PATH ?= luaclib
LUA_INC ?= wlua/skynet/3rd/lua
CFLAGS = -g -O0 -Wall -I$(LUA_INC)
SHARED := -fPIC --shared
LUA_CLIB = skiplist

prebuild:
	git submodule update --init --recursive

build: prebuild \
  $(LUA_CLIB_PATH) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)
	cd wlua && $(MAKE)

clean:
	rm -f luaclib/*

$(LUA_CLIB_PATH)/skiplist.so : 3rd/lua-zset/skiplist.h 3rd/lua-zset/skiplist.c 3rd/lua-zset/lua-skiplist.c | $(LUA_CLIB_PATH)
	$(CC)  $(CFLAGS)  -I$(LUA_INC) $(SHARED)  $^ -o $@

check:
	luacheck `find app -name '*.lua' | xargs` --ignore 212/self

restart:
	wlua stop
	sleep 3
	wlua start

status:
	@wlua status

start:
	wlua start

stop:
	wlua stop

reload:
	wlua reload
