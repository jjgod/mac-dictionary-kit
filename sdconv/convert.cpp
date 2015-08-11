// convert.cpp: convert modules

#include <arpa/inet.h>

#include "dict.h"
#include "convert.h"
#include "python.h"
#include "lua.h"
#include "index.h"

GString *mdk_start_convert(struct convert_module *mod)
{
    return g_string_new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                                 "<d:dictionary xmlns=\"http://www.w3.org/1999/xhtml\" "
                                 "xmlns:d=\"http://www.apple.com/DTDs/DictionaryService-1.0.rng\">\n\n");
}

void mdk_finish_convert(struct convert_module *mod, GString *dest)
{
    g_string_append(dest, "</d:dictionary>\n");
}

inline bool convert_with_glib(gchar *src, GString *dest)
{
	g_string_append(dest, "<pre>\n");
    g_string_append(dest, src);
	g_string_append(dest, "\n</pre>\n");

    return true;
}

struct convert_module convert_module_list[] = {
    { "default", 0, NULL,        convert_with_glib,   NULL        },
    { "python",  1, init_python, convert_with_python, fini_python },
    // { "lua",     1, init_lua,    convert_with_lua,    fini_lua    },
    { NULL,      0, NULL,        NULL,                NULL        },
};

struct convert_module *mdk_get_convert_module(const char *name)
{
    int i;

    for (i = 0; convert_module_list[i].name != NULL; i++)
        if (strcmp(convert_module_list[i].name, name) == 0)
            return &convert_module_list[i];

    return NULL;
}

void convert_with_module(struct convert_module *mod,
                         gchar *src, GString *dest)
{
    guint32 data_size, sec_size;

    data_size = get_uint32(src);
    src += sizeof(guint32);

    const gchar *p = src;

    while (guint32(p - src) < data_size)
    {
        switch (*p)
        {
			case 'm':
			case 'l':
				p++;
				sec_size = strlen(p);

				if (sec_size)
                {
					gchar *m_str = g_markup_escape_text(p, sec_size);
                    mod->convert(m_str, dest);
					g_free(m_str);
				}

				sec_size++;
				break;

			case 'g':
				p++;
				sec_size = strlen(p);
				if (sec_size)
                {
					g_string_append(dest, "<pre>\n");
					g_string_append(dest, p);
					g_string_append(dest, "\n</pre>");
                }
				sec_size++;
				break;

			case 'x':
			case 'k':
			case 'w':
			case 'h':
				p++;
				sec_size = strlen(p) + 1;

                g_string_append(dest,
                                "<p class=\"error\">Format not supported.</p>");
				break;

			case 't':
            case 'y':
				p++;
				sec_size = strlen(p);
				if (sec_size)
                {
					g_string_append_printf(dest, "<div class=\"%c\">", *p);
					gchar *m_str = g_markup_escape_text(p, sec_size);
					g_string_append(dest, m_str);
					g_free(m_str);
					g_string_append(dest, "</div>\n");
				}
				sec_size++;
				break;

			case 'W':
				p++;
				sec_size = ntohl(get_uint32(p));
				// enable sound button.
				sec_size += sizeof(guint32);
				break;

			case 'P':
				p++;
				sec_size = ntohl(get_uint32(p));
				if (sec_size) {
					// TODO: extract images from here
					g_string_append(dest, "<span foreground=\"red\">[Missing Image]</span>");
				} else {
					g_string_append(dest, "<span foreground=\"red\">[Missing Image]</span>");
				}

                sec_size += sizeof(guint32);
			    break;

			default:
				if (g_ascii_isupper(*p))
                {
					p++;
					sec_size = ntohl(get_uint32(p));
					sec_size += sizeof(guint32);
				} else {
					p++;
					sec_size = strlen(p) + 1;
				}

				g_string_append(dest,
                                "<p class=\"error\">Unknown data type.</p>");
				break;
		}

		p += sec_size;
    }
}

void mdk_convert_index_with_module(struct convert_module *mod,
                                   mdk_dict *dict,
                                   unsigned int index,
                                   GString *dest)
{
    mdk_entry entry;

    dict->get_entry_by_index(index, &entry);
    gchar *m_str = g_markup_escape_text(entry.key, strlen(entry.key));

    g_string_append_printf(dest, "<d:entry id=\"%d\" d:title=\"%s\">\n"
                                 "<d:index d:value=\"%s\"/>\n"
                                 "<h1>%s</h1>\n",
                           index, m_str, m_str, m_str);
    g_free(m_str);

    gchar *src = dict->get_entry_data(&entry);
    convert_with_module(mod, src, dest);
    g_free(src);

    g_string_append(dest, "\n</d:entry>\n\n");
}
