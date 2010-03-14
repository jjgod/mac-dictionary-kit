// python.h

#ifndef SDCONV_PYTHON_H
#define SDCONV_PYTHON_H

#include <glib.h>

bool init_python(const char *file);
void fini_python();
bool convert_with_python(gchar *src, GString *dest);

#endif

