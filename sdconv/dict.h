// dict.h

#ifndef MDK_DICT_H
#define MDK_DICT_H

#include <glib.h>
#include <string>
#include <memory>

#include "index.h"
#include "storage.h"

class mdk_dict {
private:
    guint32     wordcount;
    guint32     synwordcount;
    guint32     index_file_size;
    std::string bookname;
    std::string author;
    std::string email;
    std::string website;
    std::string date;
    std::string description;
    std::string sametypesequence;
    std::string dicttype;

	mdk_index   *index;
	ResourceStorage *storage;

	bool load_ifo(const gchar *file);
	FILE *dictfile;

public:
	mdk_dict();
	~mdk_dict();
	bool load(const std::string&);

	const std::string& dict_name() { return bookname; }
	const std::string& dict_type() { return dicttype; }

	guint32 get_entry_count()
    {
        return index->entry_count();
    }
    
    gchar *get_entry_data(mdk_entry *entry);

	gchar *get_entry_data_by_index(guint32 index)
	{
        mdk_entry entry;

		if (get_entry_by_index(index, &entry))
            return get_entry_data(&entry);

        return NULL;
	}

	bool get_entry_by_index(guint32 idx, mdk_entry *entry)
	{
		return index->get_entry(idx, entry);
	}
};

#endif

