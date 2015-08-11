// sdconv.cpp

#include <stdio.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <ctype.h>
#include <locale.h>

#include "mdk.h"

void show_usage()
{
    fprintf(stderr, "usage: sdconv [options] [script] <dict.ifo> [output.xml]\n\n"
                    "Available options:\n"
                    "   -m <module>: select convert module, available: python, lua\n"
                    "   -d [num/r] : debug mode [num for start number, r for random]\n"
                    "   -h         : show this help page\n\n"
                    "For additional information, see http://mac-dictionary-kit.googlecode.com/\n");
    exit(1);
}

enum debug_mode { DEBUG_MODE_OFF, DEBUG_MODE_NUM, DEBUG_MODE_RANDOM };

int main(int argc, char *argv[])
{
    int i = 1, debug_mode = DEBUG_MODE_OFF;
    FILE *fp;
    const char *outfile, *module_name = "default", *module_file = NULL;
    int start = 0;

    if (argc < 3)
        show_usage();

    // process options in arguments
    while (i < argc)
    {
        if (strcmp(argv[i], "-d") == 0)
        {
            debug_mode = DEBUG_MODE_NUM;
            i++;

            if (i < argc)
            {
                // specify an start id
                if (isdigit(argv[i][0]))
                {
                    start = strtol(argv[i++], NULL, 10);

                    if (start <= 0)
                    {
                        fprintf(stderr, "-d option comes with "
                                        "positive start number.\n");
                        return 1;
                    }
                }

                // random mode
                else if (strlen(argv[i]) == 1 && argv[i][0] == 'r')
                {
                    debug_mode = DEBUG_MODE_RANDOM;
                    i++;
                }

                // otherwise leave it alone, use default start id (0)
            }
        }

        else
        if (strcmp(argv[i], "-m") == 0)
        {
            i++;

            if (i >= argc)
            {
                fprintf(stderr, "-m option must come with a module name.\n");
                return 1;
            }

            module_name = argv[i++];
        }

        else
        if (strcmp(argv[i], "-h") == 0)
            show_usage();

        else
            break;
    }

    struct convert_module *mod = mdk_get_convert_module(module_name);
    if (! mod)
    {
        fprintf(stderr, "module '%s' not found.\n", module_name);
        return 1;
    }

    if (mod->req_file)
    {
        struct stat st;

        if (argc - i < 1)
            show_usage();

        module_file = argv[i++];
        if (stat(module_file, &st) != 0)
        {
            fprintf(stderr, "specified module script '%s' not found.\n",
                    module_file);
            return 1;
        }
    }

    if (mod->init)
    {
        bool ret = mod->init(module_file);
        if (ret != true)
        {
            fprintf(stderr, "%s: initialize module %s failed.\n",
                    argv[0], module_file);
            return 1;
        }
    }

    // we must leave at least one argument for input file name
    if (argc - i < 1)
        show_usage();

    const char *path = argv[i++];
    const std::string url(path);
    int end, count;
    mdk_dict *dict = new mdk_dict;

    setlocale(LC_ALL, "");

    if (dict->load(url) != true)
    {
        fprintf(stderr, "%s: load dictionary file '%s' failed.\n", argv[0], path);
        return 1;
    }

    count = dict->get_entry_count();

    if (debug_mode)
    {
        if (debug_mode == DEBUG_MODE_RANDOM)
        {
            srandom(time(0));

            double r = random();
            start = count * r / RAND_MAX;
        }

        else if (start >= count)
        {
            fprintf(stderr, "%s: start entry id %d is larger than "
                            "the total entry number (%d).\n",
                    argv[0], start, count);
            return 1;
        }
        count = 1;
    }

    printf("%s %d %d\n",
           dict->dict_name().c_str(),
           dict->get_entry_count(), start);

    end = start + count;

    // if we have yet another argument, that's the output file
    // otherwise we'll output to stdout
    if (i < argc)
    {
        outfile = argv[i];
        fp = fopen(outfile, "w");
        if (! fp)
        {
            fprintf(stderr, "%s: write to output file '%s' failed.\n", argv[0], outfile);
            return 1;
        }
    } else
        fp = stdout;

    GString *dest = mdk_start_convert(mod);

    for (i = start; i < end; i++)
        mdk_convert_index_with_module(mod, dict, i, dest);

    mdk_finish_convert(mod, dest);
    fprintf(fp, "%s", dest->str);
    g_string_free(dest, TRUE);
    if (fp != stdout)
        fclose(fp);

    if (mod->fini)
        mod->fini();

    return 0;
}

