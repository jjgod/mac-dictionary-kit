// python.h

#include <glib.h>

bool init_python(const char *file);
void fini_python();
bool convert_with_python(gchar *src, GString *dest);

