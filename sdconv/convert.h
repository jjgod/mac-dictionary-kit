// convert.h

#ifndef MDK_CONVERT_H
#define MDK_CONVERT_H

#include <stdio.h>
#include <glib.h>

struct convert_module {
    const char *name;
    int req_file;                               /* need to specify another file */
    bool (*init)(const char *file);
    bool (*convert)(gchar *src, GString *dest);
    void (*fini)();
};

GString *mdk_start_convert(struct convert_module *mod);
void mdk_finish_convert(struct convert_module *mod, GString *dest);
struct convert_module *mdk_get_convert_module(const char *name);
void mdk_convert_index_with_module(struct convert_module *mod, 
                                   mdk_dict *dict,
                                   unsigned int index, 
                                   GString *dest);
#endif

