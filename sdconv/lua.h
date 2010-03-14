// lua.h

#ifndef SDCONV_LUA_H
#define SDCONV_LUA_H

#include <glib.h>

bool init_lua(const char *file);
void fini_lua();
bool convert_with_lua(gchar *src, GString *dest);

#endif

