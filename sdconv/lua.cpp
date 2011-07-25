// lua.cpp

#if 0
#include "lua.h"
#include <lua.hpp>

lua_State *L;

bool init_lua(const char *file)
{
    int ret;

    L = luaL_newstate();

    luaL_openlibs(L);
    ret = luaL_loadfile(L, file);
    if (ret)
    {
        fprintf(stderr, "Couldn't load file: %s\n", lua_tostring(L, -1));
        return false;
    }

    return true;
}

void fini_lua()
{
    lua_close(L);
}

bool convert_with_lua(gchar *src, GString *dest)
{
    lua_pushstring(L, src);
    lua_setglobal(L, "input");

    lua_pcall(L, 0, 1, 0);
    g_string_append(dest, lua_tostring(L, -1));
    lua_pop(L, 1);

    return true;
}

#endif