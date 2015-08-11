// index.cpp

#include "index.h"
#include <zlib.h>
#include <sys/stat.h>

mdk_index::mdk_index()
{
	entry_buffer = NULL;
}

mdk_index::~mdk_index()
{
	g_free(entry_buffer);
}

guint32 mdk_index::entry_count()
{
    return entry_list.size();
}

bool mdk_index::load(const gchar *file, guint32 entry_count, guint32 fsize)
{
    size_t len;

    if (g_str_has_suffix(file, ".gz"))
    {
	    gzFile in = gzopen(file, "rb");
	    
        if (in == NULL)
		    return false;
	    
        entry_buffer = (gchar *) g_malloc(fsize);
        len = gzread(in, entry_buffer, fsize);
	    gzclose(in);
    } else
    {
        FILE *in = fopen(file, "rb");

        if (! in)
            return false;
        
        entry_buffer = (gchar *) g_malloc(fsize);
        len = fread(entry_buffer, 1, fsize, in);

        fclose(in);
    }

	if (len == 0 || len != fsize)
		return false;

	entry_list.resize(entry_count);
	gchar *p1 = entry_buffer;
	guint32 i;

	for (i = 0; i < entry_count; i++)
    {
		entry_list[i] = p1;
		p1 += strlen(p1) + 1 + 2 * sizeof(guint32);
	}

	return true;
}

bool mdk_index::get_entry(guint32 index, mdk_entry *entry)
{
    if (index >= entry_count())
        return false;

    gchar *p1 = entry_list[index];
    entry->key = p1;

    p1 += strlen(entry->key) + sizeof(gchar);
	entry->offset = ntohl(get_uint32(p1));

	p1 += sizeof(guint32);
	entry->size = ntohl(get_uint32(p1));

#if 0
    fprintf(stderr, "index = %u, offset = %u, size = %u\n", 
            index, entry->offset, entry->size);
#endif

    return true;
}
