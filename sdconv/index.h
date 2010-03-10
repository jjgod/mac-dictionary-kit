// index.h: dictionary index

#ifndef MDK_INDEX_H
#define MDK_INDEX_H

#include <vector>
#include <string>
#include <glib.h>

#ifdef ARM
static inline guint32 get_uint32(const gchar *addr)
{
	guint32 result;
	memcpy(&result, addr, sizeof(guint32));
	return result;
}
#else
#define get_uint32(x) *reinterpret_cast<const guint32 *>(x)
#endif

typedef struct mdk_entry {
    const gchar *key;
    guint32 offset;
    guint32 size;
} mdk_entry;

class mdk_index {
public:
    mdk_index();
	~mdk_index();

	bool load(const gchar *file, 
              guint32 entry_count, 
              guint32 fsize);
    bool get_entry(guint32 index, mdk_entry *entry);

    guint32 entry_count();

private:
	gchar               *entry_buffer;
	std::vector<gchar *> entry_list;
};

#endif

