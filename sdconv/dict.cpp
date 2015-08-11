// dict.cpp

#include "dict.h"

#include <stdlib.h>

static void parse_description(const char *p, long len, std::string &description)
{
	description.clear();
	const char *p1 = p;

	while (p1 - p < len)
    {
		if (*p1 == '<')
        {
			p1++;
			if ((*p1 == 'b' || *p1 == 'B') && 
                (*(p1 + 1) == 'r' || *(p1 + 1) == 'R') && 
                *(p1 + 2)=='>')
            {
				description += '\n';
				p1 += 3;
			} else
            {
				description += '<';
			}
		} else
        {
			description += *p1;
			p1++;
		}
	}
}

mdk_dict::mdk_dict()
{
    dictfile = NULL;
    index    = NULL;
    storage  = NULL;
}

mdk_dict::~mdk_dict()
{
    if (dictfile)
        fclose(dictfile);

    if (index)
        delete index;

    delete storage;
}

bool mdk_dict::load(const std::string& ifofilename)
{
    if (! load_ifo(ifofilename.c_str()))
        return false;

    std::string fullfilename(ifofilename);
    fullfilename.replace(fullfilename.length() - sizeof("ifo") + 1, 
                         sizeof("ifo") - 1, "dict.dz");

    if (g_file_test(fullfilename.c_str(), G_FILE_TEST_EXISTS))
    {
        char extract_cmd[256];

        sprintf(extract_cmd, "/usr/bin/gunzip -S .dz %s", fullfilename.c_str());
        system(extract_cmd);
    }

    fullfilename.erase(fullfilename.length() - sizeof(".dz") + 1, 
                       sizeof(".dz") - 1);

    dictfile = fopen(fullfilename.c_str(), "rb");
    if (! dictfile)
    {
        g_print("open file %s failed!\n", fullfilename.c_str());
        return false;
    }

    fullfilename = ifofilename;
    fullfilename.replace(fullfilename.length() - sizeof("ifo")+1, 
                         sizeof("ifo") - 1, "idx.gz");

    if (! g_file_test(fullfilename.c_str(), G_FILE_TEST_EXISTS))
        fullfilename.erase(fullfilename.length() - sizeof(".gz") + 1, 
                           sizeof(".gz") - 1);

    index = new mdk_index();
    if (! index->load(fullfilename.c_str(), wordcount, index_file_size))
        return false;

    bool has_res = false;
    gchar *dirname = g_path_get_dirname(ifofilename.c_str());
    fullfilename = dirname;
    fullfilename += G_DIR_SEPARATOR_S "res";
    if (g_file_test(fullfilename.c_str(), G_FILE_TEST_IS_DIR))
    {
        has_res = true;
    } else {
        fullfilename = dirname;
        fullfilename += G_DIR_SEPARATOR_S "res.rifo";
        if (g_file_test(fullfilename.c_str(), G_FILE_TEST_EXISTS))
        {
            has_res = true;
        }
    }

    if (has_res)
    {
        storage = new ResourceStorage();
        bool failed = storage->load(dirname);
        if (failed) {
            delete storage;
            storage = NULL;
        }
    }
    g_free(dirname);

    return true;
}

bool mdk_dict::load_ifo(const gchar *file)
{
    gchar *buffer;

	if (!g_file_get_contents(file, &buffer, NULL, NULL))
		return false;

#define DICT_MAGIC_DATA "StarDict's dict ifo file\nversion="
	if (!g_str_has_prefix(buffer, DICT_MAGIC_DATA))
    {
		g_free(buffer);
		return false;
	}

	bool is_dict_300 = false;
	gchar *p1;
    p1 = buffer + sizeof(DICT_MAGIC_DATA) -1;
#define DICT_VERSION_242 "2.4.2\n"
#define DICT_VERSION_300 "3.0.0\n"
    if (g_str_has_prefix(p1, DICT_VERSION_242)) {
        p1 += sizeof(DICT_VERSION_242) -2;
    } else if (g_str_has_prefix(p1, DICT_VERSION_300)) {
        p1 += sizeof(DICT_VERSION_300) -2;
        is_dict_300 = true;
    } else {
        g_print("Load %s failed: Unknown version.\n", file);
        g_free(buffer);
        return false;
    }

	gchar *p2, *p3;

	p2 = strstr(p1,"\nwordcount=");
	if (!p2) {
		g_free(buffer);
		return false;
	}

	p3 = strchr(p2 + sizeof("\nwordcount=")-1,'\n');
	gchar *tmpstr = (gchar *)g_memdup(p2 + sizeof("\nwordcount=") - 1, 
                                      p3 - (p2+sizeof("\nwordcount=") - 1) + 1);
	tmpstr[p3 - (p2 + sizeof("\nwordcount=") - 1)] = '\0';
	wordcount = atol(tmpstr);
	g_free(tmpstr);

	p2 = strstr(p1,"\nsynwordcount=");
	if (p2) {
		p3 = strchr(p2 + sizeof("\nsynwordcount=") - 1, '\n');
		gchar *tmpstr = (gchar *)g_memdup(p2 + sizeof("\nsynwordcount=") - 1, 
                                          p3 - (p2 + sizeof("\nsynwordcount=") - 1) + 1);
		tmpstr[p3-(p2+sizeof("\nsynwordcount=")-1)] = '\0';
		synwordcount = atol(tmpstr);
		g_free(tmpstr);
	} else {
		synwordcount = 0;
	}

    p2 = strstr(p1,"\nidxfilesize=");
    if (!p2) {
        g_free(buffer);
        return false;
    }

    p3 = strchr(p2+ sizeof("\nidxfilesize=")-1,'\n');
    tmpstr = (gchar *)g_memdup(p2 + sizeof("\nidxfilesize=")-1, 
                               p3 - (p2 + sizeof("\nidxfilesize=")-1)+1);
    tmpstr[p3-(p2+sizeof("\nidxfilesize=")-1)] = '\0';
    index_file_size = atol(tmpstr);
    g_free(tmpstr);

    p2 = strstr(p1,"\ndicttype=");
    if (p2) {
        p2+=sizeof("\ndicttype=")-1;
        p3 = strchr(p2, '\n');
        dicttype.assign(p2, p3-p2);
    }

	p2 = strstr(p1,"\nbookname=");

	if (!p2) {
		g_free(buffer);
		return false;
	}

	p2 = p2 + sizeof("\nbookname=") -1;
	p3 = strchr(p2, '\n');
	bookname.assign(p2, p3-p2);

	p2 = strstr(p1,"\nauthor=");
	if (p2) {
		p2 = p2 + sizeof("\nauthor=") -1;
		p3 = strchr(p2, '\n');
		author.assign(p2, p3-p2);
	}

	p2 = strstr(p1,"\nemail=");
	if (p2) {
		p2 = p2 + sizeof("\nemail=") -1;
		p3 = strchr(p2, '\n');
		email.assign(p2, p3-p2);
	}

	p2 = strstr(p1,"\nwebsite=");
	if (p2) {
		p2 = p2 + sizeof("\nwebsite=") -1;
		p3 = strchr(p2, '\n');
		website.assign(p2, p3-p2);
	}

	p2 = strstr(p1,"\ndate=");
	if (p2) {
		p2 = p2 + sizeof("\ndate=") -1;
		p3 = strchr(p2, '\n');
		date.assign(p2, p3-p2);
	}

	p2 = strstr(p1,"\ndescription=");
	if (p2)
    {
		p2 = p2 + sizeof("\ndescription=")-1;
		p3 = strchr(p2, '\n');

		parse_description(p2, p3 - p2, description);
	}

	p2 = strstr(p1,"\nsametypesequence=");
	if (p2)
    {
		p2 += sizeof("\nsametypesequence=") - 1;
		p3 = strchr(p2, '\n');
		sametypesequence.assign(p2, p3 - p2);
	}

	g_free(buffer);

    if (wordcount == 0)
        return false;

    return true;
}

gchar *mdk_dict::get_entry_data(mdk_entry *entry)
{
    int i;
    guint32 idxitem_offset = entry->offset;
    guint32 idxitem_size = entry->size;

    if (dictfile)
        fseek(dictfile, idxitem_offset, SEEK_SET);

    gchar *data;
    if (! sametypesequence.empty())
    {
        gchar *origin_data = (gchar *) g_malloc(idxitem_size);

        if (fread(origin_data, idxitem_size, 1, dictfile) != 1)
        {
            g_free(origin_data);
            return NULL;
        }

        guint32 data_size;
        gint sametypesequence_len = sametypesequence.length();
        // there have sametypesequence_len char being omitted.
        // Here is a bug fix of 2.4.8, which don't add sizeof(guint32) anymore.
        data_size = idxitem_size + sametypesequence_len; 

        // if the last item's size is determined by the end up '\0', 
        // then += sizeof(gchar);
        // if the last item's size is determined by the head guint32 type data, 
        // then += sizeof(guint32);
        switch (sametypesequence[sametypesequence_len - 1])
        {
        case 'm':
        case 't':
        case 'y':
        case 'l':
        case 'g':
        case 'x':
        case 'k':
        case 'w':
            data_size += sizeof(gchar);
            break;
        case 'W':
        case 'P':
            data_size += sizeof(guint32);
            break;
        default:
            if (g_ascii_isupper(sametypesequence[sametypesequence_len-1]))
                data_size += sizeof(guint32);
            else
                data_size += sizeof(gchar);
            break;
        }

        data = (gchar *) g_malloc(data_size + sizeof(guint32));
        gchar *p1,*p2;
        p1 = data + sizeof(guint32);
        p2 = origin_data;
        guint32 sec_size;
        // copy the head items.
        for (i = 0; i < sametypesequence_len - 1; i++)
        {
            *p1=sametypesequence[i];
            p1+=sizeof(gchar);
            switch (sametypesequence[i]) {
            case 'm':
            case 't':
            case 'y':
            case 'l':
            case 'g':
            case 'x':
            case 'k':
            case 'w':
                sec_size = strlen(p2)+1;
                memcpy(p1, p2, sec_size);
                p1+=sec_size;
                p2+=sec_size;
                break;
            case 'W':
            case 'P':
                sec_size = get_uint32(p2);
                sec_size += sizeof(guint32);
                memcpy(p1, p2, sec_size);
                p1+=sec_size;
                p2+=sec_size;
                break;
            default:
                if (g_ascii_isupper(sametypesequence[i])) {
                    sec_size = get_uint32(p2);
                    sec_size += sizeof(guint32);
                } else {
                    sec_size = strlen(p2)+1;
                }
                memcpy(p1, p2, sec_size);
                p1+=sec_size;
                p2+=sec_size;
                break;
            }
        }

        // calculate the last item 's size.
        sec_size = idxitem_size - (p2-origin_data);
        *p1=sametypesequence[sametypesequence_len-1];
        p1 += sizeof(gchar);

        switch (sametypesequence[sametypesequence_len - 1])
        {
        case 'm':
        case 't':
        case 'y':
        case 'l':
        case 'g':
        case 'x':
        case 'k':
        case 'w':
            memcpy(p1, p2, sec_size);
            p1 += sec_size;
            *p1='\0';//add the end up '\0';
            break;
        case 'W':
        case 'P':
            memcpy(p1, &sec_size, sizeof(guint32));
            p1 += sizeof(guint32);
            memcpy(p1, p2, sec_size);
            break;

        default:
            if (g_ascii_isupper(sametypesequence[sametypesequence_len-1]))
            {
                memcpy(p1, &sec_size, sizeof(guint32));
                p1 += sizeof(guint32);
                memcpy(p1, p2, sec_size);
            } else {
                memcpy(p1, p2, sec_size);
                p1 += sec_size;
                *p1='\0';
            }
            break;
        }

        g_free(origin_data);
        memcpy(data, &data_size, sizeof(guint32));
    } else
    {
        data = (gchar *) g_malloc(idxitem_size + sizeof(guint32));
        
        if (fread(data + sizeof(guint32), idxitem_size, 1, dictfile) != 1)
        {
            g_free(data);
            return NULL;
        }

        memcpy(data, &idxitem_size, sizeof(guint32));
    }

    return data;
}

